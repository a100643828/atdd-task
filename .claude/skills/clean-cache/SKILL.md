---
name: cleaning-cache
description: Cleans Claude Code cache files and temporary data to free up disk space. Use when the user requests to clean cache, free up space, or optimize Claude Code storage.
version: 1.0.0
---

# Cleaning Cache

清理 Claude Code 暫存檔案和臨時資料，釋放磁碟空間。

## Instructions

執行以下步驟清理 `~/.claude/` 目錄下的暫存檔案：

### 1. 顯示當前空間使用情況

```bash
du -sh ~/.claude/* | sort -hr | head -10
```

### 2. 清理暫存目錄

執行以下清理操作（依序執行，每次確認成功）：

```bash
# 清理 debug 日誌
rm -rf ~/.claude/debug/*

# 清理文件歷史
rm -rf ~/.claude/file-history/*

# 清理 shell 快照
rm -rf ~/.claude/shell-snapshots/*

# 清理 todos 暫存
rm -rf ~/.claude/todos/*

# 清理 session 環境
rm -rf ~/.claude/session-env/*
```

### 3. 可選：清理對話歷史

詢問用戶是否清理對話歷史（**此操作不可逆**）：

```bash
# 清理對話歷史（謹慎！）
rm -f ~/.claude/history.jsonl
```

### 4. 確認清理結果

```bash
du -sh ~/.claude/* | sort -hr | head -10
```

報告釋放的空間大小。

## Safety Guidelines

1. **永不清理的目錄**：
   - `~/.claude/settings.json` - 用戶設定
   - `~/.claude/settings.local.json` - 本地設定
   - `~/.claude/agents/` - 自定義 agents
   - `~/.claude/commands/` - 自定義命令
   - `~/.claude/projects/` - 專案緩存（除非用戶明確要求）
   - `~/.claude/plugins/` - 插件資料（除非用戶明確要求）

2. **需要確認的操作**：
   - 清理 `history.jsonl` 前必須詢問用戶
   - 清理 `projects/` 或 `plugins/` 前必須詢問用戶

3. **錯誤處理**：
   - 如果目錄不存在，顯示警告但繼續執行
   - 如果權限不足，停止並報告錯誤

## Expected Results

- 釋放 15-25 MB 磁碟空間（取決於使用時長）
- 不影響 Claude Code 功能
- 暫存檔案會在使用中自動重建
- 對話歷史清理後將永久遺失

## Notes

- 此操作不會減少 System tools 的 token 佔用（那是 Claude Code 核心）
- 清理後需要重啟 Claude Code 才能看到完整效果
- 建議每月執行一次定期清理
