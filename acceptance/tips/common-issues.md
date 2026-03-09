# 常見問題與解法

## 環境前置檢查（Preflight）

**E2E 測試前必須確認環境已啟動**，否則會遇到連線失敗、頁面無法載入等問題。

### 開發環境網址

| 服務 | 網址 |
|------|------|
| 開發環境首頁 | `http://admin.dev.localhost:3000/` |
| Sidekiq Web UI | `http://admin.dev.localhost:3000/sidekiq/` |

### 測試帳號

| 用途 | 帳號 | 密碼 |
|------|------|------|
| 一般測試（管理員） | `$TEST_USER_EMAIL` | `$TEST_USER_PASSWORD` |

> **注意**：帳密定義於 `.env`，如需特定權限的操作，請使用對應權限的測試帳號。

### 必要服務清單

| 服務 | 用途 | 檢查方式 |
|------|------|----------|
| Rails Server | 網頁應用 | `curl http://admin.dev.localhost:3000/` |
| Sidekiq | 背景任務 | `ps aux | grep sidekiq` 或查看 Web UI |
| PostgreSQL | 資料庫 | `pg_isready` |
| Redis | 快取/Queue | `redis-cli ping` |

### 檢查 Rails Server

```bash
# 檢查是否啟動
curl -s -o /dev/null -w "%{http_code}" http://admin.dev.localhost:3000/

# 啟動 Rails Server（如果未啟動）
cd $CORE_WEB_PATH && rails s -d  # 背景執行
# 或
cd $CORE_WEB_PATH && rails s     # 前景執行（需另開 terminal）
```

### 檢查 Sidekiq

```bash
# 檢查是否有 Sidekiq 進程
ps aux | grep -v grep | grep sidekiq

# 檢查 Sidekiq Web UI
# 瀏覽器開啟：http://admin.dev.localhost:3000/sidekiq/
# 可查看：排隊任務、執行中任務、失敗任務、重試佇列

# 啟動 Sidekiq（如果未啟動）
cd $CORE_WEB_PATH && bundle exec sidekiq -d  # 背景執行
# 或
cd $CORE_WEB_PATH && bundle exec sidekiq     # 前景執行
```

### 檢查資料庫連線

```bash
# PostgreSQL
pg_isready -h localhost -p 5432

# 或透過 Rails 檢查
cd $CORE_WEB_PATH && rails runner "puts ActiveRecord::Base.connected?"
```

### 檢查 Redis

```bash
# Redis 連線測試
redis-cli ping
# 應該返回 PONG

# 檢查 Redis 是否啟動
ps aux | grep -v grep | grep redis
```

### 自動化 Preflight 腳本

建議在測試前執行完整檢查：

```bash
#!/bin/bash
# preflight.sh - E2E 測試前置檢查

echo "=== E2E Preflight Check ==="

# 1. 檢查 Rails Server
echo -n "Rails Server: "
if curl -s http://admin.dev.localhost:3000/ > /dev/null 2>&1; then
  echo "✅ Running (http://admin.dev.localhost:3000/)"
else
  echo "❌ Not running"
  echo "   啟動: cd $CORE_WEB_PATH && rails s"
  exit 1
fi

# 2. 檢查 Sidekiq
echo -n "Sidekiq: "
if ps aux | grep -v grep | grep sidekiq > /dev/null; then
  echo "✅ Running (http://admin.dev.localhost:3000/sidekiq/)"
else
  echo "❌ Not running"
  echo "   啟動: cd $CORE_WEB_PATH && bundle exec sidekiq"
  exit 1
fi

# 3. 檢查 PostgreSQL
echo -n "PostgreSQL: "
if pg_isready -h localhost > /dev/null 2>&1; then
  echo "✅ Running"
else
  echo "❌ Not running"
  echo "   啟動: brew services start postgresql"
  exit 1
fi

# 4. 檢查 Redis
echo -n "Redis: "
if redis-cli ping > /dev/null 2>&1; then
  echo "✅ Running"
else
  echo "❌ Not running"
  echo "   啟動: brew services start redis"
  exit 1
fi

echo "=== All checks passed! ==="
```

### Preflight 失敗的常見症狀

| 症狀 | 可能原因 | 解法 |
|------|----------|------|
| `Connection refused` | Rails Server 未啟動 | 啟動 Rails Server |
| 頁面載入超時 | 服務未啟動或端口錯誤 | 確認服務和端口 |
| 背景任務沒執行 | Sidekiq 未啟動 | 啟動 Sidekiq |
| `PG::ConnectionBad` | PostgreSQL 未啟動 | 啟動 PostgreSQL |
| `Redis::CannotConnectError` | Redis 未啟動 | 啟動 Redis |

---

## Tab 相關問題

### 問題：`Tab doesn't exist` 或 `Invalid tab ID`

**原因**：
- Tab 被關閉
- 使用了舊的 tabId
- 從未取得過 tab

**解法**：
```javascript
// 重新取得 tab context
tabs_context_mcp(createIfEmpty=true)
// 使用新的 tabId
```

**預防**：
- 測試開始時固定呼叫 `tabs_context_mcp`
- 不要重複使用其他對話的 tabId

---

### 問題：操作後頁面空白或卡住

**原因**：
- 觸發了 JavaScript alert/confirm/prompt
- 頁面崩潰
- 無限重導向

**解法**：
```javascript
// 檢查 console 錯誤
read_console_messages(tabId=xxx, onlyErrors=true)

// 重新導航（跳脫卡住狀態）
navigate(tabId=xxx, url="about:blank")
navigate(tabId=xxx, url="http://admin.dev.localhost:3000")
```

**預防**：
- 避免點擊會觸發 alert/confirm 的按鈕
- 在點擊刪除等危險操作前確認

---

### 問題：遇到無法自動化測試的功能

**常見無法測試的情況**：
- 瀏覽器原生對話框（`alert`、`confirm`、`prompt`）
- 第三方外掛或 iframe（跨域限制）
- 檔案下載/上傳的系統對話框
- 需要驗證碼或外部認證

**處理原則**：

> ⚠️ **不要浪費時間嘗試繞過**，發現無法測試時，建議重構該功能使其可測試。

**建議做法**：

1. **記錄問題**：在測試報告中說明無法測試的原因
2. **建議重構**：提出讓功能可測試的重構建議（如改用自定義 Modal 取代原生 confirm）
3. **標記人工驗證**：使用 `/e2e-manual` 標記該功能需人工驗證

```yaml
# 測試文件註明
e2e:
  mode: manual
  reason: "功能使用原生 confirm，建議重構為自定義 Modal"
```

---

## 元素找不到問題

### 問題：`read_page` 找不到元素

**可能原因 1**：元素在 iframe 內

```javascript
// 檢查是否有 iframe
javascript_tool(text="document.querySelectorAll('iframe').length")

// 如果有，嘗試讀取 iframe 內容
// 注意：跨域 iframe 無法存取
```

**可能原因 2**：元素被 CSS 隱藏

```javascript
// 檢查元素是否存在但隱藏
javascript_tool(text=`
  const el = document.querySelector('.target');
  if (!el) return 'not found';
  return {
    display: getComputedStyle(el).display,
    visibility: getComputedStyle(el).visibility,
    opacity: getComputedStyle(el).opacity
  };
`)
```

**可能原因 3**：元素是動態生成的

```javascript
// 等待元素出現
computer(action="wait", duration=2)
read_page(tabId=xxx)

// 或用 JavaScript 等待
javascript_tool(text=`
  await new Promise(r => {
    const check = () => document.querySelector('.target') ? r(true) : setTimeout(check, 100);
    check();
  });
`)
```

---

### 問題：`find` 沒有返回結果

**解法**：
1. 嘗試不同的描述方式
2. 使用更具體的描述
3. 改用 `read_page` + `ref_id`

```javascript
// 原本
find(query="按鈕")  // 太籠統

// 改成
find(query="藍色的送出按鈕")
find(query="表單底部的 Submit 按鈕")
```

---

## 點擊問題

### 問題：點擊沒有反應

**可能原因 1**：點擊位置錯誤

```javascript
// 使用 ref 而不是座標（更可靠）
computer(action="left_click", ref="ref_5")
```

**可能原因 2**：元素被覆蓋

```javascript
// 檢查是否有覆蓋層
javascript_tool(text=`
  const el = document.querySelector('.button');
  const rect = el.getBoundingClientRect();
  const top = document.elementFromPoint(rect.x + rect.width/2, rect.y + rect.height/2);
  return top === el ? 'visible' : 'covered by: ' + top.className;
`)

// 如果被覆蓋，可能需要關閉 modal 或捲動
```

**可能原因 3**：元素不在可視區域

```javascript
// 先滾動到元素
computer(action="scroll_to", ref="ref_5")
computer(action="wait", duration=0.5)
computer(action="left_click", ref="ref_5")
```

**可能原因 4**：按鈕被禁用

```javascript
// 檢查 disabled 狀態
javascript_tool(text="document.querySelector('button').disabled")
```

---

### 問題：點擊後沒有導航

**原因**：連結可能用 JavaScript 處理

```javascript
// 嘗試 JavaScript 點擊
javascript_tool(text="document.querySelector('a.link').click()")
```

---

## 表單問題

### 問題：`form_input` 輸入失敗

**可能原因 1**：ref 不正確

```javascript
// 重新取得 ref
read_page(tabId=xxx, filter="interactive")
// 確認輸入框的 ref
```

**可能原因 2**：輸入框是唯讀

```javascript
// 檢查 readonly
javascript_tool(text="document.querySelector('input').readOnly")
```

**可能原因 3**：輸入框有特殊處理

```javascript
// 用 type 代替 form_input
computer(action="left_click", ref="ref_input")
computer(action="key", text="ctrl+a")  // 全選
computer(action="type", text="new value")
```

---

### 問題：下拉選單選不到選項

**解法 1**：使用選項的 value

```javascript
form_input(ref="ref_select", value="option_value")
```

**解法 2**：使用選項的顯示文字

```javascript
form_input(ref="ref_select", value="顯示的文字")
```

**解法 3**：JavaScript 操作

```javascript
javascript_tool(text=`
  const select = document.querySelector('select[name="country"]');
  select.value = 'TW';
  select.dispatchEvent(new Event('change', { bubbles: true }));
`)
```

---

## 截圖問題

### 問題：截圖是空白的

**原因**：頁面還在載入

```javascript
// 等待後再截圖
computer(action="wait", duration=2)
computer(action="screenshot")
```

---

### 問題：截圖沒有包含特定元素

**原因**：元素不在可視區域

```javascript
// 先滾動到元素
computer(action="scroll_to", ref="ref_target")
computer(action="wait", duration=0.5)
computer(action="screenshot")
```

---

## 驗證問題

### 問題：驗證文字存在但失敗

**可能原因**：文字在非預期的地方

```javascript
// 使用精確的選擇器
javascript_tool(text=`
  const el = document.querySelector('.success-message');
  return el ? el.textContent : 'not found';
`)
```

---

### 問題：驗證數值不正確

**可能原因**：數字格式問題（逗號、空格等）

```javascript
// 清理格式後比較
javascript_tool(text=`
  const text = document.querySelector('.amount').textContent;
  return parseFloat(text.replace(/[^0-9.-]/g, ''));
`)
```

---

## 效能問題

### 問題：`read_page` 返回太慢或超出限制

**解法**：
```javascript
// 限制深度
read_page(tabId=xxx, depth=5)

// 只看互動元素
read_page(tabId=xxx, filter="interactive")

// 聚焦特定區域
read_page(tabId=xxx, ref_id="ref_table")
```

---

### 問題：測試執行太慢

**優化**：
1. 減少不必要的 `read_page` 呼叫
2. 使用 `find` 代替完整 `read_page`
3. 合理設置等待時間（不要過長）
4. 平行執行獨立的驗證

---

## 除錯技巧

### 查看 Console 錯誤

```javascript
read_console_messages(tabId=xxx, onlyErrors=true)
```

### 查看網路請求

```javascript
read_network_requests(tabId=xxx, urlPattern="/api/")
```

### 執行診斷腳本

```javascript
javascript_tool(text=`
  return {
    url: window.location.href,
    title: document.title,
    bodyClasses: document.body.className,
    visibleText: document.body.innerText.slice(0, 200),
    errors: window.__errors || []
  };
`)
```
