# Kanban 操作

> ⚠️ 所有 Kanban 操作必須透過 `kanban-adapter.sh` 進行，不可直接編輯 kanban.md

## Kanban Adapter

位置：`.claude/scripts/kanban-adapter.sh`

### 新增卡片

**Jira 開票確認**（建立卡片前必須執行）：

使用 AskUserQuestion 詢問是否在 Jira 開票：

```
question: "是否在 Jira 開立任務票？"
header: "Jira"
options:
  - label: "否（僅本地追蹤）"
    description: "不建立 Jira Issue，使用 Markdown backend 在本地追蹤任務"
  - label: "是（開立 Jira 票）"
    description: "在 Jira Cloud 建立 Issue 並同步任務狀態"
multiSelect: false
```

- 選「否」→ 使用 Markdown backend（`KANBAN_BACKEND=markdown`），跳過 Jira 開票，任務 JSON 的 `jira.issueKey` 和 `jira.url` 維持 null
- 選「是」→ 使用 Jira backend（`KANBAN_BACKEND=jira`），執行下方 create 命令，並回寫 issue key 到任務 JSON

```bash
bash .claude/scripts/kanban-adapter.sh create \
  --project {project} \
  --title "{description}" \
  --column {column} \
  --tags "{domain}, {type}" \
  --priority {priority} \
  --workload {workload} \
  --background "{background}" \
  --scope "{scope}"
```

### 移動卡片

```bash
bash .claude/scripts/kanban-adapter.sh move \
  --project {project} \
  --title "{description}" \
  --from {current_column} \
  --to {target_column}
```

### 結案（移至 Completed + Metrics）

```bash
# 先取得 metrics
ruby .claude/scripts/session-stats.rb latest --format kanban > /tmp/kanban-metrics.txt

# 更新卡片
bash .claude/scripts/kanban-adapter.sh complete \
  --project {project} \
  --title "{description}" \
  --commit {commit_hash} \
  --phase-history "{phase1} → {phase2} → ..." \
  --task-id {task_id_prefix} \
  --type {Feature/Fix/Refactor} \
  --domain {domain} \
  --branch {branch} \
  --metrics-file /tmp/kanban-metrics.txt
```

### 更新描述

```bash
bash .claude/scripts/kanban-adapter.sh update \
  --project {project} \
  --title "{description}" \
  --description-file {path_to_description_file}
```

描述檔案格式支援：`## ` 標題、`- [ ] ` 任務清單、一般文字。Jira backend 會自動轉為 ADF 格式。

### 放棄（移至 Failed）

```bash
bash .claude/scripts/kanban-adapter.sh fail \
  --project {project} \
  --title "{description}"
```

## Backend 切換

預設使用 Markdown backend（操作 `tasks/{project}/kanban.md`）。可切換為 Jira Cloud backend。

### 設定 Jira Backend

1. 編輯 `.claude/config/jira.yml`，填入 Jira Cloud URL、email、API Token
2. 設定環境變數：

```bash
export KANBAN_BACKEND=jira
```

3. 所有 kanban-adapter.sh 命令會自動改用 Jira REST API

### Backend 差異

| 行為 | Markdown | Jira |
|------|----------|------|
| 資料儲存 | `kanban.md` 檔案 | Jira Cloud issue |
| create | 在 kanban.md 插入卡片 | POST /rest/api/3/issue |
| move | 搬移卡片到目標欄位 | Transition issue status |
| update | no-op（資訊在本地） | PUT /rest/api/3/issue 更新 description |
| complete | 搬移 + 寫入 metrics | Transition to DONE + comment |
| fail | 搬移到 Failed | Transition to DONE + comment |

### Status Mapping（多對一）

多個 ATDD 階段對應同一 Jira status，同 status 內的 move 會被自動跳過：

| ATDD Column | Jira Status |
|-------------|-------------|
| requirement | TO DO |
| specification, testing, development, review | IN PROGRESS |
| gate | REVIEW/QA |
| completed, failed | DONE |

## 欄位對照

| Kanban 欄位 | status 值 |
|------------|-----------|
| Requirement | `requirement` |
| Specification | `specification` |
| Testing | `testing` |
| Development | `development` |
| Review | `review` |
| Gate | `gate` |
| Completed | `completed` |
| Failed | `failed` |

## Metrics 格式說明

`session-stats.rb --format kanban` 輸出範例：

```
**Agents**: specist(14/2.1k), tester(8/1.4k), coder(31/2.5k), gatekeeper(38/10.3k)
**總計**: 114 tools / 18.2M tokens / 2h 30m
```

| 格式 | 說明 |
|------|------|
| `agent(tools/tokens)` | Agent 名稱（tool 呼叫次數/token 消耗） |
| `tools` | 總共呼叫的 tool 次數 |
| `tokens` | 總 token 消耗（k=千, M=百萬） |
| `duration` | 任務執行時間 |
