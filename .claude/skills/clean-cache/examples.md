# Cleaning Cache Examples

## Example 1: 基本清理

用戶請求：「幫我清理 Claude Code 的暫存」

```bash
# 1. 檢查當前使用情況
du -sh ~/.claude/* | sort -hr | head -10

# 2. 清理暫存
rm -rf ~/.claude/debug/*
rm -rf ~/.claude/file-history/*
rm -rf ~/.claude/shell-snapshots/*
rm -rf ~/.claude/todos/*
rm -rf ~/.claude/session-env/*

# 3. 確認結果
du -sh ~/.claude/* | sort -hr | head -10
```

輸出：
```
✓ debug 已清理
✓ file-history 已清理
✓ shell-snapshots 已清理
✓ todos 已清理
✓ session-env 已清理

已釋放約 19.5 MB 空間
```

## Example 2: 完整清理（含對話歷史）

用戶請求：「清理所有暫存，包括對話歷史」

```bash
# 暫存清理
rm -rf ~/.claude/{debug,file-history,shell-snapshots,todos,session-env}/*

# 對話歷史清理
rm -f ~/.claude/history.jsonl
```

輸出：
```
✓ 暫存已清理
✓ 對話歷史已清理

已釋放約 20 MB 空間
```

## Example 3: 保守清理（僅日誌）

用戶請求：「清理 debug 日誌就好」

```bash
rm -rf ~/.claude/debug/*
```

## Example 4: 一鍵清理腳本

建立清理腳本（可選）：

```bash
#!/bin/bash
# .claude/skills/clean-cache/scripts/clean.sh

echo "🧹 開始清理 Claude Code 暫存..."

# 清理暫存目錄
for dir in debug file-history shell-snapshots todos session-env; do
  if [ -d ~/.claude/$dir ]; then
    rm -rf ~/.claude/$dir/*
    echo "✓ $dir 已清理"
  fi
done

# 顯示結果
echo ""
echo "📊 當前空間使用："
du -sh ~/.claude/* | sort -hr | head -5

echo ""
echo "✅ 清理完成！"
```

使用：
```bash
bash .claude/skills/clean-cache/scripts/clean.sh
```
