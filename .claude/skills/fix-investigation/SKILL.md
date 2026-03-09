---
name: fix-investigation
description: Fix 調查輔助工具，整合各種調查資源（Error Tracking、APM、Log、Code）並自動彙整調查結果。根據 Discovery Source 引導系統性調查流程。
version: 1.0.0
---

# Fix Investigation

系統性地調查 Bug，整合多種資料來源，自動彙整調查結果。

## Core Principles

> **系統性調查** - 根據問題類型選擇正確的調查流程，不遺漏任何線索

### 調查優先順序

```
1. 重現問題（Browser / 本地測試）
2. 閱讀相關程式碼（Read Code）
3. 查看 Server Log / Error Tracking
4. 使用 Rails Runner 確認資料狀態
5. 查看 Git History（最後手段）
```

## Instructions

### 1. 識別 Discovery Source

根據問題描述識別 Discovery Source（D1-D19）：

| ID | 名稱 | 特徵 |
|----|------|------|
| D1 | UI 顯示錯誤-靜態 | 頁面樣式、文字、排版問題 |
| D2 | UI 顯示錯誤-資料 | 顯示錯誤的資料值 |
| D3 | UI 行為錯誤 | 按鈕無反應、表單無法送出 |
| D4 | 資料錯誤 | 資料庫內容不正確 |
| D5 | Worker 失敗 | Sidekiq Job 執行失敗 |
| D6 | 排程錯誤 | Cron/排程任務未執行或錯誤 |
| D7 | Alert 告警 | 監控系統發出的告警 |
| D8 | 效能-回應慢 | API 或頁面回應時間過長 |
| D9 | 效能-資源耗盡 | Memory/CPU/Disk 不足 |
| D10 | 外部整合失敗 | 第三方 API 串接問題 |
| D12 | 權限問題 | 未授權存取或權限錯誤 |
| D13 | 資安漏洞 | 安全性問題 |
| D14 | 資料不一致 | 跨系統資料不同步 |
| D19 | RWD 問題 | 響應式設計問題 |

### 2. 執行調查流程

根據 Discovery Source 執行對應的調查流程：

#### D1: UI 顯示錯誤-靜態

```
Browser → Read Code → (?) 修復
```

1. **Browser**: 重現問題，截圖記錄
2. **Read Code**: 檢查 View/CSS/JS 檔案
3. 如果找到問題 → 修復

#### D2: UI 顯示錯誤-資料

```
Browser → Read Code → Server Log → (?) 修復
     ↘                    ↓
      Rails Runner   ← ←↙
```

1. **Browser**: 確認錯誤的資料值
2. **Read Code**: 追蹤資料來源（Controller/Service）
3. **Server Log**: 檢查是否有錯誤
4. **Rails Runner**: 確認資料庫實際值

#### D5: Worker 失敗

```
Server Log → Read Code → Rails Runner → (?) 修復
     ↓
Error Tracking（如有）
```

1. **Server Log**: 查看 Sidekiq log
   ```bash
   'commands=["sudo journalctl -u sidekiq -n 100 --no-pager | grep -i error"]'
   ```
2. **Read Code**: 檢查 Job 程式碼
3. **Rails Runner**: 確認相關資料狀態

#### D8: 效能-回應慢

```
APM → Read Code → Rails Runner → (?) 修復
              ↓
          Benchmark
```

1. **APM**: 確認慢查詢和瓶頸
2. **Read Code**: 檢查相關程式碼
3. **Benchmark**: 本地效能測試
4. **Rails Runner**: 確認 N+1 或資料量

### 3. 使用調查工具

#### Error Tracking 查詢

**Sentry/Rollbar/Bugsnag**（需人工查詢）：

```markdown
請到 Error Tracking 服務查詢以下資訊：

1. 搜尋關鍵字：{error_message}
2. 時間範圍：最近 7 天
3. 需要資訊：
   - Stack trace
   - 發生次數
   - 影響用戶數
   - 最近/首次發生時間
   - 相關 tag（browser, device, user）

請將結果貼回這裡。
```

#### Server Log 查詢

> 📋 實例資訊請讀取 `.claude/config/aws-instances.yml`，根據專案查詢 INSTANCE_ID 和 APP_DIR

```bash
INSTANCE_ID="<從 aws-instances.yml 查詢>"

# 查詢錯誤 log
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["grep -a -i \"error\\|exception\\|fail\" ${APP_DIR}/shared/log/production.log | tail -100"]' \
  --output text \
  --query "Command.CommandId")

sleep 10 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

#### Rails Runner 查詢

> **⚠️ 強制前置步驟：在撰寫任何 Rails Runner 查詢之前，必須先確認 Schema 和 Model，禁止憑記憶猜測。**
>
> 1. **確認 Model class 名稱**：用 Grep 在本地專案搜尋正確的 class name 和 namespace
>    ```
>    grep -r "class.*Invoice" {project_path}/app/models/ --include="*.rb"
>    ```
> 2. **確認欄位名稱**：讀取本地專案的 `db/schema.rb`，找到對應 table 確認欄位
>    ```
>    grep -A 30 'create_table "invoices"' {project_path}/db/schema.rb
>    ```
> 3. 用確認過的 class name 和欄位名撰寫腳本
>
> **專案本地路徑**：core_web → `/Users/liu/sunnyfounder/core_web`、sf_project → `/Users/liu/sunnyfounder/sf_project`、jv_project → `/Users/liu/sunnyfounder/jv_project`

```bash
# 查詢特定資料
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands='["cat > /tmp/query.rb << '\''SCRIPT'\''
# 調查查詢
record = Invoice.find_by(serial: \"INV-001\")
puts \"Status: #{record.status}\"
puts \"Amount: #{record.amount}\"
puts \"Created: #{record.created_at}\"
puts \"Project: #{record.project&.serial}\"
SCRIPT", "sudo su - apps -c '\''export PATH=\"/home/apps/.rbenv/bin:/home/apps/.rbenv/shims:$PATH\" && eval \"$(rbenv init -)\" && cd ${APP_DIR}/current && RAILS_ENV=production bundle exec rails runner /tmp/query.rb'\''"]' \
  --output text \
  --query "Command.CommandId")

sleep 30 && aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
```

### 4. 彙整調查結果

調查完成後，輸出調查報告：

```markdown
┌──────────────────────────────────────────────────────┐
│ 🔍 調查報告                                          │
├──────────────────────────────────────────────────────┤
│ 📋 問題描述：{problem_description}                   │
│ 🔖 Discovery Source：D2（UI 顯示錯誤-資料）          │
│                                                      │
│ 📊 調查結果：                                        │
├──────────────────────────────────────────────────────┤
│ 1. Browser 重現：                                    │
│    • 頁面：/projects/123/invoices                    │
│    • 現象：金額顯示 $0 而非 $10,000                  │
│    • 截圖：[已記錄]                                  │
│                                                      │
│ 2. Read Code：                                       │
│    • 檔案：app/views/invoices/show.html.erb:45      │
│    • 問題：使用了 invoice.amount 而非 invoice.total │
│                                                      │
│ 3. Rails Runner：                                    │
│    • Invoice#amount = 0（僅商品金額）                │
│    • Invoice#total = 10000（含稅金額）               │
│                                                      │
├──────────────────────────────────────────────────────┤
│ 🎯 根本原因：                                        │
│    View 使用了錯誤的欄位，應使用 total 而非 amount   │
│                                                      │
│ 💡 建議修復：                                        │
│    修改 show.html.erb:45，將 amount 改為 total       │
│                                                      │
│ 📊 信心度：95%                                       │
│                                                      │
│ 📝 輸入 /continue 開始修復                           │
└──────────────────────────────────────────────────────┘
```

## Common Investigation Patterns

### Pattern 1: 追蹤資料流

```
用戶輸入 → Controller → Service → Repository → Database
                ↓
            Response → View → 用戶看到的
```

**檢查點**：
1. Controller 收到什麼參數？
2. Service 處理後的結果？
3. Repository 查詢/寫入什麼？
4. Database 實際儲存什麼？

### Pattern 2: 追蹤錯誤堆疊

```
1. 從 Error Tracking 取得 stack trace
2. 定位到第一個應用程式檔案
3. 閱讀該檔案的上下文
4. 確認輸入和預期輸出
5. 找出不符合預期的地方
```

### Pattern 3: 時間線分析

```
1. 確認問題首次發生時間
2. 檢查該時間前後的 deploy
3. 比對 git log 找出可疑 commit
4. 驗證假設
```

## Safety Guidelines

### 調查時禁止

```
❌ 在 Production 執行任何 UPDATE/DELETE
❌ 修改 Production 設定
❌ 重啟 Production 服務（除非緊急且經過確認）
```

### 調查時允許

```
✅ 讀取 log
✅ 執行 SELECT 查詢（透過 Rails Runner）
✅ 重現問題（在 Browser）
✅ 閱讀程式碼
```

## Integration with ATDD Workflow

此 Skill 在 Fix 任務的 `requirement` 階段使用：

```
/fix 啟動 → specist 呼叫 fix-investigation → 調查報告 → 信心度評估 → testing
```

調查報告會記錄到任務 JSON：

```json
{
  "context": {
    "investigation": {
      "discoverySource": "D2",
      "findings": [...],
      "rootCause": "...",
      "suggestedFix": "...",
      "confidence": 95
    }
  }
}
```
