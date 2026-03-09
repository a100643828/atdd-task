# AWS Operations Skill - 使用範例

完整的使用範例，涵蓋各種實際場景。

## 範例 1: 每日運維檢查

### 用戶請求
```
早安！請幫我檢查所有生產環境伺服器的健康狀態
```

### Claude 執行步驟

1. 列出生產環境實例
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress,InstanceType,State.Name]' \
  --output table
```

2. 對每個實例執行健康檢查（透過 SSM，不需 SSH key）
```bash
for IP in 54.123.45.67 54.123.45.68; do
  echo "=== 檢查 $IP ==="
  ssh -i ~/.ssh/${PROJECT}_production.pem ubuntu@$IP 'bash -s' << 'EOF'
#!/bin/bash
echo "🖥️  System Info"
echo "  Uptime: $(uptime -p)"
echo "  Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

echo "💾 Disk Usage"
df -h | grep -E '^/dev/' | awk '{print "  "$1" "$5" used"}'
echo ""

echo "🧠 Memory"
free -h | grep Mem | awk '{print "  "$3"/"$2" used"}'
echo ""

echo "✅ Services"
for service in puma postgresql nginx; do
  status=$(sudo systemctl is-active $service)
  echo "  $service: $status"
done
EOF
done
```

### 預期輸出
```
=== 檢查 54.123.45.67 ===
🖥️  System Info
  Uptime: up 15 days, 3 hours
  Load: 0.45, 0.52, 0.48

💾 Disk Usage
  /dev/xvda1 45% used

🧠 Memory
  2.1G/8.0G used

✅ Services
  puma: active
  postgresql: active
  nginx: active

=== 檢查 54.123.45.68 ===
...
```

---

## 範例 2: 緊急資料庫備份

### 用戶請求
```
客戶要求緊急變更，請先備份 production 資料庫
```

### Claude 執行步驟

1. 確認環境
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=${PROJECT}" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].[InstanceId,PublicIpAddress]' \
  --output text
```

2. 執行備份
```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INSTANCE_IP="54.123.45.67"
BACKUP_FILE="${PROJECT}_production_${TIMESTAMP}.sql"

echo "📦 開始備份..."
ssh -i ~/.ssh/${PROJECT}_production.pem ubuntu@${INSTANCE_IP} \
  "pg_dump -U postgres -d ${PROJECT}_production -F c -b -v" \
  > "${BACKUP_FILE}"

echo "🗜️  壓縮備份..."
gzip "${BACKUP_FILE}"

SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
echo "✅ 備份完成: ${BACKUP_FILE}.gz (${SIZE})"
```

### 預期輸出
```
📦 開始備份...
pg_dump: last built-in OID is 16383
pg_dump: reading extensions
pg_dump: identifying extension members
...
🗜️  壓縮備份...
✅ 備份完成: ${PROJECT}_production_20251127_143022.sql.gz (245M)
```

---

## 範例 3: 程式碼部署

### 用戶請求
```
將 master 分支的最新代碼部署到 staging 環境
```

### Claude 執行步驟

1. 列出 staging 實例
```bash
STAGING_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=staging" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "📍 Staging Server: $STAGING_IP"
```

2. 執行部署腳本
```bash
ssh -i ~/.ssh/${PROJECT}_staging.pem ubuntu@${STAGING_IP} 'bash -s' << 'EOF'
#!/bin/bash
set -e

cd ${APP_DIR}

echo "🔄 拉取最新代碼..."
git fetch origin
git checkout master
git pull origin master

echo "📦 安裝依賴..."
bundle install --deployment

echo "🗄️  執行資料庫遷移..."
RAILS_ENV=staging bundle exec rails db:migrate

echo "🔨 編譯資源..."
RAILS_ENV=staging bundle exec rails assets:precompile

echo "🔄 重啟服務..."
sudo systemctl restart puma

echo "✅ 部署完成"
EOF
```

3. 驗證部署
```bash
ssh -i ~/.ssh/${PROJECT}_staging.pem ubuntu@${STAGING_IP} \
  "cd ${APP_DIR} && git log -1 --oneline && sudo systemctl status puma | grep Active"
```

### 預期輸出
```
📍 Staging Server: 54.123.45.99
🔄 拉取最新代碼...
Already on 'master'
From github.com:sunnyfounder/${PROJECT}
 * branch            master     -> FETCH_HEAD
Already up to date.

📦 安裝依賴...
Using bundler 2.3.26
...
Bundle complete!

🗄️  執行資料庫遷移...
== 20251127135500 AddIndexToProjects: migrating ===========================
-- add_index(:projects, :status)
== 20251127135500 AddIndexToProjects: migrated (0.0234s) ==================

🔨 編譯資源...
...

🔄 重啟服務...
✅ 部署完成

ceae0dc1 feat: 修正e2e整合測試
   Active: active (running) since Wed 2025-11-27 14:32:15 UTC; 2s ago
```

---

## 範例 4: 多實例批次操作

### 用戶請求
```
在所有 production web servers 上更新 nginx 配置並重啟
```

### Claude 執行步驟

1. 取得所有 web server IPs
```bash
WEB_SERVERS=$(aws ec2 describe-instances \
  --filters "Name=tag:Role,Values=web" \
            "Name=tag:Environment,Values=production" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress]' \
  --output text)

echo "$WEB_SERVERS"
```

2. 批次更新配置
```bash
cat << 'EOF' > /tmp/update_nginx.sh
#!/bin/bash
# 備份現有配置
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)

# 測試新配置
sudo nginx -t

# 如果測試通過，重新載入
if [ $? -eq 0 ]; then
  sudo systemctl reload nginx
  echo "✅ Nginx 已重新載入"
else
  echo "❌ Nginx 配置測試失敗"
  exit 1
fi
EOF

while IFS=$'\t' read -r NAME IP; do
  echo "=== 更新 $NAME ($IP) ==="

  # 上傳新配置
  scp -i ~/.ssh/${PROJECT}_production.pem \
    nginx.conf ubuntu@$IP:/tmp/nginx.conf

  # 移動配置並重啟
  ssh -i ~/.ssh/${PROJECT}_production.pem ubuntu@$IP \
    "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf && bash -s" < /tmp/update_nginx.sh

  echo ""
done <<< "$WEB_SERVERS"
```

### 預期輸出
```
=== 更新 sf-project-web-01 (54.123.45.70) ===
nginx.conf                100%  2048    2.0MB/s   00:00
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
✅ Nginx 已重新載入

=== 更新 sf-project-web-02 (54.123.45.71) ===
nginx.conf                100%  2048    2.0MB/s   00:00
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
✅ Nginx 已重新載入
```

---

## 範例 5: 使用 SSM 執行命令

### 用戶請求
```
使用 SSM 在私有子網的資料庫伺服器上檢查 PostgreSQL 狀態
```

### Claude 執行步驟

1. 取得實例 ID
```bash
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sf-project-db-production" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

echo "📍 Instance: $INSTANCE_ID"
```

2. 發送命令
```bash
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "sudo systemctl status postgresql",
    "sudo -u postgres psql -c \"SELECT version();\"",
    "sudo -u postgres psql -c \"SELECT count(*) FROM pg_stat_activity;\""
  ]' \
  --output text \
  --query "Command.CommandId")

echo "⏳ 命令 ID: $COMMAND_ID"
echo "等待執行結果..."
sleep 3
```

3. 取得結果
```bash
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

### 預期輸出
```
📍 Instance: i-0abcd1234efgh5678
⏳ 命令 ID: 12345678-abcd-1234-efgh-123456789abc
等待執行結果...

● postgresql.service - PostgreSQL RDBMS
   Loaded: loaded (/lib/systemd/system/postgresql.service; enabled)
   Active: active (running) since Mon 2025-11-20 10:15:22 UTC; 1 week 0 days ago

PostgreSQL 14.10 on x86_64-pc-linux-gnu, compiled by gcc 11.4.0, 64-bit

 count
-------
    15
```

---

## 範例 6: 安全性審計

### 用戶請求
```
檢查所有 production 實例的安全性配置
```

### Claude 執行步驟

```bash
# 檢查安全群組規則
aws ec2 describe-security-groups \
  --filters "Name=tag:Environment,Values=production" \
  --query 'SecurityGroups[*].[GroupName,IpPermissions[?FromPort==`22`].[IpRanges[*].CidrIp]]' \
  --output table

# 檢查 SSH key 使用情況
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],KeyName]' \
  --output table

# 在每個實例上檢查 SSH 配置
PROD_IPS=$(aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].PublicIpAddress' \
  --output text)

for IP in $PROD_IPS; do
  echo "=== 檢查 $IP ==="
  ssh -i ~/.ssh/${PROJECT}_production.pem ubuntu@$IP \
    "grep -E 'PermitRootLogin|PasswordAuthentication|PubkeyAuthentication' /etc/ssh/sshd_config"
  echo ""
done
```

---

## 小技巧

### 1. 使用環境變數簡化命令

```bash
# 在 ~/.zshrc 或 ~/.bashrc 中設定（依專案調整）
export PROD_KEY="~/.ssh/<PROJECT>_production.pem"
export PROD_USER="ubuntu"

# 使用
ssh -i $PROD_KEY $PROD_USER@<IP> "command"
```

### 2. 建立 SSH 配置

```bash
# ~/.ssh/config（依專案建立對應 Host）
Host core-web-prod-*
  User ubuntu
  IdentityFile ~/.ssh/core_web_production.pem
  StrictHostKeyChecking no

Host sf-prod-*
  User ubuntu
  IdentityFile ~/.ssh/sf_project_production.pem
  StrictHostKeyChecking no

# 使用
ssh core-web-prod-web1 "command"
```

### 3. 使用 AWS CLI profiles

```bash
# ~/.aws/config
[profile production]
region = ap-northeast-1
output = json

# 使用
aws ec2 describe-instances --profile production
```

這些範例涵蓋了日常運維的大部分場景，可以直接複製使用或作為模板修改。
