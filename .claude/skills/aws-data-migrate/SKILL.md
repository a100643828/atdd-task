---
name: aws-data-migrate
description: 資料遷移工具，從 Production 安全地遷移資料到 Local/Staging 環境。自動清理敏感資料，硬編碼禁止反向遷移。
version: 1.0.0
---

# AWS Data Migrate

安全地從 Production 環境遷移資料到 Local/Staging，用於本地除錯和測試。

## Core Principles

> **Production 資料不可變** - 只允許 Production → Local/Staging 的單向遷移

### 允許的遷移方向

```
✅ Production → Local
✅ Production → Staging
❌ Local → Production     # 硬性禁止
❌ Staging → Production   # 硬性禁止
❌ Local → Staging        # 需要討論
```

## Prerequisites

- AWS CLI 已配置且認證有效
- 本地資料庫已建立（PostgreSQL）
- 有 Production 資料庫的讀取權限

## Instructions

### 1. 確認遷移需求

在開始遷移前，必須確認：

```markdown
📦 資料遷移需求確認

1. 需要遷移的 Table(s)：{tables}
2. 資料時間範圍：{date_range}
3. 是否需要關聯資料：{yes/no}
4. 敏感資料處理方式：{mask/remove/keep}
5. 目標環境：{local/staging}

請確認以上資訊是否正確？
```

### 2. 識別敏感欄位

自動偵測以下類型的敏感欄位：

| 類型 | 欄位名稱模式 | 處理方式 |
|------|-------------|---------|
| Email | `*email*`, `*mail*` | 替換為 `xxx@example.com` |
| 電話 | `*phone*`, `*tel*`, `*mobile*` | 替換為 `0900-000-000` |
| 地址 | `*address*` | 替換為 `測試地址` |
| 密碼 | `*password*`, `*passwd*` | 清空或替換為固定 hash |
| Token | `*token*`, `*secret*`, `*key*` | 清空 |
| 身分證 | `*id_number*`, `*identity*` | 替換為 `A000000000` |
| 銀行帳號 | `*bank*`, `*account*` | 替換為 `000-0000000` |

### 3. 建立遷移腳本

**基本結構**：

```ruby
# /tmp/migrate_data.rb
# 資料遷移腳本
# 建立時間：{timestamp}
# 目的：{description}
# 預計刪除：執行後立即刪除

require 'csv'

# 1. 查詢需要的資料
data = {Model}.where({conditions}).limit({limit})

# 2. 輸出為 CSV（不含敏感資料）
CSV.open('/tmp/export.csv', 'w') do |csv|
  csv << data.first.attributes.keys.reject { |k| sensitive_columns.include?(k) }
  data.each do |record|
    csv << record.attributes.values_at(*safe_columns)
  end
end

puts "Exported #{data.count} records"
```

### 4. 執行 Production 資料匯出

**方法 A：使用 Rails Runner**

```bash
INSTANCE_ID="<從 aws-instances.yml 查詢>"

# 建立並執行匯出腳本
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands='["cat > /tmp/export_data.rb << '\''SCRIPT'\''
# 匯出腳本
records = Invoice.where(created_at: 30.days.ago..Time.current).limit(100)

require \"csv\"
CSV.open(\"/tmp/export.csv\", \"w\") do |csv|
  csv << [\"id\", \"serial\", \"amount\", \"status\", \"created_at\"]
  records.each do |r|
    csv << [r.id, r.serial, r.amount, r.status, r.created_at]
  end
end
puts \"Exported #{records.count} records\"
SCRIPT", "sudo su - apps -c '\''export PATH=\"/home/apps/.rbenv/bin:/home/apps/.rbenv/shims:$PATH\" && eval \"$(rbenv init -)\" && cd ${APP_DIR}/current && RAILS_ENV=production bundle exec rails runner /tmp/export_data.rb'\''"]' \
  --output text \
  --query "Command.CommandId")

sleep 30 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

**方法 B：使用 pg_dump（單表）**

```bash
INSTANCE_ID="<從 aws-instances.yml 查詢>"
TABLE_NAME="invoices"

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands="[\"pg_dump -U postgres -d sf_project_production -t ${TABLE_NAME} --data-only -f /tmp/${TABLE_NAME}.sql\", \"ls -la /tmp/${TABLE_NAME}.sql\"]" \
  --output text \
  --query "Command.CommandId")

sleep 10 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

### 5. 下載匯出的資料

```bash
# 從遠端 cat 出 CSV 內容
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cat /tmp/export.csv"]' \
  --output text \
  --query "Command.CommandId")

sleep 5 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text > /tmp/downloaded_data.csv
```

### 6. 清理敏感資料（本地處理）

```ruby
# 本地清理腳本
require 'csv'

SENSITIVE_COLUMNS = %w[email phone address password_digest token]

# 讀取並清理
data = CSV.read('/tmp/downloaded_data.csv', headers: true)

data.each do |row|
  row['email'] = "test_#{row['id']}@example.com" if row['email']
  row['phone'] = '0900-000-000' if row['phone']
  row['address'] = '測試地址' if row['address']
  row['password_digest'] = nil if row['password_digest']
  row['token'] = nil if row['token']
end

# 輸出清理後的資料
CSV.open('/tmp/sanitized_data.csv', 'w') do |csv|
  csv << data.headers
  data.each { |row| csv << row.values_at(*data.headers) }
end
```

### 7. 匯入到本地資料庫

```bash
# 使用 psql COPY
# 路徑從 .claude/config/projects.yml 取得
cd {project_path}
RAILS_ENV=development rails runner "
  require 'csv'
  CSV.foreach('/tmp/sanitized_data.csv', headers: true) do |row|
    Invoice.create!(row.to_h.except('id'))
  end
"

# 或使用 SQL COPY
psql -d sf_project_development -c "COPY invoices FROM '/tmp/sanitized_data.csv' CSV HEADER"
```

### 8. 驗證資料完整性

```bash
# 確認 record count（路徑從 .claude/config/projects.yml 取得）
cd {project_path}
rails runner "puts 'Local count: ' + Invoice.count.to_s"

# 確認關聯資料
rails runner "
  Invoice.last(10).each do |inv|
    puts \"#{inv.serial}: project=#{inv.project.present?}, items=#{inv.items.count}\"
  end
"
```

### 9. 清理遠端暫存檔案

```bash
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["rm -f /tmp/export_data.rb /tmp/export.csv /tmp/*.sql", "ls -la /tmp/*.csv /tmp/*.sql 2>/dev/null || echo No temp files found"]' \
  --output text \
  --query "Command.CommandId")

sleep 5 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

## Safety Guidelines

### 絕對禁止

```
❌ 將 Local/Staging 資料推到 Production
❌ 直接在 Production 執行 UPDATE/DELETE
❌ 保留未清理的敏感資料
❌ 遷移超過必要範圍的資料
```

### 必須執行

```
✅ 遷移前確認需求和範圍
✅ 自動偵測並清理敏感欄位
✅ 遷移後清理遠端暫存檔案
✅ 驗證本地資料完整性
```

## Common Patterns

### 遷移特定專案的資料

```ruby
# 匯出與專案相關的所有資料
project = Project.find_by(serial: 'RT130044')
export_data = {
  project: project.attributes,
  invoices: project.invoices.map(&:attributes),
  payments: project.payments.map(&:attributes)
}
File.write('/tmp/project_data.json', export_data.to_json)
```

### 遷移指定時間範圍

```ruby
# 最近 30 天的資料
Invoice.where(created_at: 30.days.ago..Time.current)
  .includes(:project, :items)
```

### 只遷移結構（不含資料）

```bash
# 只匯出 schema
pg_dump -U postgres -d sf_project_production --schema-only -f /tmp/schema.sql
```

## Output Format

遷移完成後輸出：

```markdown
┌──────────────────────────────────────────────────────┐
│ 📦 資料遷移完成                                       │
├──────────────────────────────────────────────────────┤
│ 來源：Production (<INSTANCE_ID>)                      │
│ 目標：Local (development)                            │
│                                                      │
│ 📊 遷移統計：                                        │
│   • invoices: 100 筆                                 │
│   • payments: 45 筆                                  │
│                                                      │
│ 🔒 敏感資料處理：                                    │
│   • email: 已替換                                    │
│   • phone: 已替換                                    │
│                                                      │
│ ✅ 遠端暫存已清理                                    │
│ ✅ 本地資料已驗證                                    │
└──────────────────────────────────────────────────────┘
```
