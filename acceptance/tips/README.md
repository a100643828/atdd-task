# E2E Tips

Chrome MCP E2E 測試的經驗知識庫。

## 目錄結構

```
acceptance/tips/
├── README.md                    # 本文件
├── chrome-mcp-tips.md           # Chrome MCP 使用技巧
├── selectors.md                 # 選擇器最佳實踐
├── common-issues.md             # 常見問題與解法
└── wait-strategies.md           # 等待策略
```

## 使用方式

在執行 E2E 測試前或遇到問題時，查閱相關文檔：

| 情境 | 參考文檔 |
|------|----------|
| **測試前環境檢查** | `common-issues.md` → 環境前置檢查 |
| 不確定如何使用 Chrome MCP 工具 | `chrome-mcp-tips.md` |
| 選擇器找不到元素 | `selectors.md` |
| 測試不穩定或失敗 | `common-issues.md` |
| 頁面載入問題或元素未出現 | `wait-strategies.md` |
| **遇到無法自動化測試的功能** | `common-issues.md` → 建議重構 |

## Preflight 快速檢查

**E2E 測試前必須確保以下服務已啟動**：

| 服務 | 網址 |
|------|------|
| 開發環境 | http://admin.dev.localhost:3000/ |
| Sidekiq Web UI | http://admin.dev.localhost:3000/sidekiq/ |

**測試帳號**：定義於 `.env`（`TEST_USER_EMAIL` / `TEST_USER_PASSWORD`），如需特定權限請用對應帳號

```bash
# 1. Rails Server
curl -s http://admin.dev.localhost:3000/ > /dev/null && echo "✅ Rails" || echo "❌ Rails"

# 2. Sidekiq
ps aux | grep -v grep | grep sidekiq > /dev/null && echo "✅ Sidekiq" || echo "❌ Sidekiq"

# 3. PostgreSQL
pg_isready > /dev/null 2>&1 && echo "✅ PostgreSQL" || echo "❌ PostgreSQL"

# 4. Redis
redis-cli ping > /dev/null 2>&1 && echo "✅ Redis" || echo "❌ Redis"
```

詳細的 Preflight 檢查和啟動指令請參考 `common-issues.md`。

## 快速參考

### Chrome MCP 工具對照

| 需求 | 工具 | 範例 |
|------|------|------|
| 導航到 URL | `navigate` | `navigate(url="/admin")` |
| 點擊元素 | `computer(left_click)` | 需要座標或 ref |
| 輸入表單 | `form_input` | `form_input(ref="ref_1", value="test")` |
| 截圖 | `computer(screenshot)` | 全頁截圖 |
| 找元素 | `find` | 自然語言查詢 |
| 讀頁面 | `read_page` | 取得 DOM 結構和 ref |
| 執行 JS | `javascript_tool` | 複雜操作或驗證 |

### 選擇器優先順序

```
1. ref_id（從 read_page 取得）- 最可靠
2. 唯一 ID：#unique-id
3. data 屬性：[data-testid="xxx"]
4. name 屬性：[name="email"]
5. 組合選擇器：form.login input[type="email"]
6. 文字內容：使用 find 工具
```

### 等待策略

```
1. 導航後：等 1-2 秒讓頁面載入
2. 點擊後：等 0.5-1 秒讓動作完成
3. 表單送出後：等 2-3 秒讓伺服器回應
4. 動畫後：等動畫時間 + 緩衝
```
