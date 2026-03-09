# 選擇器最佳實踐

## 選擇器優先順序

按穩定性和可維護性排序：

### 1. ref_id（最推薦）

從 `read_page` 取得的動態 ID，最可靠。

```javascript
// 取得 ref
read_page(tabId=xxx)
// 輸出包含 ref_1, ref_2, ref_3...

// 使用 ref
form_input(ref="ref_1", value="test")
computer(action="left_click", ref="ref_2")
```

**優點**：
- 由 Chrome MCP 生成，保證唯一
- 不依賴頁面實作細節

**缺點**：
- 每次讀取頁面會重新生成
- 需要先呼叫 `read_page`

---

### 2. data-testid 屬性

專為測試設計的屬性，開發時加入。

```html
<button data-testid="submit-btn">送出</button>
```

```javascript
// JavaScript 驗證
document.querySelector('[data-testid="submit-btn"]')
```

**優點**：
- 與視覺樣式無關
- 不受重構影響

**缺點**：
- 需要開發時加入
- 舊專案可能沒有

---

### 3. 唯一 ID

```html
<div id="user-profile">...</div>
```

```javascript
document.querySelector('#user-profile')
```

**優點**：
- 簡單直接
- 效能最好

**缺點**：
- 並非所有元素都有 ID
- ID 可能不夠語意化

---

### 4. name 屬性

表單元素常用。

```html
<input name="email" type="email">
```

```javascript
document.querySelector('[name="email"]')
// 或
document.querySelector('input[name="email"]')
```

**優點**：
- 表單元素通常有 name
- 語意清楚

---

### 5. 組合選擇器

結合多個條件提高精確度。

```javascript
// 登入表單中的 email 輸入框
document.querySelector('form.login input[type="email"]')

// 特定區塊內的按鈕
document.querySelector('.sidebar button.primary')

// 特定 class 組合
document.querySelector('.modal.active .submit-btn')
```

**Tips**：
- 從外到內縮小範圍
- 避免過長的選擇器鏈

---

### 6. 文字內容（使用 find）

無法用選擇器時的最後手段。

```javascript
find(query="包含『送出』的按鈕")
find(query="商品名稱為 'iPhone' 的列表項")
```

**優點**：
- 自然語言描述
- 適合動態內容

**缺點**：
- 可能匹配多個
- 文字變更會失敗

---

## 不推薦的選擇器

### 1. 純 class 選擇器

```javascript
// 不推薦 - class 容易變更
document.querySelector('.btn')
document.querySelector('.primary')
```

### 2. 純標籤選擇器

```javascript
// 不推薦 - 太泛用
document.querySelector('button')
document.querySelector('input')
```

### 3. 位置相關選擇器

```javascript
// 不推薦 - 順序變更會失敗
document.querySelector('table tr:nth-child(3)')
document.querySelector('.list li:first-child')
```

### 4. 複雜巢狀選擇器

```javascript
// 不推薦 - 結構變更會失敗
document.querySelector('div > div > div > span.text')
```

---

## 常見場景選擇器

### 表單

```javascript
// Email 輸入框
'input[type="email"]'
'input[name="email"]'
'#email'

// 密碼輸入框
'input[type="password"]'
'input[name="password"]'

// 送出按鈕
'button[type="submit"]'
'input[type="submit"]'
'form button:last-child'

// 下拉選單
'select[name="country"]'
'select#country'
```

### 表格

```javascript
// 表頭
'table thead th'
'th:contains("名稱")'  // jQuery 風格，需 JS 處理

// 特定欄位
'table td:nth-child(2)'  // 第二欄

// 特定行的操作按鈕
'tr[data-id="123"] .edit-btn'
```

### 導航

```javascript
// 連結
'a[href="/admin/users"]'
'nav a:contains("使用者")'

// 選單項目
'.menu-item.active'
'.sidebar a[href*="users"]'
```

### Modal / Dialog

```javascript
// Modal 容器
'.modal.show'
'.modal[aria-hidden="false"]'
'[role="dialog"]'

// Modal 內的按鈕
'.modal.show .confirm-btn'
'.modal.show button[type="submit"]'
```

### 訊息提示

```javascript
// 成功訊息
'.alert-success'
'.toast.success'
'.notification.success'

// 錯誤訊息
'.alert-danger'
'.alert-error'
'.error-message'
```

---

## JavaScript 輔助函數

在 `javascript_tool` 中使用：

### 找包含特定文字的元素

```javascript
// 找包含 "送出" 的按鈕
Array.from(document.querySelectorAll('button'))
  .find(btn => btn.textContent.includes('送出'))
```

### 等待元素出現

```javascript
// 等待元素出現（最多 5 秒）
await new Promise((resolve, reject) => {
  let attempts = 0;
  const check = () => {
    const el = document.querySelector('.success-message');
    if (el) resolve(el);
    else if (++attempts > 50) reject('timeout');
    else setTimeout(check, 100);
  };
  check();
});
```

### 驗證元素可見

```javascript
const el = document.querySelector('.message');
const isVisible = el && el.offsetParent !== null &&
  getComputedStyle(el).visibility !== 'hidden';
```

### 取得表格資料

```javascript
Array.from(document.querySelectorAll('table tbody tr')).map(row => ({
  id: row.cells[0].textContent,
  name: row.cells[1].textContent,
  status: row.cells[2].textContent
}));
```

---

## 選擇器除錯

### 在瀏覽器 DevTools 測試

```javascript
// 測試選擇器是否匹配
document.querySelector('your-selector')
document.querySelectorAll('your-selector').length

// 高亮匹配的元素
$$('your-selector').forEach(el => el.style.outline = '2px solid red')
```

### 常見問題

| 問題 | 可能原因 | 解法 |
|------|----------|------|
| 找不到元素 | 元素在 iframe 內 | 先切換到 iframe |
| 找不到元素 | 元素動態生成 | 等待後再找 |
| 找到多個 | 選擇器太泛 | 加更多條件 |
| 間歇性失敗 | 動畫或載入中 | 增加等待時間 |
