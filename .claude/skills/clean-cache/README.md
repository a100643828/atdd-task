# Cleaning Cache Skill

清理 Claude Code 暫存檔案和臨時資料的自定義 skill。

## 功能

自動清理以下目錄：
- `~/.claude/debug/` - Debug 日誌
- `~/.claude/file-history/` - 文件修改歷史
- `~/.claude/shell-snapshots/` - Shell 快照
- `~/.claude/todos/` - Todo 列表暫存
- `~/.claude/session-env/` - Session 環境

## 使用方式

### 方式 1: 透過 Claude Code (推薦)

直接向 Claude 下指令：
```
清理 Claude Code 暫存
```

Claude 會自動使用這個 skill 執行清理。

### 方式 2: 手動執行腳本

```bash
# 執行清理腳本
bash .claude/skills/clean-cache/scripts/clean.sh

# 或直接執行
./.claude/skills/clean-cache/scripts/clean.sh
```

### 方式 3: 建立別名（可選）

在 `~/.zshrc` 或 `~/.bashrc` 中加入：
```bash
alias claude-clean='bash ~/.claude/skills/clean-cache/scripts/clean.sh'
```

然後執行：
```bash
claude-clean
```

## 安全性

此 skill **不會**清理：
- `~/.claude/settings.json` - 用戶設定
- `~/.claude/agents/` - 自定義 agents
- `~/.claude/commands/` - 自定義命令
- `~/.claude/projects/` - 專案緩存
- `~/.claude/history.jsonl` - 對話歷史（除非明確要求）

## 預期效果

- 釋放 15-25 MB 磁碟空間
- 不影響 Claude Code 功能
- 暫存檔案會在使用中自動重建

## 建議

- 每月執行一次定期清理
- 清理後重啟 Claude Code 以確保完全生效
- 如需清理對話歷史，請單獨執行：`rm -f ~/.claude/history.jsonl`

## 版本

- v1.0.0 - 初始版本
