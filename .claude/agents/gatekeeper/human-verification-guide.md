# 人工驗收指南生成規則

> **重要**：人工驗收指南是框架的**保險機制**，**無論任何情況都必須提供**。

## 適用情況

- GO 決策 → 仍提供（作為二次確認）
- CONDITIONAL GO → 提供（作為主要驗收方式）
- NO-GO → 提供（修復後可用）

## 指南內容

1. 驗收環境準備（setup script）
2. 驗收步驟摘要
3. 預期結果清單
4. E2E 錄製連結（如有）
5. Console 驗證指令（calculation profile）
6. 清理方式（teardown script）

## E2E Profile 格式

```markdown
═══ 人工驗收指南 ═══

📋 驗收清單：
1. [ ] 發票狀態正確顯示為「已作廢」
2. [ ] 顯示成功訊息
3. [ ] 作廢原因已記錄

🎬 E2E 錄製（可直接觀看）：
   recordings/{task_id}/e2e.gif

📹 或手動驗收：

環境準備：
  cd {project_path} && rails runner db/seeds/acceptance/{task}_setup.rb

驗收步驟：
  1. 登入系統（test@example.com / password）
  2. 進入發票管理頁面（/accounting/invoices）
  3. 找到編號 ACC-{task_id}-INV-001 的發票
  4. 點擊「作廢」按鈕
  5. 填入作廢原因並確認

預期結果：
  • 發票狀態變更為「已作廢」
  • 顯示綠色成功訊息
  • 系統記錄作廢時間和原因

清理環境：
  cd {project_path} && rails runner db/seeds/acceptance/{task}_cleanup.rb
```

## Calculation Profile 格式（無 E2E）

```markdown
═══ 人工驗收指南 ═══

📦 驗收類型：calculation（無 E2E）

📋 自動化測試結果：
  ✅ 6 個單元測試通過
  ✅ 3 個整合測試通過

═══ 手動驗收方式 ═══

### 方式 1：Rails Console 驗證

```ruby
# 在 staging 環境的 Rails console 執行

# 1. 驗證 {場景1標題}
{具體的 console 程式碼}
# 預期結果：{預期輸出}

# 2. 驗證 {場景2標題}
{具體的 console 程式碼}
# 預期結果：{預期輸出}
```

### 方式 2：下次業務流程執行時驗證

等下次 {業務流程名稱} 執行時，檢查：
- [ ] {檢查項目1}
- [ ] {檢查項目2}

### 驗收檢查清單

| 項目 | 預期結果 | 驗證方式 |
|------|---------|---------|
| {項目1} | {預期1} | Console / Log |
| {項目2} | {預期2} | DB 查詢 |
```

## Gatekeeper 生成指南時必須

1. 根據 spec 中的場景，為每個場景提供具體驗證方式
2. 識別相關的業務流程，提供「下次執行時驗證」的檢查清單
3. 生成明確的驗收檢查清單表格
