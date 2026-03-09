#!/bin/bash
# Claude Code Cache Cleaner
# 清理 ~/.claude/ 目錄下的暫存檔案

set -e

echo "🧹 開始清理 Claude Code 暫存..."
echo ""

# 顯示清理前的空間使用
echo "📊 清理前空間使用："
du -sh ~/.claude/* 2>/dev/null | sort -hr | head -10
echo ""

# 清理暫存目錄
CLEANED=0

for dir in debug file-history shell-snapshots todos session-env; do
  if [ -d ~/.claude/$dir ]; then
    SIZE_BEFORE=$(du -sk ~/.claude/$dir 2>/dev/null | cut -f1)
    rm -rf ~/.claude/$dir/*
    SIZE_AFTER=$(du -sk ~/.claude/$dir 2>/dev/null | cut -f1 || echo 0)
    FREED=$((SIZE_BEFORE - SIZE_AFTER))
    CLEANED=$((CLEANED + FREED))
    echo "✓ $dir 已清理 (釋放 $((FREED / 1024)) MB)"
  else
    echo "⚠ $dir 目錄不存在，跳過"
  fi
done

echo ""
echo "💾 總共釋放: $((CLEANED / 1024)) MB"
echo ""

# 顯示清理後的空間使用
echo "📊 清理後空間使用："
du -sh ~/.claude/* 2>/dev/null | sort -hr | head -10

echo ""
echo "✅ 清理完成！"
echo ""
echo "💡 提示："
echo "  - 清理對話歷史: rm -f ~/.claude/history.jsonl"
echo "  - 查看空間使用: du -sh ~/.claude/*"
