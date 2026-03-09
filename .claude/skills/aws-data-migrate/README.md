# AWS Data Migrate

從 Production 安全地遷移資料到 Local/Staging 環境。

## 使用時機

- 需要 Production 資料來重現 Bug
- 需要真實資料進行本地測試
- 需要特定案例的資料進行分析

## 快速開始

```
使用 aws-data-migrate skill 來：
1. 從 Production 匯出 Invoice 資料（最近 30 天）
2. 清理敏感資料（email, phone）
3. 匯入到 Local
```

## 安全機制

- **硬編碼禁止**：Local → Production 方向的遷移
- **自動偵測**：敏感欄位（email, phone, address, password）
- **強制清理**：遷移後清除遠端暫存檔案

## 相關文件

- [SKILL.md](./SKILL.md) - 完整使用說明
