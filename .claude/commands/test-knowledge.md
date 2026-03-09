---
description: 記錄知識缺口，停止測試並退回 requirement 階段
---

# Test Knowledge: $ARGUMENTS

## 概述

當 E2E 測試執行中發現**知識缺口**（無法判斷是系統錯誤還是測試錯誤）時，代表**這個測試不該存在**——測試是在知識不完整的情況下被撰寫的。

**ATDD 原則**：測試即規格。如果執行測試時才發現「不知道誰對誰錯」，代表 requirement 階段的知識釐清不足。

**此命令會**：
1. 記錄知識缺口資訊
2. **停止測試**（不是暫停）
3. 標記測試為 `invalid`（測試本身有問題）
4. 引導用戶重新從 requirement 階段開始

> 💡 大部分情況應使用 `/test-feature`（缺少功能）或 `/test-fix`（系統 bug）。
> 知識的累積應該在 **Gate 階段統整**，而非測試執行中補課。

## 參數解析

`$ARGUMENTS` = `{domain}, {描述}` 或 `{描述}`

- 有逗號：第一段為 domain，第二段為描述
- 無逗號：使用 suite.yml 的 domain，整段為描述

如果沒有提供描述：
```
⚠️ 請提供知識缺口描述
用法：/test-knowledge {domain}, {描述}
      /test-knowledge {描述}
範例：/test-knowledge ErpPeriod, 狀態名稱「草稿」vs「待審核」定義不明
      /test-knowledge 無法判斷帳單狀態的正確行為
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

### Step 2: 解析參數

```
如果 $ARGUMENTS 包含逗號：
  domain = 逗號前的部分（trim）
  description = 逗號後的部分（trim）
否則：
  domain = suite.yml 的 domain 欄位
  description = $ARGUMENTS（trim）
```

### Step 3: 截圖保存現場

使用 Chrome MCP 截圖：

**新結構**：
```
runs/{timestamp}/recordings/{scenario}-knowledge-{kg_id}.png
```

**舊結構**：
```
screenshots/{scenario}-knowledge-{timestamp}.png
```

### Step 4: 生成知識缺口記錄

生成 KG-{序號} ID（基於 run.yml 現有 knowledgeGaps 數量 +1）。

### Step 5: 更新 run.yml

**新結構**：更新 `runs/{timestamp}/run.yml`：
```yaml
status: "invalid"
completedAt: "{ISO timestamp}"
invalidReason: "knowledge_gap"

knowledgeGaps:
  - id: "KG-001"
    scenario: "{scenario_id}"
    step: {step_number}
    domain: "{domain}"
    description: "{description}"
    screenshot: "recordings/{filename}"
    timestamp: "{ISO timestamp}"
```

**舊結構**：更新 `results.yml` 及 `test.yml`（同上邏輯）。

### Step 6: 更新 suite.yml 統計

```yaml
stats:
  lastRun: "{ISO timestamp}"
  lastStatus: "invalid"
```

### Step 7: 輸出結果

```markdown
┌──────────────────────────────────────────────────────────────┐
│ ⛔ 測試已停止 — 知識缺口                                      │
├──────────────────────────────────────────────────────────────┤
│ 🆔 缺口 ID：KG-001                                          │
│ 📍 發現位置：{場景名稱} - Step {step}                        │
│ 🏷️ Domain：{domain}                                         │
│ 📝 描述：{description}                                       │
│ 📷 截圖：recordings/{filename}                               │
│                                                              │
│ ⚠️ 此測試在知識不完整時被撰寫，需退回 requirement 階段。      │
│                                                              │
│ 測試統計：                                                   │
│   • 通過：{passed} 個場景                                    │
│   • 失敗：{failed} 個場景                                    │
│   • 未執行：{remaining} 個場景                               │
│   • 狀態：invalid (knowledge_gap)                            │
│                                                              │
│ 📝 下一步：                                                  │
│   1. 釐清知識：/knowledge {project}, {domain}                │
│   2. 重新定義測試：/test-edit {project}, {suite-id}          │
│   3. 重新執行：/test-run {project}, {suite-id}               │
└──────────────────────────────────────────────────────────────┘
```

## 與其他命令的區別

| 情境 | 命令 | 測試狀態 |
|------|------|----------|
| 系統有 bug | `/test-fix` | 繼續或停止 |
| 缺少功能 | `/test-feature` | 繼續 |
| 測試預期寫錯 | `/test-revise` | 暫停確認 |
| **測試不該存在** | `/test-knowledge` | **停止 (invalid)** |

## 範例

### 帶 domain 參數

```
/test-knowledge ErpPeriod, 狀態「草稿」vs「待審核」定義不明確
```

輸出：
```
┌──────────────────────────────────────────────────────────────┐
│ ⛔ 測試已停止 — 知識缺口                                      │
├──────────────────────────────────────────────────────────────┤
│ 🆔 缺口 ID：KG-001                                          │
│ 📍 發現位置：S2-建立新期間 - Step 5                          │
│ 🏷️ Domain：ErpPeriod                                        │
│ 📝 描述：狀態「草稿」vs「待審核」定義不明確                  │
│ 📷 截圖：recordings/S2-knowledge-KG-001.png                 │
│                                                              │
│ ⚠️ 此測試在知識不完整時被撰寫，需退回 requirement 階段。      │
│                                                              │
│ 測試統計：                                                   │
│   • 通過：1 個場景                                           │
│   • 失敗：0 個場景                                           │
│   • 未執行：3 個場景                                         │
│   • 狀態：invalid (knowledge_gap)                            │
│                                                              │
│ 📝 下一步：                                                  │
│   1. 釐清知識：/knowledge core_web, ErpPeriod                │
│   2. 重新定義測試：/test-edit core_web, E2E-A1               │
│   3. 重新執行：/test-run core_web, E2E-A1                    │
└──────────────────────────────────────────────────────────────┘
```

### 不帶 domain 參數

```
/test-knowledge 無法判斷帳單狀態的正確行為
```

輸出（使用 suite.yml 的 domain）：
```
┌──────────────────────────────────────────────────────────────┐
│ ⛔ 測試已停止 — 知識缺口                                      │
├──────────────────────────────────────────────────────────────┤
│ 🆔 缺口 ID：KG-001                                          │
│ 📍 發現位置：S6-檢查帳單狀態 - Step 3                        │
│ 🏷️ Domain：Billing                                          │
│ 📝 描述：無法判斷帳單狀態的正確行為                          │
│ 📷 截圖：recordings/S6-knowledge-KG-001.png                 │
│                                                              │
│ ⚠️ 此測試在知識不完整時被撰寫，需退回 requirement 階段。      │
│                                                              │
│ 測試統計：                                                   │
│   • 通過：5 個場景                                           │
│   • 失敗：0 個場景                                           │
│   • 未執行：2 個場景                                         │
│   • 狀態：invalid (knowledge_gap)                            │
│                                                              │
│ 📝 下一步：                                                  │
│   1. 釐清知識：/knowledge core_web, Billing                  │
│   2. 重新定義測試：/test-edit core_web, E2E-B1               │
│   3. 重新執行：/test-run core_web, E2E-B1                    │
└──────────────────────────────────────────────────────────────┘
```
