---
description: 繼續暫停的 E2E 測試
---

# Test Resume: $ARGUMENTS

## 概述

繼續暫停的 E2E 測試，從上次暫停的位置繼續執行。

## 執行步驟

### Step 1: 找到暫停的測試

```
搜尋順序：
1. 新結構：tests/{project}/suites/*/runs/latest/run.yml
   - 找到 status == "paused" 的執行記錄
2. 舊結構：tests/{project}/{uuid}/test.yml（向下相容）
   - 找到 execution.status == "paused" 的測試
3. 如果沒有暫停的測試，報錯
```

如果沒有暫停的測試：
```
⚠️ 沒有暫停的測試可繼續
```

### Step 2: 讀取暫停資訊

**新結構**：從 `runs/{timestamp}/run.yml` 讀取：
- `pause.currentScenario`
- `pause.currentStep`
- `pause.reason`

**舊結構**：從 `test.yml` 讀取：
- `execution.currentScenario`
- `execution.currentStep`
- `execution.pause.reason`

### Step 3: 更新測試狀態

**新結構**：更新 `runs/{timestamp}/run.yml`：
```yaml
status: "running"
pause:
  resumedAt: "{ISO timestamp}"
```

**舊結構**：更新 `test.yml`：
```yaml
execution:
  status: "running"
  pause:
    reason: null
    timestamp: null
    resumable: true
```

### Step 4: 輸出恢復訊息

```markdown
┌──────────────────────────────────────────────────────────────┐
│ ▶️ 測試已恢復                                                │
├──────────────────────────────────────────────────────────────┤
│ 📍 恢復位置：{場景名稱} - Step {step}                        │
│ ⏰ 暫停時長：{duration}                                      │
│                                                              │
│ 繼續執行測試...                                              │
└──────────────────────────────────────────────────────────────┘
```

### Step 5: 呼叫 tester Agent 繼續執行

使用 Task tool 呼叫 tester，傳遞恢復資訊：

**新結構**：
```
Task(
  subagent_type: "tester",
  prompt: "
    任務類型：test-run (測試套件執行)
    Suite ID：{suite_id}
    Run 目錄：tests/{project}/suites/{suite_id}/runs/{timestamp}/
    操作模式：resume
    Test Run ID：{test_run_id}

    從暫停位置繼續執行 E2E 測試：
    - 當前場景：{currentScenario}
    - 當前步驟：{currentStep}

    請繼續執行剩餘的測試步驟。
  "
)
```

**舊結構**：
```
Task(
  subagent_type: "tester",
  prompt: "
    任務類型：test (獨立 E2E 測試)
    測試 ID：{test_id}
    測試目錄：tests/{project}/{test_id}/
    操作模式：resume

    從暫停位置繼續執行 E2E 測試：
    - 當前場景：{currentScenario}
    - 當前步驟：{currentStep}

    請繼續執行剩餘的測試步驟。
  "
)
```

## 範例

```
/test-resume
```

輸出：
```
┌──────────────────────────────────────────────────────────────┐
│ ▶️ 測試已恢復                                                │
├──────────────────────────────────────────────────────────────┤
│ 📍 恢復位置：S2-建立新期間 - Step 3                          │
│ ⏰ 暫停時長：5 分鐘                                          │
│                                                              │
│ 繼續執行測試...                                              │
└──────────────────────────────────────────────────────────────┘
```
