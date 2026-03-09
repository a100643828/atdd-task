# 任務流程圖

## Feature 流程

```
/feature 啟動
    │
    ▼
┌─────────────────┐
│ 1. REQUIREMENT  │ ← specist
│    需求分析     │
│    信心度評估   │
└────────┬────────┘
         │ 信心度 >= 95%
         ▼
┌─────────────────┐
│ 2. SPEC         │ ← specist
│    撰寫規格     │
│    用戶確認     │
└────────┬────────┘
         │ /continue
         ▼
┌─────────────────┐
│ 3. TESTING      │ ← tester
└────────┬────────┘
         │ /continue
         ▼
┌─────────────────┐
│ 4. DEVELOPMENT  │ ← coder
└────────┬────────┘
         │ 測試通過
         ▼
┌─────────────────┐
│ 5. REVIEW       │ ← reviewers
└────────┬────────┘
         │ /continue
         ▼
┌─────────────────┐
│ 6. GATE         │ ← gatekeeper
└────────┬────────┘
         │ GO
         ▼
┌─────────────────┐
│ 7. KNOWLEDGE?   │ ← curator（條件式）
│    有新知識？    │   Gatekeeper 識別到新知識時觸發
└────────┬────────┘
         │
         ▼
    ✅ COMPLETED
```

## Fix 流程（簡化）

```
/fix 啟動
    │
    ▼
┌─────────────────┐
│ 1. REQUIREMENT  │ ← specist（信心度 80%）
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. TESTING      │ ← tester
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. DEVELOPMENT  │ ← coder
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. REVIEW       │ ← risk-reviewer only
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. GATE         │ ← gatekeeper
└────────┬────────┘
         │ GO
         ▼
┌─────────────────┐
│ 6. KNOWLEDGE?   │ ← curator（條件式）
│    有新知識？    │   Gatekeeper 識別到新知識時觸發
└────────┬────────┘
         │
         ▼
    ✅ COMPLETED
```

## Test 流程（套件建立 + 執行）

### /test-create（建立套件）

```
/test 或 /test-create 啟動
    │
    ▼
┌─────────────────┐
│ 1. REQUIREMENT  │ ← specist
│    識別範圍     │
│    規劃場景     │
│    定義資料需求 │
└────────┬────────┘
         │ 信心度 >= 90%
         ▼
    ✅ 套件就緒
```

### /test-run（執行套件）

```
/test-run 啟動
    │
    ▼
┌─────────────────┐
│ 1. SETUP        │ ← command
│    生成 run ID  │
│    執行 seed.rb │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. TESTING      │ ← tester
│    執行 E2E     │
│    錄製 GIF     │
│    記錄結果     │
└────────┬────────┘
         │ 測試完成
         ▼
┌─────────────────┐
│ 3. CLEANUP      │ ← command
│    執行 cleanup │
│    更新 stats   │
└────────┬────────┘
         │
         ▼
    ✅ 執行記錄保存
```

### Tagged Data 策略

```
seed.rb 建立資料時
    │
    ├── 資料加上 test_run_id 標記
    │   （存在 metadata 欄位）
    │
    ▼
cleanup.rb 清理時
    │
    └── 只刪除有該標記的資料
        （不影響其他測試）
```

## 階段轉移

| 從 | 到 | 觸發 |
|----|-----|------|
| requirement | specification | 信心度 >= 95% |
| specification | testing | /continue |
| testing | development | /continue |
| development | review | 測試通過 |
| review | gate | /continue |
| gate | completed | /done, /close |

## 允許循環

```
testing ↔ development  # 測試失敗時
review → testing       # /fix-critical 等
```
