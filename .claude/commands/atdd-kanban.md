# ATDD Kanban Command

顯示 Markdown Kanban 看板，可用 VSCode Markdown Kanban 插件視覺化。

## 執行命令

```bash
# 直接顯示 Kanban 看板
cat tasks.md
```

## VSCode 整合

提醒使用者：

1. **安裝 Markdown Kanban 插件**
   - VSCode 擴展市場搜尋 "Markdown Kanban"
   - 安裝 `coddx.coddx-alpha` 或類似插件

2. **開啟看板**
   - 在 VSCode 中開啟 `tasks.md`
   - 插件會自動偵測並顯示看板視圖

3. **看板功能**
   - 拖放任務移動狀態
   - 點擊任務查看詳情
   - 新增、編輯、刪除任務

## 看板結構

看板包含以下欄位：
- **Backlog**: 待處理任務
- **In Progress**: 進行中
- **Testing**: 測試階段
- **Review**: 審查階段
- **Completed**: 已完成
- **Failed**: 失敗任務

每個任務格式：
```markdown
- [ ] ✨ 建立使用者註冊功能 (12345678) _2025-12-05_
```

---

現在顯示看板內容。
