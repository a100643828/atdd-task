# E2E 測試決策矩陣

## 決策邏輯

```
| e2e.required | e2eMode | results.e2e.status | 決策 |
|--------------|---------|-------------------|------|
| false | - | - | GO（不需要 E2E）|
| true | "auto" | "passed" | GO |
| true | "auto" | "failed" | NO-GO |
| true | "auto" | 缺失 | NO-GO（E2E 應執行但未執行）|
| true | "manual" | "manual_pending" | CONDITIONAL GO |
| true | "manual" | 缺失 | CONDITIONAL GO |
| true | null | 缺失 | NO-GO（未選擇 E2E 模式）|
```

## 判斷步驟

```
1. 檢查 acceptance.testLayers.e2e.required
   - 如果 false → E2E 不影響決策

2. 如果 e2e.required == true：
   a. 檢查 acceptance.e2eMode
      - 如果 "manual" → 標記為 CONDITIONAL GO，提供人工驗收清單
      - 如果 "auto" → 繼續檢查 results.e2e.status
      - 如果 null → NO-GO，提示「E2E 模式未選擇，流程異常」

   b. 如果 e2eMode == "auto"：
      - results.e2e.status == "passed" → PASS
      - results.e2e.status == "failed" → FAIL
      - results.e2e.status 缺失 → FAIL（E2E 應執行但未執行）
```

## 輸出格式

### E2E 自動化執行通過
```
E2E Tests (chrome-mcp):
  • 模式：自動化（auto）
  • 狀態：passed ✅
  • 步驟：5/5 完成
  • 錄製：recordings/{task_id}/e2e.gif
```

### E2E 人工驗證模式
```
E2E Tests:
  • 模式：人工驗證（manual）⚠️
  • 狀態：等待人工驗收

📋 人工驗收清單：
1. [ ] {驗收項目 1}
2. [ ] {驗收項目 2}
```

### E2E 流程異常
```
E2E Tests:
  • 模式：未選擇 ❌
  • 狀態：未執行
  • 問題：E2E 測試為必要項目，但未選擇執行模式

⚠️ 流程異常：請回到 development 階段，選擇 E2E 測試方式
```
