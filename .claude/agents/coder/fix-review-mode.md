# Fix-Review Mode 指南

當任務從 review 階段回到 development（透過 `/fix-critical`、`/fix-high`、`/fix-all`），coder 需要讀取 `reviewFindings` 來修復問題。

## 識別 Fix-Review 模式

檢查 prompt 中是否包含 `模式：fix-review`，或任務 JSON 的 `workflow.pendingAction === "fix_review"`。

## 處理流程

```
1. 讀取任務 JSON
2. 從 context.reviewFindings 取得問題列表
3. 根據 fixScope 篩選問題：
   - "critical": 只處理 severity === "critical"
   - "high": 處理 severity === "critical" 或 "high"
   - "all": 處理所有問題
4. 讀取 tester 新增的測試案例
5. 依序修復每個問題
6. 更新 context.modifiedFiles
```

## reviewFindings 結構

```json
{
  "context": {
    "reviewFindings": {
      "fixScope": "critical",
      "riskReview": {
        "findings": [
          {
            "id": "SEC-001",
            "severity": "critical",
            "category": "security",
            "file": "use_cases/void_current_invoice.rb",
            "line": "7-14",
            "title": "缺乏授權控制",
            "description": "任何人知道 serial 就能作廢發票",
            "suggestion": "加入 current_user 參數，檢查權限",
            "example": "yield authorize_user(receivable, current_user)"
          }
        ]
      }
    }
  }
}
```

## 修復實作範例

```ruby
# 問題 SEC-001: 缺乏授權控制
# suggestion: 加入 current_user 參數，檢查權限

def steps(serial:, void_reason:, current_user:)  # 新增參數
  receivable = yield retrieve_receivable(serial: serial)
  yield authorize_user(receivable: receivable, user: current_user)  # 新增步驟
  yield validate_input(void_reason: void_reason)
  yield check_erp_settlement(serial: serial)
  voided_receivable = yield void_invoice(receivable: receivable, reason: void_reason)
  yield save_receivable(receivable: voided_receivable)

  Success(voided_receivable)
end

private

def authorize_user(receivable:, user:)
  project = Project.find_by(serial: receivable.project_serial)
  return Failure('無權限操作此專案') unless user.can_manage?(project)
  return Failure('無權限作廢發票') unless user.has_role?(:accountant, :admin)

  Success()
end
```

## 需要用戶確認的情況

如果問題需要用戶決策（信心度 < 90%），必須先詢問：

```
根據分析，我發現 [具體情況]，但 [不確定點]，請確認應該如何處理？

例如：
- SEC-002 需要使用 Redis Lock，但專案是否已設定 Redis？
- SEC-001 授權邏輯應該用 Pundit 還是自訂 Ability？
```
