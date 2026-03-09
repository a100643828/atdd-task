# Chrome MCP 使用技巧

## 概述

Chrome MCP 是透過 Claude Chrome 擴充功能執行瀏覽器操作的工具集。

## 工具清單與用途

### 1. tabs_context_mcp - 取得 Tab 資訊

**必須首先呼叫**，取得可用的 tab ID。

```
mcp__claude-in-chrome__tabs_context_mcp(createIfEmpty=true)
```

**回傳**：
- `tabId`：用於後續所有操作
- `groupId`：Tab 群組 ID

**Tips**：
- 每個新對話開始時呼叫一次
- 如果 tab 不存在，使用 `createIfEmpty=true`

---

### 2. navigate - 導航

```
mcp__claude-in-chrome__navigate(tabId=xxx, url="/admin/users")
```

**支援**：
- 完整 URL：`https://example.com/path`
- 相對路徑：`/admin/users`（基於當前域名）
- 歷史操作：`back`、`forward`

**Tips**：
- 導航後等待 1-2 秒讓頁面載入
- 使用相對路徑更簡潔

---

### 3. read_page - 讀取頁面結構

```
mcp__claude-in-chrome__read_page(tabId=xxx)
```

**回傳**：
- DOM 樹結構
- 每個元素的 `ref_id`（如 `ref_1`、`ref_2`）
- 元素類型、文字、屬性

**參數**：
- `depth`：樹深度（預設 15，過大會超出限制）
- `filter`：`"interactive"` 只顯示可互動元素
- `ref_id`：聚焦特定元素

**Tips**：
- 輸出過大時，縮小 `depth` 或使用 `ref_id` 聚焦
- 用 `filter="interactive"` 找按鈕、連結、輸入框
- `ref_id` 是後續操作的關鍵

---

### 4. find - 自然語言查找元素

```
mcp__claude-in-chrome__find(tabId=xxx, query="登入按鈕")
```

**適用**：
- 不知道確切選擇器時
- 用文字描述找元素
- 找特定內容的元素

**Tips**：
- 描述要具體：「包含『送出』的按鈕」比「按鈕」好
- 最多返回 20 個匹配
- 返回的 `ref_id` 可用於後續操作

---

### 5. form_input - 表單輸入

```
mcp__claude-in-chrome__form_input(tabId=xxx, ref="ref_5", value="test@example.com")
```

**支援類型**：
- 文字輸入：`value="text"`
- 核取方塊：`value=true/false`
- 下拉選單：`value="option_value"` 或 `value="選項文字"`

**Tips**：
- 必須使用 `ref_id`，不支援 CSS 選擇器
- 先用 `read_page` 或 `find` 取得 ref
- 下拉選單可以用值或顯示文字

---

### 6. computer - 滑鼠與鍵盤操作

```
mcp__claude-in-chrome__computer(tabId=xxx, action="xxx", ...)
```

#### 點擊操作

```javascript
// 使用座標
computer(action="left_click", coordinate=[100, 200])

// 使用 ref（推薦）
computer(action="left_click", ref="ref_5")

// 雙擊
computer(action="double_click", coordinate=[100, 200])

// 右鍵
computer(action="right_click", coordinate=[100, 200])
```

#### 鍵盤輸入

```javascript
// 打字
computer(action="type", text="Hello World")

// 按鍵
computer(action="key", text="Enter")
computer(action="key", text="Tab")
computer(action="key", text="Backspace")

// 組合鍵
computer(action="key", text="cmd+a")  // Mac 全選
computer(action="key", text="ctrl+a") // Windows 全選
```

#### 截圖

```javascript
// 全頁截圖
computer(action="screenshot")

// 區域截圖（zoom）
computer(action="zoom", region=[x0, y0, x1, y1])
```

#### 等待

```javascript
// 等待 2 秒
computer(action="wait", duration=2)
```

#### 滾動

```javascript
// 向下滾動
computer(action="scroll", coordinate=[500, 300], scroll_direction="down", scroll_amount=3)

// 滾動元素到可見
computer(action="scroll_to", ref="ref_10")
```

**Tips**：
- 點擊優先用 `ref`，比座標更穩定
- 截圖前先等待動作完成
- 複雜輸入用 `type`，簡單輸入用 `form_input`

---

### 7. javascript_tool - 執行 JavaScript

```
mcp__claude-in-chrome__javascript_tool(tabId=xxx, action="javascript_exec", text="...")
```

**用途**：
- 複雜的 DOM 操作
- 取得頁面變數
- 驗證特定條件
- 觸發事件

**範例**：

```javascript
// 取得元素文字
document.querySelector('.message').textContent

// 檢查元素是否存在
!!document.querySelector('#success-alert')

// 取得表格行數
document.querySelectorAll('table tbody tr').length

// 觸發事件
document.querySelector('#myButton').click()

// 等待元素出現
await new Promise(resolve => {
  const check = () => {
    if (document.querySelector('.loaded')) resolve(true);
    else setTimeout(check, 100);
  };
  check();
});
```

**Tips**：
- 不要用 `return`，直接寫表達式
- 可以用 `await` 做非同步操作
- 適合做複雜驗證

---

### 8. gif_creator - GIF 錄製

```javascript
// 開始錄製
gif_creator(action="start_recording", tabId=xxx)

// 停止錄製
gif_creator(action="stop_recording", tabId=xxx)

// 匯出 GIF
gif_creator(action="export", tabId=xxx, download=true, filename="test.gif")

// 清除錄製
gif_creator(action="clear", tabId=xxx)
```

**流程**：
1. `start_recording`
2. 執行測試步驟（每步後截圖）
3. `stop_recording`
4. `export`

**Tips**：
- 開始後立即截圖一次（捕捉初始狀態）
- 停止前截圖一次（捕捉最終狀態）
- 設定有意義的 filename

---

## 完整測試流程範例

```javascript
// 1. 取得 tab
tabs_context_mcp(createIfEmpty=true)
// 取得 tabId

// 2. 開始錄製
gif_creator(action="start_recording", tabId=xxx)

// 3. 導航
navigate(tabId=xxx, url="http://localhost:3000/login")
computer(action="wait", duration=1)
computer(action="screenshot")  // 初始截圖

// 4. 讀取頁面找輸入框
read_page(tabId=xxx, filter="interactive")
// 取得 email input 的 ref_1, password 的 ref_2

// 5. 填寫表單
form_input(tabId=xxx, ref="ref_1", value="test@example.com")
form_input(tabId=xxx, ref="ref_2", value="password123")
computer(action="screenshot")

// 6. 點擊登入
find(tabId=xxx, query="登入按鈕")
// 取得按鈕的 ref_3
computer(action="left_click", ref="ref_3")
computer(action="wait", duration=2)
computer(action="screenshot")

// 7. 驗證結果
javascript_tool(tabId=xxx, action="javascript_exec",
  text="document.querySelector('.welcome').textContent")
// 應該返回 "歡迎回來"

// 8. 停止錄製並匯出
gif_creator(action="stop_recording", tabId=xxx)
gif_creator(action="export", tabId=xxx, download=true, filename="login-test.gif")
```

---

## 常見錯誤處理

| 錯誤 | 原因 | 解法 |
|------|------|------|
| `tab doesn't exist` | tabId 無效 | 重新呼叫 `tabs_context_mcp` |
| `element not found` | ref 或選擇器無效 | 用 `read_page` 重新取得 |
| `timeout` | 頁面未載入完成 | 增加等待時間 |
| `output too large` | read_page 輸出過大 | 減小 depth 或用 ref_id 聚焦 |
