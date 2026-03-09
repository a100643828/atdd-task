---
description: 跳過當前測試步驟或場景
---

# Test Skip: $ARGUMENTS

## 概述

跳過當前執行中或暫停的測試步驟/場景，繼續執行下一個。

## 參數解析

- 無參數：跳過當前步驟
- `scenario`：跳過整個當前場景
- `S{n}`：跳過指定場景

## 執行步驟

### Step 1: 找到當前測試

```
1. 掃描 tests/*/*/test.yml
2. 找到 execution.status == "running" 或 "paused" 的測試
3. 如果沒有，報錯
```

### Step 2: 記錄跳過資訊

更新 `results.yml`：

```yaml
scenarios:
  - id: "{scenario_id}"
    steps:
      - id: "{step_id}"
        status: "skipped"
        reason: "{$ARGUMENTS 或 '用戶請求跳過'}"
        timestamp: "{ISO timestamp}"
```

### Step 3: 更新執行狀態

**跳過步驟**（預設）：
```yaml
execution:
  currentStep: "{next_step}"
```

**跳過場景**（參數為 `scenario` 或 `S{n}`）：
```yaml
execution:
  currentScenario: "{next_scenario}"
  currentStep: 1

results:
  summary:
    skipped: {+1}
```

### Step 4: 輸出跳過訊息

**跳過步驟**：
```markdown
┌──────────────────────────────────────────────────────────────┐
│ ⏭️ 步驟已跳過                                                │
├──────────────────────────────────────────────────────────────┤
│ 📍 跳過：{場景名稱} - Step {step}                            │
│ 📝 原因：{reason}                                            │
│                                                              │
│ 繼續執行 Step {next_step}...                                 │
└──────────────────────────────────────────────────────────────┘
```

**跳過場景**：
```markdown
┌──────────────────────────────────────────────────────────────┐
│ ⏭️ 場景已跳過                                                │
├──────────────────────────────────────────────────────────────┤
│ 📍 跳過：{場景名稱} ({step_count} 個步驟)                    │
│ 📝 原因：{reason}                                            │
│                                                              │
│ 繼續執行場景 {next_scenario}...                              │
└──────────────────────────────────────────────────────────────┘
```

### Step 5: 繼續執行

如果測試狀態是 "running"，自動繼續下一步驟/場景。

如果測試狀態是 "paused"，提示用戶：
```
📝 輸入 /test-resume 繼續測試
```

## 範例

**跳過步驟**：
```
/test-skip 此步驟需要特殊環境
```

**跳過場景**：
```
/test-skip scenario
```

**跳過指定場景**：
```
/test-skip S3
```
