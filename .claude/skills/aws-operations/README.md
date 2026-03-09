# AWS Operations Skill

AWS EC2 實例管理與遠端操作的 Claude Skill，將 aws-connect MCP 的功能轉換為可直接執行的 CLI 命令範本。

## 功能

替代原本的 `aws-connect` MCP，提供以下操作：

| MCP 功能 | Skill 實現方式 | CLI 命令 |
|----------|---------------|----------|
| `aws_check_auth` | AWS CLI | `aws sts get-caller-identity` |
| `aws_list_instances` | AWS CLI | `aws ec2 describe-instances` |
| `aws_connect_ec2` | SSH | `ssh -i <key> <user>@<ip> "<cmd>"` |
| `aws_execute_remote` | SSH | `ssh -i <key> <user>@<ip> 'bash -s' < script.sh` |
| `aws_execute_ssm` | AWS CLI | `aws ssm send-command` |
| `aws_backup_database` | SSH + pg_dump/mysqldump | 自動化腳本 |

## 使用方式

### 方式 1: 透過 Claude Code (推薦)

直接向 Claude 下達指令，Claude 會自動使用此 skill：

```
列出所有運行中的 EC2 實例
```

```
連接到生產環境伺服器並檢查狀態
```

```
備份 production 資料庫
```

### 方式 2: 手動使用命令範本

從 SKILL.md 中複製命令範本，根據需求修改參數後執行。

## 前置需求

1. **AWS CLI**
   ```bash
   # macOS
   brew install awscli

   # 驗證安裝
   aws --version

   # 配置認證
   aws configure
   ```

2. **SSH Keys**
   ```bash
   # 確保 keys 存在且權限正確（依專案設定）
   chmod 400 ~/.ssh/<PROJECT>_<ENVIRONMENT>.pem
   ```

3. **AWS Credentials**
   ```bash
   # 檢查配置
   cat ~/.aws/credentials
   cat ~/.aws/config
   ```

## 與 MCP 的差異

### MCP 方式（舊）
```python
# 需要啟動獨立的 MCP server
await mcp.aws_connect.aws_list_instances()
```

### Skill 方式（新）
```bash
# Claude 直接使用 Bash tool 執行
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
  --output table
```

## 優勢

1. **無需額外進程**：不需要啟動 MCP server
2. **透明可控**：可直接看到執行的命令
3. **易於調試**：命令輸出直接可見
4. **可自訂**：容易根據需求調整參數
5. **版本控制**：Skill 文件可納入專案版控

## 常見使用場景

### 場景 1: 部署檢查

```
請檢查生產環境伺服器狀態，包括系統資源和關鍵服務
```

Claude 會執行：
- 列出生產環境實例
- SSH 連接並檢查 uptime、memory、disk
- 檢查 puma、postgresql、nginx 狀態

### 場景 2: 緊急備份

```
立即備份生產環境資料庫
```

Claude 會執行：
- 自動取得實例 IP
- 透過 SSH 執行 pg_dump
- 壓縮並儲存到本地
- 報告備份檔案大小

### 場景 3: 批次部署

```
在所有 staging 伺服器上更新代碼並重啟服務
```

Claude 會執行：
- 列出所有 staging 實例
- 逐一執行 git pull
- bundle install
- 重啟服務

## 安全性

此 skill 遵循以下安全原則：

1. **命令審查**：所有破壞性命令執行前會請求確認
2. **環境隔離**：明確區分 production 和 staging
3. **憑證保護**：不在命令中硬編碼密碼或 keys
4. **日誌記錄**：重要操作會記錄執行日誌

## 疑難排解

### Claude 沒有自動使用此 skill

確認 skill 描述清晰，包含關鍵字：
- AWS
- EC2
- 實例
- 遠端
- 伺服器
- 部署

### SSH 連接失敗

```bash
# 檢查 key 權限
ls -la ~/.ssh/*.pem

# 應該是 -r--------
chmod 400 ~/.ssh/*.pem
```

### AWS CLI 認證錯誤

```bash
# 重新配置
aws configure

# 測試認證
aws sts get-caller-identity
```

## 擴展

需要新增功能時，編輯 `SKILL.md` 加入新的命令範本。

範例：新增 RDS 快照功能

```markdown
### 7. 建立 RDS 快照

bash
aws rds create-db-snapshot \
  --db-instance-identifier <DB_INSTANCE_ID> \
  --db-snapshot-identifier <PROJECT>-$(date +%Y%m%d-%H%M%S)
```

## 參考資料

- [AWS CLI 命令參考](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [SSH 最佳實踐](https://www.ssh.com/academy/ssh/command)
- [PostgreSQL pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)

## 版本歷史

- v1.0.0 (2025-11-27) - 初始版本，將 aws-connect MCP 轉換為 Skill
