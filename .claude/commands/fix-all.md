---
description: 修復 Review 發現的所有問題（TDD 流程）
---

# Fix All Issues

修復 Review 階段發現的所有問題（包含 suggestions），使用 TDD 流程。

---

## 前置檢查

1. 確認有 active 任務
2. 確認任務狀態為 `review`
3. 確認 `context.reviewFindings` 存在

---

## 執行步驟

### Step 1: 收集所有問題

從以下來源收集所有問題：
- `riskReview.findings`（所有 severity）
- `styleReview.issues`
- `styleReview.suggestions`

### Step 2: 更新任務 JSON

```json
{
  "status": "testing",
  "workflow": {
    "currentAgent": "tester",
    "pendingAction": "fix_review"
  },
  "context": {
    "reviewFindings": {
      "fixScope": "all"
    }
  },
  "history": [
    { "phase": "testing", "timestamp": "{ISO}", "reason": "fix-all" }
  ]
}
```

### Step 3: 更新 Kanban

執行 `shared/kanban-operations.md` 的「移動卡片」

### Step 4: 輸出訊息

```markdown
┌──────────────────────────────────────────────────────┐
│ 📋 修復所有問題                                      │
├──────────────────────────────────────────────────────┤
│ 📍 從：review                                        │
│ 📍 到：testing                                       │
│ 🔧 修復範圍：all (包含 suggestions)                  │
│                                                      │
│ 💡 可依序輸入：/clear → /continue 清理對話後繼續     │
│                                                      │
│ ═══ 待修復問題 ═══                                   │
│ 🔴 Critical: 3 項                                    │
│ 🟠 High: 2 項                                        │
│ 🟡 Medium: 3 項                                      │
│ 🟢 Low: 2 項                                         │
│ 💡 Suggestions: 6 項                                 │
│                                                      │
│ 總計：16 項                                          │
│                                                      │
│ 正在啟動 tester 補充測試...                          │
└──────────────────────────────────────────────────────┘
```

### Step 5: 呼叫 tester Agent

```
Task(
  subagent_type: "tester",
  prompt: "
    專案：{project}
    任務：補充測試案例以覆蓋 review 發現的所有問題
    任務 JSON：{task_json_path}
    模式：fix-review

    請執行：
    1. 讀取任務 JSON 的 context.reviewFindings
    2. 處理所有問題（不篩選 severity）
    3. 為每個問題生成測試案例
       - 注意：suggestions 可能不需要測試，但需要評估
    4. 執行測試確認失敗
    5. 更新任務 JSON 的 context.testFiles

    輸出格式請遵循 tester agent 的標準格式。
  "
)
```

### Step 6: 後續流程

同 fix-critical.md，依序：
1. tester 補測試
2. coder 修復
3. 回到 review（完整審查）
4. gate

---

## 注意事項

### Suggestions 處理

對於 `severity === "suggestion"` 的項目：
- 評估是否真的需要修復
- 可能只需要代碼改善，不需要新增測試
- coder 可自行判斷是否採納

### 時間考量

修復所有問題可能耗時較長，建議：
- 優先考慮 `/fix-critical` 快速上線
- 後續再用 `/fix-all` 完善

---

## 相關文件

- [fix-critical.md](.claude/commands/fix-critical.md) - 只修復 Critical
- [fix-high.md](.claude/commands/fix-high.md) - 修復 Critical + High
- [review-fix-workflow.md](docs/review-fix-workflow.md) - 完整設計文檔
