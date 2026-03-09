---
description: 修正場景預期值（系統正確，測試錯誤），暫停確認後繼續
---

# Test Revise: $ARGUMENTS

## 概述

當 E2E 測試步驟失敗，但確認是**測試預期有誤**（系統行為正確）時，修正場景 YAML 的預期值，記錄修訂歷史，並暫停等待用戶確認後再繼續。

**使用時機**：系統行為正確，但場景 YAML 中的預期結果、步驟描述或前置條件有誤。

## 參數解析

`$ARGUMENTS` = 修正原因（必填）

如果沒有提供描述：
```
⚠️ 請提供修正原因
用法：/test-revise {修正原因}
範例：/test-revise 狀態名稱已從「草稿」改為「待審核」
```

## 執行步驟

### Step 1: 找到當前測試

```
搜尋順序：
1. 新結構：tests/{project}/suites/*/runs/latest/run.yml
   - 找到 status == "running" 或 "paused" 的執行記錄
2. 舊結構：tests/{project}/{uuid}/test.yml（向下相容）
   - 找到 execution.status == "running" 或 "paused" 的測試
3. 如果沒有，報錯
```

### Step 2: 截圖保存現場

使用 Chrome MCP 截圖：

**新結構**：
```
runs/{timestamp}/recordings/{scenario}-revise-{rev_id}.png
```

**舊結構**：
```
screenshots/{scenario}-revise-{timestamp}.png
```

### Step 3: 讀取場景 YAML 並顯示

讀取當前場景的 YAML 檔案，顯示失敗步驟的內容：

```markdown
┌──────────────────────────────────────────────────────────────┐
│ 📝 場景修訂模式                                              │
├──────────────────────────────────────────────────────────────┤
│ 📍 場景：{scenario_name}                                     │
│ 📍 步驟 {step}: {step_description}                           │
│                                                              │
│ 當前預期值：                                                 │
│   expectedResult: "{current_expected}"                       │
│   verification: "{current_verification}"                     │
│                                                              │
│ 📷 截圖：recordings/{filename}                               │
└──────────────────────────────────────────────────────────────┘
```

### Step 4: 詢問用戶修改內容

使用 AskUserQuestion 詢問：

1. 要修改哪個步驟？（預設為當前失敗步驟）
2. 修改類型：
   - `expectedResult`（預期結果）
   - `verification`（驗證條件）
   - `action`（操作步驟）
   - `precondition`（前置條件）
3. 正確的值是什麼？

### Step 5: 生成修訂記錄

生成 REV-{序號} ID（基於場景 YAML 現有 revisions 數量 +1）。

建立 revision 記錄：
```yaml
revisions:
  - id: "REV-001"
    timestamp: "{ISO timestamp}"
    type: "expectation_change"   # expectation_change | step_change | precondition_change
    source: "test-revise"
    runId: "{current_run_timestamp}"
    before:
      step: {step_number}
      field: "{field_name}"
      value: "{old_value}"
    after:
      step: {step_number}
      field: "{field_name}"
      value: "{new_value}"
    reason: "{$ARGUMENTS}"
```

**type 對照**：
| 修改欄位 | type |
|----------|------|
| expectedResult, verification | `expectation_change` |
| action, description | `step_change` |
| precondition | `precondition_change` |

### Step 6: 更新場景 YAML

1. 修改對應步驟的值
2. 在場景 YAML 末尾附加 revision 記錄到 `revisions` 區段

```yaml
# 場景 YAML 新增/更新 revisions 區段
revisions:
  - id: "REV-001"
    timestamp: "2026-02-04T10:30:00+08:00"
    type: "expectation_change"
    source: "test-revise"
    runId: "20260204_103000"
    before:
      step: 5
      field: "expectedResult.status"
      value: "草稿"
    after:
      step: 5
      field: "expectedResult.status"
      value: "待審核"
    reason: "狀態名稱已從「草稿」改為「待審核」"
```

### Step 7: 更新 run.yml

**新結構**：更新 `runs/{timestamp}/run.yml` 新增 revisions 區段：
```yaml
revisions:
  - id: "REV-001"
    scenario: "{scenario_id}"
    step: {step_number}
    field: "{field_name}"
    before: "{old_value}"
    after: "{new_value}"
    reason: "{$ARGUMENTS}"
    timestamp: "{ISO timestamp}"
```

### Step 8: 輸出 diff 風格結果

```markdown
┌──────────────────────────────────────────────────────────────┐
│ ✏️ 場景已修訂                                                │
├──────────────────────────────────────────────────────────────┤
│ 📍 場景：{scenario_name}                                     │
│ 🆔 修訂 ID：REV-001                                          │
│                                                              │
│ 變更內容：                                                   │
│   Step {step} > {field}:                                     │
│   - "{old_value}"                                            │
│   + "{new_value}"                                            │
│                                                              │
│ 原因：{$ARGUMENTS}                                           │
│ 📷 截圖：recordings/{filename}                               │
│                                                              │
│ ⏸️ 測試已暫停，請確認修訂是否正確                             │
│ 📝 輸入 /test-resume 繼續測試                                │
│    輸入 /test-revise 再次修訂                                │
└──────────────────────────────────────────────────────────────┘
```

### Step 9: 暫停測試

更新測試狀態為 paused（同 `/test-pause` 機制）：

**新結構**：更新 `runs/{timestamp}/run.yml`：
```yaml
status: "paused"
pause:
  reason: "場景修訂確認中 (REV-001)"
  timestamp: "{ISO timestamp}"
  currentScenario: "{當前場景}"
  currentStep: "{修訂的步驟}"
  resumable: true
```

## Revision Type 對照表

| 修改類型 | type 值 | 說明 |
|----------|---------|------|
| 修改預期結果 | `expectation_change` | 步驟的 expectedResult 或 verification |
| 修改操作步驟 | `step_change` | 步驟的 action 或 description |
| 修改前置條件 | `precondition_change` | 場景的 preconditions |

## 範例

```
/test-revise 狀態名稱已從「草稿」改為「待審核」
```

輸出：
```
┌──────────────────────────────────────────────────────────────┐
│ ✏️ 場景已修訂                                                │
├──────────────────────────────────────────────────────────────┤
│ 📍 場景：S2-建立新期間                                       │
│ 🆔 修訂 ID：REV-001                                          │
│                                                              │
│ 變更內容：                                                   │
│   Step 5 > expectedResult.status:                            │
│   - "草稿"                                                   │
│   + "待審核"                                                 │
│                                                              │
│ 原因：狀態名稱已從「草稿」改為「待審核」                     │
│ 📷 截圖：recordings/S2-revise-REV-001.png                   │
│                                                              │
│ ⏸️ 測試已暫停，請確認修訂是否正確                             │
│ 📝 輸入 /test-resume 繼續測試                                │
│    輸入 /test-revise 再次修訂                                │
└──────────────────────────────────────────────────────────────┘
```
