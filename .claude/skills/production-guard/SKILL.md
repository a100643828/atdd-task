---
name: production-guard
description: Production 環境保護機制，攔截所有可能影響 Production 的操作，強制要求確認，記錄所有存取。
version: 1.0.0
---

# Production Guard

保護 Production 環境免於意外或未授權的修改操作。

## Core Principles

> **Production 資料不可變** - 除非經過明確確認，否則禁止所有寫入操作

### 保護層級

| 層級 | 操作類型 | 處理方式 |
|------|---------|---------|
| 🔴 禁止 | DDL (DROP, TRUNCATE, ALTER) | 絕對禁止，無法覆蓋 |
| 🟠 需確認 | DML (UPDATE, DELETE, INSERT) | 需要人類明確確認 |
| 🟡 警告 | 讀取敏感資料 | 記錄並警告 |
| 🟢 允許 | 一般讀取 (SELECT) | 允許但記錄 |

## Instructions

### 1. 操作類型識別

在執行任何 Production 操作前，識別操作類型：

#### Query（讀取）操作 - 🟢 允許

```ruby
# 安全的讀取操作
User.find(1)
Invoice.where(status: 'pending').count
Project.includes(:invoices).first
```

#### Command（寫入）操作 - 🟠 需確認

```ruby
# 需要確認的操作
Invoice.find(1).update(status: 'voided')  # 🟠
User.create(email: 'test@example.com')     # 🟠
Payment.destroy_all                         # 🔴 禁止
```

### 2. 攔截機制

當偵測到 Production 寫入操作時，強制中斷並要求確認：

```markdown
┌──────────────────────────────────────────────────────┐
│ ⚠️ PRODUCTION WRITE OPERATION DETECTED              │
├──────────────────────────────────────────────────────┤
│                                                      │
│ 🔴 操作類型：UPDATE                                  │
│ 📍 目標：Production (<INSTANCE_ID>)                  │
│                                                      │
│ 📝 即將執行的操作：                                  │
│ ```ruby                                              │
│ Invoice.find(123).update(status: 'voided')          │
│ ```                                                  │
│                                                      │
│ 影響範圍：                                           │
│ • Table: invoices                                    │
│ • Record ID: 123                                     │
│ • Changed fields: status                             │
│                                                      │
│ ⚠️ 此操作將修改 Production 資料，且無法自動復原！   │
│                                                      │
│ 請輸入以下任一選項：                                 │
│ • YES - 確認執行                                     │
│ • NO  - 取消操作                                     │
│ • DRY - 執行 dry-run（只顯示會做什麼）              │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### 3. 絕對禁止的操作

以下操作**無法透過確認覆蓋**，必須拒絕：

```ruby
# DDL 操作
DROP TABLE users;                    # 🔴 絕對禁止
TRUNCATE invoices;                   # 🔴 絕對禁止
ALTER TABLE projects DROP COLUMN;   # 🔴 絕對禁止

# 批量刪除
User.destroy_all                     # 🔴 絕對禁止
Invoice.delete_all                   # 🔴 絕對禁止
Model.where(...).delete_all          # 🔴 絕對禁止（無 limit）

# 危險的更新
User.update_all(admin: true)         # 🔴 絕對禁止
Model.where(...).update_all(...)     # 🔴 絕對禁止（無 limit）
```

**拒絕訊息**：

```markdown
┌──────────────────────────────────────────────────────┐
│ 🔴 OPERATION BLOCKED - CANNOT OVERRIDE              │
├──────────────────────────────────────────────────────┤
│                                                      │
│ 偵測到危險操作：                                     │
│ ```sql                                               │
│ TRUNCATE TABLE invoices                              │
│ ```                                                  │
│                                                      │
│ 此操作被歸類為「絕對禁止」，原因：                   │
│ • 批量刪除資料無法復原                               │
│ • 可能導致資料永久遺失                               │
│                                                      │
│ 如果確實需要執行此操作，請：                         │
│ 1. 直接登入 Production 手動執行                      │
│ 2. 確保已有完整備份                                  │
│ 3. 取得相關人員核准                                  │
│                                                      │
│ Claude 不會協助執行此類操作。                        │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### 4. Dry-Run 模式

對於需確認的操作，提供 dry-run 模式：

```ruby
# Dry-run 範例
def dry_run_update(record, attributes)
  puts "=== DRY RUN MODE ==="
  puts "Target: #{record.class.name}##{record.id}"
  puts "Current values:"
  attributes.keys.each do |key|
    puts "  #{key}: #{record.send(key)}"
  end
  puts "New values:"
  attributes.each do |key, value|
    puts "  #{key}: #{value}"
  end
  puts "=== NO CHANGES MADE ==="
end
```

### 5. 操作記錄

所有 Production 存取都會記錄：

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "operation": "UPDATE",
  "target": "Production",
  "instance_id": "<INSTANCE_ID>",
  "details": {
    "table": "invoices",
    "record_id": 123,
    "changes": {
      "status": ["pending", "voided"]
    }
  },
  "user_confirmed": true,
  "task_id": "abc-123-def",
  "executed": true
}
```

記錄位置：`logs/production-access.jsonl`

## Detection Patterns

### Rails Runner 命令偵測

```ruby
WRITE_PATTERNS = [
  /\.save[!]?/,
  /\.update[!]?/,
  /\.create[!]?/,
  /\.destroy[!]?/,
  /\.delete/,
  /update_all/,
  /delete_all/,
  /destroy_all/,
  /\.increment!/,
  /\.decrement!/,
  /\.toggle!/,
  /ActiveRecord::Base\.connection\.execute/
]

def contains_write_operation?(code)
  WRITE_PATTERNS.any? { |pattern| code.match?(pattern) }
end
```

### SQL 命令偵測

```ruby
DANGEROUS_SQL = [
  /\bINSERT\b/i,
  /\bUPDATE\b/i,
  /\bDELETE\b/i,
  /\bDROP\b/i,
  /\bTRUNCATE\b/i,
  /\bALTER\b/i,
  /\bCREATE\b/i
]

def dangerous_sql?(query)
  DANGEROUS_SQL.any? { |pattern| query.match?(pattern) }
end
```

## Integration with Other Skills

### aws-operations

當 aws-operations 要執行 Rails Runner 時：

```
1. 解析要執行的 Ruby 程式碼
2. 檢查是否包含寫入操作
3. 如果是寫入 → 觸發 production-guard
4. 如果是讀取 → 允許但記錄
```

### aws-data-migrate

確保遷移方向正確：

```
1. 檢查來源和目標
2. 如果目標是 Production → 絕對禁止
3. 記錄遷移操作
```

## Safety Guidelines

### 操作原則

```
✅ 預設拒絕所有 Production 寫入
✅ 明確確認後才執行
✅ 記錄所有存取
✅ 提供 dry-run 選項
✅ 危險操作絕對禁止

❌ 自動執行任何寫入
❌ 忽略確認步驟
❌ 執行 DDL 操作
❌ 批量刪除/更新
```

### 例外情況

即使經過確認，以下情況仍需特別注意：

1. **緊急修復**：需要更高層級的確認
2. **資料修正**：需要提供修正腳本和復原計畫
3. **批量操作**：必須先在 Staging 測試

## Output Format

操作完成後記錄：

```markdown
┌──────────────────────────────────────────────────────┐
│ ✅ Production 操作已完成                             │
├──────────────────────────────────────────────────────┤
│ 🕐 時間：2024-01-15 10:30:00 UTC                    │
│ 📍 目標：Production (<INSTANCE_ID>)                  │
│ 🔧 操作：UPDATE invoices SET status='voided'        │
│ 📊 影響：1 筆記錄                                    │
│ ✅ 確認者：User                                      │
│ 📝 已記錄到：logs/production-access.jsonl │
└──────────────────────────────────────────────────────┘
```
