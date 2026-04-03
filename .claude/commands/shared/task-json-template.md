# 任務 JSON 模板

## 標準任務 JSON

```json
{
  "id": "{uuid}",
  "type": "{feature|fix|refactor|test}",
  "description": "{標題}",
  "status": "requirement",
  "projectId": "{project}",
  "projectName": "{project}",
  "domain": "",
  "git": {
    "branch": "{selected_branch}"
  },
  "agents": [],
  "workflow": {
    "mode": "guided",
    "currentAgent": "specist",
    "confidence": 0,
    "pendingAction": null
  },
  "acceptance": {
    "profile": null,
    "testLayers": {},
    "fixture": null,
    "results": {},
    "verificationGuide": null
  },
  "history": [
    { "phase": "requirement", "timestamp": "{ISO timestamp}" }
  ],
  "jira": {
    "issueKey": null,
    "url": null
  },
  "causation": {
    "causedBy": null,
    "rootCauseType": null,
    "discoveredIn": null,
    "discoveredAt": null,
    "timeSinceIntroduced": null
  },
  "context": {
    "background": "",
    "relatedDomains": [],
    "deletedFiles": [],
    "modifiedFiles": [],
    "changes": [],
    "commitHash": ""
  },
  "metrics": null,
  "createdAt": "{ISO timestamp}",
  "updatedAt": "{ISO timestamp}"
}
```

## Causation 欄位說明（Fix 任務專用）

`causation` 用於追蹤 bug 的因果關係，在 specist 調查階段填寫：

```json
"causation": {
  "causedBy": {                    // 造成此 bug 的原始任務（調查後填寫）
    "taskId": "a8a9f6d2-...",      //   原始任務 ID
    "commitHash": "abc123",        //   造成問題的 commit
    "description": "月結分帳功能"   //   原始任務描述
  },
  "rootCauseType": "feature-defect",  // feature-defect | fix-regression | legacy | unknown | environment | dependency
  "discoveredIn": "production",       // production | staging | e2e | review | development
  "discoveredAt": "2026-04-03T10:00:00Z",  // 問題被發現的時間
  "timeSinceIntroduced": "32d"             // 自動計算：discoveredAt - causedBy.completedAt
}
```

- `causedBy`: 調查階段才填寫，非建立時。Specist 可用 `git blame` → commit → 反查 task JSON 的 `context.commitHash` 來追溯
- `rootCauseType`: 分類 bug 根因，用於統計分析
- `discoveredIn`: 在哪個環節發現，用於計算 Escape Rate
- Feature/Refactor/Test 任務的 `causation` 保持 null

## Completed 任務 JSON（額外欄位）

```json
{
  "status": "completed",
  "metrics": {
    "totalTools": 114,
    "totalTokens": "18.2M",
    "duration": "2h 30m",
    "totalToolBreakdown": {
      "Read": 35,
      "Edit": 28,
      "Bash": 22,
      "Grep": 15,
      "Write": 8,
      "Glob": 6
    },
    "agents": {
      "specist": { "tools": 14, "tokens": "2.1k" },
      "tester": { "tools": 8, "tokens": "1.4k" },
      "coder": { "tools": 31, "tokens": "2.5k" },
      "gatekeeper": { "tools": 38, "tokens": "10.3k" }
    }
  },
  "completedAt": "{ISO timestamp}"
}
```

## Epic 子任務 JSON（額外欄位）

```json
{
  "epic": {
    "id": "{epic-id}",
    "taskId": "{task-id}",
    "phase": "{phase name}",
    "requirementPath": "requirements/{project}/{epic-id}-{short_name}.md",
    "baReportPath": "requirements/{project}/{epic-id}-{short_name}-ba.md"
  }
}
```

**重要**：`requirementPath` 和 `baReportPath` 從 `epic.yml` 的 `requirement` 區塊取得。這些路徑確保子任務在新對話中仍能定位 Epic 層級的需求文件，維持業務規則的一致性。

## 儲存位置

```
tasks/{project}/active/{uuid}.json   # 進行中
tasks/{project}/completed/{uuid}.json # 已完成
tasks/{project}/failed/{uuid}.json   # 失敗
```

## 產生 UUID

```bash
uuidgen | tr '[:upper:]' '[:lower:]'
```
