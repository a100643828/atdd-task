---
name: debug-tips
description: Debug 經驗知識庫查詢工具。偵測調查卡住的行為訊號，並從知識庫中查詢相關的除錯提示。
version: 1.0.0
---

# Debug Tips

協助開發者在除錯過程中，利用過去累積的經驗快速定位和解決問題。

## 核心功能

1. **卡住行為偵測**：偵測重複失敗、長時間無進展等行為訊號
2. **知識庫查詢**：根據問題類型和症狀查詢相關提示
3. **最佳路徑建議**：提供最有效的調查順序

## 使用時機

此 Skill 會在以下情況被觸發：

- 手動呼叫 `/debug-tips {症狀描述}`
- coder agent 偵測到卡住行為訊號（自動觸發）
- 重複嘗試相同方法失敗 3+ 次

## Instructions

### Step 1: 評估是否需要查詢知識庫

根據以下行為訊號判斷（不打分，純行為偵測）：

```
IF 重複嘗試相同方法失敗 >= 3 次
  → 觸發知識庫查詢

IF 已執行 10+ 次工具呼叫但 task JSON 仍無 investigation.rootCause
  → 觸發知識庫查詢

IF 調查方向不斷切換（嘗試了 3+ 個不同方向都沒結果）
  → 觸發知識庫查詢

OTHERWISE
  → 繼續當前調查
```

### Step 4: 識別問題類型

根據當前任務的 fix profile 或症狀，確定問題類型：

| Profile | 資料夾 | 典型症狀 |
|---------|--------|----------|
| ui | `debug-knowledge/ui/` | 頁面顯示異常、JS 錯誤、CSS 問題 |
| data | `debug-knowledge/data/` | 資料不一致、DB 錯誤、遷移問題 |
| worker | `debug-knowledge/worker/` | 背景任務失敗、Queue 問題 |
| performance | `debug-knowledge/performance/` | 慢查詢、記憶體問題、N+1 |
| integration | `debug-knowledge/integration/` | API 錯誤、第三方服務問題 |
| alert | `debug-knowledge/alert/` | 監控警報、日誌異常 |
| security | `debug-knowledge/security/` | 權限問題、認證失敗 |

### Step 5: 查詢知識庫

```bash
# 讀取 tag 分類法
cat debug-knowledge/tag-taxonomy.yml

# 列出該類型的所有 tips
ls debug-knowledge/{type}/

# 讀取相關 tip 檔案
cat debug-knowledge/{type}/{tip_file}.yml
```

**匹配策略（優先順序）**：

1. **Tag 匹配**（最快）：
   - 從當前任務提取 tags（domain, layer, error_pattern）
   - 與 tip 的 `tags` 欄位進行集合交集
   - 計算匹配分數（參考 tag-taxonomy.yml 的 scoring）

2. **關鍵字匹配**：比對 `identification.keywords`
3. **症狀匹配**：比對 `identification.symptoms`
4. **錯誤訊息匹配**：比對 `identification.error_patterns`
5. **情境匹配**：比對 `identification.typical_context`

**Tag 匹配算法**：

```
score = 0
for each tag_category in [error_pattern, domain, layer, technology]:
  task_tags = extract_tags_from_task(task, tag_category)
  tip_tags = tip.tags[tag_category]
  matched = intersection(task_tags, tip_tags)
  weight = priority_weights[tag_category]
  score += len(matched) * exact_match_score * weight

if score >= threshold:
  return tip as matched
```

**Tag 提取規則**（從任務 JSON）：

| 任務欄位 | 提取的 Tag 類別 |
|----------|----------------|
| `domain` | domain |
| `context.modifiedFiles` | layer（根據路徑判斷） |
| `context.background` | error_pattern（關鍵字提取） |
| `type` + fix profile | fix_profile |

### Step 6: 輸出建議

找到匹配的 tip 後，輸出：

```markdown
┌──────────────────────────────────────────────────────┐
│ 💡 Debug Tips 建議                                   │
├──────────────────────────────────────────────────────┤
│                                                      │
│ 📍 匹配到的已知問題：{tip.title}                     │
│ 📁 來源：debug-knowledge/{type}/{file}.yml          │
│                                                      │
│ 🔍 問題根源：                                        │
│ {tip.root_cause.summary}                             │
│                                                      │
│ 📋 建議調查路徑：                                    │
│ 1. {investigation_path.steps[0].action}              │
│ 2. {investigation_path.steps[1].action}              │
│ 3. ...                                               │
│                                                      │
│ ⚠️ 避免：                                            │
│ • {investigation_path.anti_patterns[0]}              │
│                                                      │
│ 🔧 解決方案摘要：                                    │
│ {solution.proper_fix.description}                    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### Step 7: 無匹配時的處理

如果沒有找到匹配的 tip：

```markdown
┌──────────────────────────────────────────────────────┐
│ 📭 未找到匹配的 Debug Tips                           │
├──────────────────────────────────────────────────────┤
│                                                      │
│ 這可能是一個新的問題類型。                           │
│                                                      │
│ 建議：                                               │
│ 1. 繼續系統性調查                                    │
│ 2. 解決後將經驗記錄到知識庫                          │
│                                                      │
│ 記錄位置：                                           │
│ debug-knowledge/{type}/{描述性檔名}.yml              │
│                                                      │
│ 範本位置：                                           │
│ debug-knowledge/tip-template.yml                     │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## 自動觸發規則

coder agent 處理 fix 類型任務時，以下行為會自動觸發知識庫查詢：

| 規則 | 偵測條件 | 動作 |
|------|----------|------|
| 重複失敗 | 相同方法失敗 >= 3 次 | 查詢 tips |
| 長時間無進展 | 工具呼叫 >= 10 次且無 rootCause | 查詢 tips |
| 方向不明 | 嘗試 3+ 個不同方向都沒結果 | 查詢 tips |

## 與 coder agent 整合

當 coder agent 處理 fix 類型任務時：

1. **進入 development 階段**：載入對應 fix profile 的 tips 索引
2. **偵測到卡住訊號**：自動查詢並顯示相關 tips
3. **Gate 阻擋**：若 task JSON 無 `investigation.rootCause` 和 `investigation.reproduction`，編輯程式碼會被 `confidence-gate.sh` 阻擋
4. **問題解決後**：提示是否要將新經驗加入知識庫

## 新增 Debug Tip

解決新問題後，使用範本建立新的 tip：

```bash
# 複製範本
cp debug-knowledge/tip-template.yml \
   debug-knowledge/{type}/{描述性名稱}.yml

# 編輯填入內容
```

**命名慣例**：
- 使用 kebab-case
- 包含關鍵識別詞
- 例如：`2fa-local-user-mismatch.yml`、`n-plus-one-eager-loading.yml`

## 查詢語法（手動呼叫）

```
/debug-tips 2FA 登入失敗
/debug-tips N+1 查詢效能問題
/debug-tips Sidekiq 任務卡住
```

Skill 會：
1. 解析關鍵字
2. 搜尋所有類型資料夾
3. 返回最相關的 tips
