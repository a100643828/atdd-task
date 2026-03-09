---
name: aws-operations
description: AWS EC2 operations including checking service status, viewing logs, server health monitoring, and production/staging environment management. Use when user asks to check/view/查看 production/staging servers, service status/狀態/狀況, logs/日誌, or perform remote operations like deployment and database backup.
version: 2.0.0
---

# AWS Operations

管理 AWS EC2 實例的常見操作，使用 AWS Systems Manager (SSM) 執行遠端命令。

## Prerequisites

確保已安裝並配置：
- AWS CLI (`aws --version`)
- 已配置 AWS credentials (`~/.aws/credentials`)
- EC2 實例已安裝 SSM Agent 並有適當的 IAM role

## Instructions

### 1. 檢查 AWS 認證狀態

驗證當前 AWS 認證是否有效：

```bash
# 檢查當前認證身份
aws sts get-caller-identity

# 預期輸出：
# {
#   "UserId": "AIDXXXXXXXXXXXXXXXXXX",
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/username"
# }
```

**錯誤處理**：
- 如果返回錯誤，檢查 `~/.aws/credentials` 配置
- 確認 AWS_PROFILE 環境變數設定正確

### 2. 列出所有可用的 EC2 實例

查詢當前區域的所有 EC2 實例：

```bash
# 列出所有實例（含詳細資訊）
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# 只列出運行中的實例
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**參數說明**：
- 可加入 `--region` 指定區域（如 `--region ap-northeast-1`）
- 使用 `--filters` 可進一步篩選（如按標籤、VPC、子網路等）

### 3. 使用 SSM 執行遠端命令（主要方式）

透過 AWS Systems Manager 在 EC2 實例上執行命令：

```bash
# 在實例上執行命令
aws ssm send-command \
  --instance-ids "<INSTANCE_ID>" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["<COMMAND>"]' \
  --output json \
  --query "Command.CommandId"

# 獲取命令執行結果（需等待幾秒讓命令完成）
sleep 3 && aws ssm get-command-invocation \
  --command-id "<COMMAND_ID>" \
  --instance-id "<INSTANCE_ID>" \
  --query "StandardOutputContent" \
  --output text
```

**專案實例對照表（Production）**：

> 📋 實例資訊請讀取 `.claude/config/aws-instances.yml`
> 根據用戶指定的專案，從設定檔查詢 instance_id 和 app_dir

| 專案 | Name Tag | Instance ID | 遠端 App 路徑 |
|------|----------|-------------|---------------|
| core_web | web_1 | `<INSTANCE_ID>` | `${APP_DIR}` |
| core_web | Shadow | `<INSTANCE_ID>` | `${APP_DIR}` |
| sf_project | sf_project | `<INSTANCE_ID>` | `${APP_DIR}` |
| jv_project | jv_project | `<INSTANCE_ID>` | `${APP_DIR}` |
| e-trading | e-trading-production | `<INSTANCE_ID>` | `${APP_DIR}` |

**多台 Instance 選擇規則**：
- 當專案有多台 Instance 時（如 core_web），必須使用 `AskUserQuestion` 工具詢問用戶要連線哪一台
- 範例提問：「core_web 有兩台 Production（web_1、Shadow），請問要連線哪一台？」

**根據專案決定變數**：
```
# 根據用戶指定的專案，設定以下變數：
INSTANCE_ID="<從對照表查詢>"
APP_DIR="<從對照表查詢>"      # 例如 /home/apps/sunny_founder
APP_CURRENT="${APP_DIR}/current"
APP_LOG="${APP_DIR}/shared/log"
APP_CONFIG="${APP_CURRENT}/config"
```

**執行多行命令**：

```bash
# 多個命令用分號或 && 串接
aws ssm send-command \
  --instance-ids "<INSTANCE_ID>" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cd ${APP_DIR} && git status"]' \
  --output json \
  --query "Command.CommandId"
```

**使用 SSM 的優勢**：
- 不需要開放 SSH 端口（22）
- 可透過 IAM 控制權限
- 自動記錄命令歷史
- 更安全的連接方式

### 4. 查看服務狀態與日誌（最常用）

針對"幫我到 Production 查看某某服務的狀況與 log"這類需求：

```bash
# 查看服務狀態
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "<INSTANCE_ID>" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sudo systemctl status <SERVICE> --no-pager"]' \
  --output text \
  --query "Command.CommandId")

sleep 3 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "<INSTANCE_ID>" \
  --query "StandardOutputContent" \
  --output text
```

**常見服務檢查指令**：

```bash
# 檢查 Puma (Rails 應用伺服器)
'commands=["sudo systemctl status puma --no-pager && tail -30 ${APP_DIR}/log/production.log"]'

# 檢查 Sidekiq (背景任務)
'commands=["sudo systemctl status sidekiq --no-pager && sudo journalctl -u sidekiq -n 50 --no-pager"]'

# 檢查 PostgreSQL
'commands=["sudo systemctl status postgresql --no-pager"]'

# 檢查 Nginx
'commands=["sudo systemctl status nginx --no-pager && sudo tail -50 /var/log/nginx/error.log"]'

# 檢查磁碟空間
'commands=["df -h"]'

# 查看目錄內容
'commands=["ls -la /home/apps/"]'
```

**Rails 日誌查看**：

```bash
# 注意：使用 Capistrano 部署，log 在 shared 目錄
# 查看 Rails production log (最後 100 行)
'commands=["tail -100 ${APP_LOG}/production.log"]'

# 查看錯誤日誌
'commands=["grep -a -i error ${APP_LOG}/production.log | tail -50"]'

# 搜尋特定專案的相關日誌
'commands=["grep -a \"RT130044\" ${APP_LOG}/production.log | tail -30"]'
```

**重要路徑說明**（根據專案對照表決定 APP_DIR）：
- 應用程式目錄：`${APP_DIR}/current`（symlink 到最新 release）
- Log 目錄：`${APP_DIR}/shared/log/`
- 設定目錄：`${APP_DIR}/current/config/`

**多服務同時檢查**：

```bash
'commands=["for service in puma sidekiq postgresql nginx; do echo \"=== $service ===\"; sudo systemctl is-active $service && echo OK || echo FAILED; done"]'
```

### 5. 完整的服務檢查腳本

```bash
# 完整健康檢查（INSTANCE_ID 和 APP_DIR 根據專案對照表決定）
INSTANCE_ID="<從對照表查詢>"
SERVICE="puma"

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[
    \"echo '=== 服務狀態 ===' && sudo systemctl status $SERVICE --no-pager | head -20\",
    \"echo '' && echo '=== 最近日誌 ===' && sudo journalctl -u $SERVICE -n 30 --no-pager\",
    \"echo '' && echo '=== 記憶體使用 ===' && free -m\",
    \"echo '' && echo '=== 磁碟空間 ===' && df -h\"
  ]" \
  --output text \
  --query "Command.CommandId")

sleep 5 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

### 6. 執行遠端 Rails/Rake 命令（重要）

在遠端伺服器執行 Rails runner 或 Rake 任務時，**必須**使用以下格式：

**關鍵要點**：
- 必須設定 rbenv 的 PATH 和初始化
- 必須進入 `${APP_DIR}/current` 目錄
- 必須使用 `RAILS_ENV=production bundle exec` 執行

#### ⚠️ 前置步驟：確認 Schema 和 Model（強制）

> **在撰寫任何 Rails Runner / Console 腳本之前，必須先完成以下確認，禁止憑記憶猜測。**

1. **確認 Model class 名稱**：用 Grep 在本地專案搜尋正確的 class name 和 namespace
   ```bash
   # 範例：搜尋跟 invoice 相關的 model
   grep -r "class.*Invoice" {project_path}/app/models/ --include="*.rb"
   ```
2. **確認欄位名稱**：讀取本地專案的 `db/schema.rb`，找到對應的 table 確認欄位
   ```bash
   # 範例：找到 invoices table 的定義
   grep -A 30 'create_table "invoices"' {project_path}/db/schema.rb
   ```
3. 用確認過的 class name 和欄位名撰寫腳本

**專案路徑對照**（從 projects.yml）：

| 專案 | 本地路徑 |
|------|---------|
| core_web | /Users/liu/sunnyfounder/core_web |
| sf_project | /Users/liu/sunnyfounder/sf_project |
| jv_project | /Users/liu/sunnyfounder/jv_project |

**執行 Rails Runner**：

```bash
INSTANCE_ID="<從對照表查詢>"

# 步驟 1: 先建立腳本檔案
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands='["cat > /tmp/my_script.rb << '\''SCRIPT'\''
# 在這裡寫 Ruby 程式碼
puts User.count
SCRIPT"]' \
  --output text \
  --query "Command.CommandId")

# 步驟 2: 執行腳本（必須使用這個格式）
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands='["sudo su - apps -c '\''export PATH=\"/home/apps/.rbenv/bin:/home/apps/.rbenv/shims:$PATH\" && eval \"$(rbenv init -)\" && cd ${APP_DIR}/current && RAILS_ENV=production bundle exec rails runner /tmp/my_script.rb'\''"]' \
  --output text \
  --query "Command.CommandId")

sleep 30 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

**執行 Rake 任務**：

```bash
INSTANCE_ID="<從對照表查詢>"

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands='["sudo su - apps -c '\''export PATH=\"/home/apps/.rbenv/bin:/home/apps/.rbenv/shims:$PATH\" && eval \"$(rbenv init -)\" && cd ${APP_DIR}/current && RAILS_ENV=production bundle exec rake <TASK_NAME>'\''"]' \
  --output text \
  --query "Command.CommandId")

sleep 30 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

**執行 Rails Console 單行命令**：

```bash
INSTANCE_ID="<從對照表查詢>"

# 建立並執行腳本（一次完成）
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands='["cat > /tmp/query.rb << '\''SCRIPT'\''
# 範例：查詢專案資料
entity = ProjectManagement::Project::Client.new.retrieve_project(serial_number: \"RT130044\", version_serial_number: 1)
puts entity.cost_elements.map(&:category).uniq.sort
SCRIPT", "sudo su - apps -c '\''export PATH=\"/home/apps/.rbenv/bin:/home/apps/.rbenv/shims:$PATH\" && eval \"$(rbenv init -)\" && cd ${APP_DIR}/current && RAILS_ENV=production bundle exec rails runner /tmp/query.rb'\''"]' \
  --output text \
  --query "Command.CommandId")

sleep 30 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

**常見錯誤與解決**：

| 錯誤訊息 | 原因 | 解決方式 |
|---------|------|---------|
| `bundle: command not found` | 沒有設定 rbenv PATH | 使用上述完整格式 |
| `cannot load such file -- bundler` | 使用了系統 Ruby | 加入 `eval "$(rbenv init -)"` |
| `uninitialized constant` | 沒有進入正確目錄或沒用 bundle exec | 確認 cd 到 current 且用 bundle exec |

### 7. 備份遠端資料庫

使用 SSM 在遠端執行備份，然後下載：

```bash
# 在遠端建立備份
INSTANCE_ID="<從對照表查詢>"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[
    \"pg_dump -U postgres -d <DATABASE_NAME> -F c -b -f /tmp/backup_${TIMESTAMP}.dump\",
    \"ls -la /tmp/backup_${TIMESTAMP}.dump\"
  ]" \
  --output text \
  --query "Command.CommandId")

sleep 10 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

## Safety Guidelines

1. **認證安全**：
   - 永不在命令或腳本中硬編碼 credentials
   - 使用 AWS IAM roles 和 instance profiles

2. **執行前確認**：
   - 破壞性命令（如 `rm`, `drop`, `truncate`）前必須詢問用戶
   - 生產環境操作前二次確認
   - 顯示將要執行的完整命令讓用戶審核

3. **錯誤處理**：
   - 檢查命令執行狀態
   - 捕獲並報告所有錯誤輸出

## Common Patterns

### 部署應用到遠端伺服器

```bash
INSTANCE_ID="<從對照表查詢>"

# 執行部署步驟
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "cd ${APP_DIR}",
    "git pull origin master",
    "bundle install --deployment",
    "RAILS_ENV=production bundle exec rails db:migrate",
    "sudo systemctl restart puma",
    "sudo systemctl status puma --no-pager"
  ]' \
  --output text \
  --query "Command.CommandId")

sleep 30 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

### 健康檢查

```bash
INSTANCE_ID="<從對照表查詢>"

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "echo === System Info === && uptime && df -h && free -m",
    "echo === Service Status === && sudo systemctl status puma --no-pager | grep Active",
    "echo === Application Status === && cd ${APP_DIR} && git log -1 --oneline"
  ]' \
  --output text \
  --query "Command.CommandId")

sleep 5 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

## Expected Results

- AWS 認證檢查：顯示當前 IAM 用戶/角色資訊
- 實例列表：表格形式顯示實例 ID、IP、狀態、標籤
- SSM 命令：返回 Command ID，然後可獲取執行輸出

## Troubleshooting

### SSM 無法連接實例

```bash
# 檢查 SSM Agent 狀態
aws ssm describe-instance-information \
  --instance-information-filter-list key=InstanceIds,valueSet=<INSTANCE_ID>

# 檢查實例 IAM role
aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn'
```

### 命令執行失敗

```bash
# 檢查完整的命令輸出（包含錯誤）
aws ssm get-command-invocation \
  --command-id "<COMMAND_ID>" \
  --instance-id "<INSTANCE_ID>"
```

## Notes

- 此 skill 使用 AWS SSM 執行所有遠端命令，不使用 SSH
- 所有涉及生產環境的操作都會在執行前請求確認
- 命令執行後需等待幾秒再獲取結果
