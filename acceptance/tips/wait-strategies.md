# 等待策略

## 概述

E2E 測試最常見的失敗原因是**時機問題**：元素還沒載入、動作還沒完成、資料還沒更新。

正確的等待策略可以讓測試更穩定。

## 等待類型

### 1. 固定等待（Simple Wait）

最簡單但效率最低的方式。

```javascript
computer(action="wait", duration=2)
```

**適用**：
- 不確定要等什麼時
- 簡單場景
- Debug 時

**缺點**：
- 浪費時間（等太久）
- 不穩定（等太短）

---

### 2. 元素出現等待（Element Wait）

等待特定元素出現。

```javascript
// 用 JavaScript 等待
javascript_tool(text=`
  await new Promise((resolve, reject) => {
    let attempts = 0;
    const maxAttempts = 50;  // 5 秒
    const check = () => {
      const el = document.querySelector('.success-message');
      if (el) resolve(true);
      else if (++attempts > maxAttempts) reject('timeout');
      else setTimeout(check, 100);
    };
    check();
  });
`)
```

**適用**：
- 等待 Modal 打開
- 等待載入完成
- 等待訊息出現

---

### 3. 元素消失等待

等待 Loading 指示器消失。

```javascript
javascript_tool(text=`
  await new Promise((resolve, reject) => {
    let attempts = 0;
    const check = () => {
      const loading = document.querySelector('.loading-spinner');
      if (!loading) resolve(true);
      else if (++attempts > 100) reject('timeout');
      else setTimeout(check, 100);
    };
    check();
  });
`)
```

**適用**：
- 等待 Loading 結束
- 等待 Modal 關閉
- 等待過渡動畫完成

---

### 4. 文字出現等待

等待特定文字出現。

```javascript
javascript_tool(text=`
  await new Promise((resolve, reject) => {
    let attempts = 0;
    const check = () => {
      const hasText = document.body.innerText.includes('操作成功');
      if (hasText) resolve(true);
      else if (++attempts > 50) reject('timeout');
      else setTimeout(check, 100);
    };
    check();
  });
`)
```

---

### 5. 網路請求等待

等待特定 API 回應。

```javascript
// 先記錄請求數
javascript_tool(text="window.__requestCount = 0")

// 攔截請求
javascript_tool(text=`
  const originalFetch = window.fetch;
  window.fetch = async (...args) => {
    const response = await originalFetch(...args);
    if (args[0].includes('/api/save')) window.__requestCount++;
    return response;
  };
`)

// 執行操作後等待
computer(action="left_click", ref="ref_save")

// 等待請求完成
javascript_tool(text=`
  await new Promise((resolve, reject) => {
    let attempts = 0;
    const check = () => {
      if (window.__requestCount > 0) resolve(true);
      else if (++attempts > 50) reject('timeout');
      else setTimeout(check, 100);
    };
    check();
  });
`)
```

---

### 6. 條件等待

等待特定條件成立。

```javascript
javascript_tool(text=`
  await new Promise((resolve, reject) => {
    let attempts = 0;
    const check = () => {
      const table = document.querySelector('table');
      const rows = table ? table.querySelectorAll('tbody tr').length : 0;
      if (rows >= 5) resolve(true);
      else if (++attempts > 50) reject('timeout');
      else setTimeout(check, 100);
    };
    check();
  });
`)
```

---

## 常見場景的等待時間建議

| 場景 | 建議等待 | 等待方式 |
|------|----------|----------|
| 頁面導航 | 1-2 秒 | 固定等待 + 元素出現 |
| 點擊按鈕 | 0.5-1 秒 | 固定等待 |
| 表單送出 | 2-3 秒 | 等待成功訊息 |
| Modal 打開 | 0.5-1 秒 | 等待 Modal 出現 |
| Modal 關閉 | 0.5-1 秒 | 等待 Modal 消失 |
| 下拉選單展開 | 0.3-0.5 秒 | 固定等待 |
| AJAX 載入 | 1-5 秒 | 等待 Loading 消失 |
| 動畫效果 | 0.3-0.5 秒 | 固定等待 |
| 檔案上傳 | 3-10 秒 | 等待進度完成 |
| 搜尋結果 | 1-2 秒 | 等待結果出現 |

---

## 等待輔助函數

### 通用等待函數

```javascript
javascript_tool(text=`
  window.waitFor = async (selector, timeout = 5000) => {
    const start = Date.now();
    while (Date.now() - start < timeout) {
      const el = document.querySelector(selector);
      if (el) return el;
      await new Promise(r => setTimeout(r, 100));
    }
    throw new Error('Timeout waiting for: ' + selector);
  };
`)

// 使用
javascript_tool(text="await waitFor('.success-message')")
```

### 等待文字函數

```javascript
javascript_tool(text=`
  window.waitForText = async (text, timeout = 5000) => {
    const start = Date.now();
    while (Date.now() - start < timeout) {
      if (document.body.innerText.includes(text)) return true;
      await new Promise(r => setTimeout(r, 100));
    }
    throw new Error('Timeout waiting for text: ' + text);
  };
`)

// 使用
javascript_tool(text="await waitForText('保存成功')")
```

### 等待消失函數

```javascript
javascript_tool(text=`
  window.waitForGone = async (selector, timeout = 5000) => {
    const start = Date.now();
    while (Date.now() - start < timeout) {
      if (!document.querySelector(selector)) return true;
      await new Promise(r => setTimeout(r, 100));
    }
    throw new Error('Timeout waiting for element to disappear: ' + selector);
  };
`)

// 使用
javascript_tool(text="await waitForGone('.loading')")
```

---

## 等待模式範例

### 頁面載入完成後操作

```javascript
// 1. 導航
navigate(tabId=xxx, url="/admin/users")

// 2. 等待頁面載入
computer(action="wait", duration=1)

// 3. 等待特定元素出現
javascript_tool(text="await waitFor('table.users-table')")

// 4. 執行操作
read_page(tabId=xxx)
```

### 表單送出後驗證

```javascript
// 1. 點擊送出
computer(action="left_click", ref="ref_submit")

// 2. 等待 Loading
computer(action="wait", duration=0.5)

// 3. 等待 Loading 消失
javascript_tool(text="await waitForGone('.loading-spinner')")

// 4. 等待成功訊息
javascript_tool(text="await waitFor('.alert-success')")

// 5. 驗證
javascript_tool(text="document.querySelector('.alert-success').textContent")
```

### Modal 操作

```javascript
// 1. 點擊打開 Modal
computer(action="left_click", ref="ref_open_modal")

// 2. 等待 Modal 出現
javascript_tool(text="await waitFor('.modal.show')")

// 3. 在 Modal 中操作
read_page(tabId=xxx, ref_id="ref_modal")
form_input(ref="ref_modal_input", value="test")

// 4. 關閉 Modal
computer(action="left_click", ref="ref_close_modal")

// 5. 等待 Modal 消失
javascript_tool(text="await waitForGone('.modal.show')")
```

---

## 避免的做法

### 1. 過長的固定等待

```javascript
// 不好 - 浪費時間
computer(action="wait", duration=10)

// 好 - 智慧等待
javascript_tool(text="await waitFor('.result')")
```

### 2. 沒有等待就操作

```javascript
// 不好 - 可能找不到元素
navigate(tabId=xxx, url="/page")
read_page(tabId=xxx)  // 頁面可能還沒載入完

// 好 - 加入等待
navigate(tabId=xxx, url="/page")
computer(action="wait", duration=1)
javascript_tool(text="await waitFor('.page-content')")
read_page(tabId=xxx)
```

### 3. 依賴固定時間

```javascript
// 不好 - 網路慢時可能失敗
computer(action="left_click", ref="ref_submit")
computer(action="wait", duration=2)
// 直接驗證

// 好 - 等待明確條件
computer(action="left_click", ref="ref_submit")
javascript_tool(text="await waitFor('.success-message')")
// 驗證
```

---

## 除錯等待問題

### 確認元素是否存在

```javascript
javascript_tool(text=`
  const el = document.querySelector('.target');
  return {
    exists: !!el,
    visible: el ? el.offsetParent !== null : false,
    text: el ? el.textContent.slice(0, 50) : null
  };
`)
```

### 確認等待條件

```javascript
javascript_tool(text=`
  return {
    hasLoading: !!document.querySelector('.loading'),
    hasSuccess: !!document.querySelector('.success'),
    bodyText: document.body.innerText.slice(0, 200)
  };
`)
```
