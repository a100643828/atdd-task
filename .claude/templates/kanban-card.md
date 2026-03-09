# Kanban 卡片格式

> 用於 tasks/{project}/kanban.md
> 格式須符合 markdown-kanban 插件規範

## 基本結構

```markdown
### {任務標題}

  - tags: [{Domain}, {type}]
  - priority: {high/medium/low}
  - workload: {Easy/Normal/Hard/Extreme}
  - defaultExpanded: true
  - steps:
    - [x] requirement
    - [x] specification
    - [ ] testing
    - [ ] development
    - [ ] review
    - [ ] gate
    ```md
    **變更背景**: {background}
    **影響範圍**: {scope}
    **變更內容**: {changes}
    ```
```

## 結案時的完整格式

```markdown
### {任務標題}

  - tags: [{Domain}, {type}]
  - priority: {priority}
  - workload: {workload}
  - defaultExpanded: true
  - steps:
    - [x] requirement
    - [x] specification
    - [x] testing
    - [x] development
    - [x] review
    - [x] gate
    ```md
    **變更背景**: {background}
    **影響範圍**: {scope}
    **變更內容**: {changes}
    **階段歷程**: requirement → specification → testing → development → review → gate → completed
    **Agents**: {agent1}({tools1}/{tokens1}k), {agent2}({tools2}/{tokens2}k), ...
    **總計**: {totalToolUses} tools / {totalTokens}k tokens / {totalDuration}
    **commit**: {commit_hash}
    ```
```

## 欄位說明

| 欄位 | 格式 | 範例 |
|------|------|------|
| tags | [Domain, type] | [ErpPeriod, feature] |
| priority | high/medium/low | high |
| workload | Easy/Normal/Hard/Extreme | Normal |
| Agents | name(tools/tokensK) | specist(15/28.5k) |
| 總計 | N tools / Nk tokens / Nm Ns | 54 tools / 105.6k tokens / 7m 02s |
