# ATDD Status Command

查看當前專案的 ATDD 任務狀態和統計資訊。

## 執行步驟

1. 讀取任務統計資訊
2. 顯示當前活躍任務
3. 顯示最近完成的任務

## 執行命令

```bash
# 讀取 Kanban 看板
cat tasks.md

# 列出活躍任務
ls -lt tasks/active/

# 顯示最新的任務
find tasks -name "*.json" -type f -exec ls -t {} + | head -5 | xargs cat
```

## 輸出格式

整理並顯示：
- 📊 總任務數
- ✅ 已完成任務數
- ❌ 失敗任務數
- 🔄 進行中任務數
- ⏱️ 平均耗時

然後列出當前活躍的任務。
