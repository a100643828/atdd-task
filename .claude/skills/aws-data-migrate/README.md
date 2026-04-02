# AWS Data Migrate

從 Production 安全地遷移資料到 Local/Staging 環境。

## 使用時機

- Staging 需要同步最新 Production 資料（全庫同步）
- 需要 Production 資料來重現 Bug（選擇性遷移）
- 需要真實資料進行本地測試
- 需要特定案例的資料進行分析

## 兩種遷移模式

| 模式 | 適用場景 | 方式 |
|------|---------|------|
| **全庫同步** (Path A) | Staging 環境同步 | pg_dump → drop → create → restore |
| **選擇性遷移** (Path B) | 除錯 / 分析用 | pg_dump 單表 or Rails Runner + CSV |

## 快速開始

```
# 全庫同步（最常見）
/aws-data-migrate e_trading production to staging

# 選擇性遷移
/aws-data-migrate invoices from core_web production to local (最近 30 天)
```

## 安全機制

- **硬編碼禁止**：Local/Staging → Production 方向的遷移
- **磁碟空間檢查**：dump 前自動檢查可用空間
- **敏感資料處理**：可選擇 mask 或 keep（由用戶決定）
- **覆蓋確認**：全庫同步會清掉目標 DB，執行前必須確認

## 相關文件

- [SKILL.md](./SKILL.md) - 完整使用說明
