# Production Guard

保護 Production 環境免於意外修改。

## 使用時機

- 自動觸發：當任何操作可能影響 Production 時
- 手動觸發：需要確認操作安全性時

## 保護層級

| 層級 | 操作 | 處理 |
|------|------|------|
| 🔴 禁止 | DROP, TRUNCATE, DELETE_ALL | 絕對禁止 |
| 🟠 需確認 | UPDATE, DELETE, INSERT | 人類確認 |
| 🟡 警告 | 讀取敏感資料 | 記錄警告 |
| 🟢 允許 | SELECT | 允許記錄 |

## 安全機制

- **攔截**：偵測寫入操作並中斷
- **確認**：要求人類明確確認（YES/NO/DRY）
- **記錄**：所有 Production 存取記錄到 log

## 相關文件

- [SKILL.md](./SKILL.md) - 完整使用說明
