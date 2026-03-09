# /test 任務 Gate 檢查

當任務類型為 `test`（獨立 E2E 測試）時，Gate 檢查流程簡化。

## 識別 /test 任務

```
1. 檢查任務 JSON 的 type == "test"
2. 或檢查 testPath 欄位存在
3. 讀取 tests/{project}/{test_id}/ 目錄的結果
```

## 簡化的門檻

| Gate | 是否適用 | 說明 |
|------|---------|------|
| Domain Gate | ✅ | 確認 Domain 已記錄 |
| Test Gate | ✅（修改版）| 檢查 E2E 測試結果 |
| Review Gate | ❌ 跳過 | /test 不需要 code review |
| Spec Gate | ❌ 跳過 | /test 不產出規格 |
| Documentation Gate | ❌ 跳過 | /test 不產出文件 |
| Cross-Domain Gate | ⚠️ 可選 | 如果跨 domain 才檢查 |
| Acceptance Gate | ✅ | 彙總 E2E 結果 |

## /test 任務的 Test Gate

| Criterion | Threshold |
|-----------|-----------|
| E2E 完成率 | 100%（所有場景都已執行）|
| 截圖完整性 | 每個場景都有截圖 |
| 問題記錄 | 發現的問題都已記錄 |

## 決策矩陣

| 情況 | 決策 |
|------|------|
| 所有場景通過 | GO |
| 部分失敗，已開 Fix 票 | CONDITIONAL GO |
| 部分失敗，未開 Fix 票 | NO-GO |
| 有跳過但有理由 | CONDITIONAL GO |
| 有跳過無理由 | NO-GO |

## 讀取測試結果

```
1. 讀取 tests/{project}/{test_id}/test.yml
2. 讀取 results.summary（通過/失敗/跳過數）
3. 讀取 results.issues（問題清單）
4. 確認 screenshots/ 目錄有截圖
```

## /test 任務結案

- **不需要 git commit**（沒有代碼產出）
- 只需要將任務標記為完成
- 移動 JSON：`active/{id}.json` → `completed/{id}.json`
- 建議使用 `/close` 結案
