# Python Style Guide

本指南定義 Python 專案的代碼風格標準，供 `style-reviewer` agent 使用。
遵循 PEP 8 規範。

## 命名規範

### 類別

```python
# ✅ Good - PascalCase
class DataProcessor:
    pass

class YahooHTMLCrawler:
    pass

# ❌ Bad
class data_processor:  # snake_case
class dataProcessor:   # camelCase
```

### 函式與方法

```python
# ✅ Good - snake_case
def calculate_total():
    pass

def fetch_stock_data(symbol: str) -> dict:
    pass

# ❌ Bad
def calculateTotal():    # camelCase
def FetchStockData():    # PascalCase
```

### 變數

```python
# ✅ Good - snake_case
user_name = "John"
total_amount = 100
is_active = True

# ❌ Bad
userName = "John"       # camelCase
TotalAmount = 100       # PascalCase
```

### 常數

```python
# ✅ Good - SCREAMING_SNAKE_CASE
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT = 30
API_BASE_URL = "https://api.example.com"
REQUEST_DELAY = 0.5
```

### 私有成員

```python
# ✅ Good
class Crawler:
    def __init__(self):
        self._session = None      # 單底線：內部使用
        self.__secret = "key"     # 雙底線：name mangling

    def _prepare_request(self):   # 內部方法
        pass

# ❌ Bad - 不要用於不需要隱藏的方法
def __init__(self):
    self.___value = 1  # 三底線無意義
```

## 代碼結構

### 函式長度

```python
# ✅ Good - 函式保持簡短
def process_stock_data(data: dict) -> ProcessedData:
    validated = validate_data(data)
    transformed = transform_data(validated)
    return ProcessedData(transformed)

# ❌ Bad - 函式過長，應拆分
def do_everything(data):
    # ... 100+ 行的邏輯
    pass
```

### Early Return

```python
# ✅ Good - 使用 early return
def process(user):
    if not user.is_valid():
        return None

    if not user.is_active():
        return None

    return execute(user)

# ❌ Bad - 深層嵌套
def process(user):
    if user.is_valid():
        if user.is_active():
            return execute(user)
        else:
            return None
    else:
        return None
```

### 類別大小

```python
# ✅ Good - 單一職責
class StockDataCrawler:
    """只負責爬取股票資料"""

    def fetch(self, symbol: str) -> dict:
        pass

class StockDataParser:
    """只負責解析資料"""

    def parse(self, raw_data: str) -> dict:
        pass
```

## Python 慣用語法

### Type Hints

```python
# ✅ Good - 使用 type hints
def fetch_data(symbol: str, timeout: int = 30) -> dict:
    pass

def process_items(items: list[dict]) -> list[ProcessedItem]:
    pass

# ❌ Bad - 無 type hints（公開 API 應有）
def fetch_data(symbol, timeout=30):
    pass
```

### List Comprehension

```python
# ✅ Good - 簡單的 list comprehension
names = [user.name for user in users]
active_users = [u for u in users if u.is_active]

# ✅ Good - 複雜邏輯用一般迴圈
results = []
for user in users:
    if user.is_active:
        processed = complex_process(user)
        if processed.is_valid:
            results.append(processed)

# ❌ Bad - 過度複雜的 comprehension
results = [complex_process(u) for u in users if u.is_active and complex_process(u).is_valid]
```

### f-strings

```python
# ✅ Good
message = f"Hello, {user.name}!"
url = f"{base_url}/api/v1/stocks/{symbol}"

# ❌ Bad
message = "Hello, " + user.name + "!"
message = "Hello, {}!".format(user.name)
message = "Hello, %s!" % user.name
```

### Context Manager

```python
# ✅ Good - 使用 with
with open("file.txt", "r") as f:
    content = f.read()

async with aiohttp.ClientSession() as session:
    response = await session.get(url)

# ❌ Bad - 手動管理資源
f = open("file.txt", "r")
content = f.read()
f.close()
```

### Dataclasses

```python
# ✅ Good - 使用 dataclass
from dataclasses import dataclass

@dataclass
class StockData:
    symbol: str
    price: float
    volume: int
    timestamp: datetime

# ❌ Bad - 手動定義 __init__ 等
class StockData:
    def __init__(self, symbol, price, volume, timestamp):
        self.symbol = symbol
        self.price = price
        self.volume = volume
        self.timestamp = timestamp
```

### Enum

```python
# ✅ Good - 使用 Enum
from enum import Enum

class OrderStatus(Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

# ❌ Bad - 使用字串常數
ORDER_STATUS_PENDING = "pending"
ORDER_STATUS_APPROVED = "approved"
```

## Async 程式

### async/await

```python
# ✅ Good
async def fetch_all_stocks(symbols: list[str]) -> list[dict]:
    tasks = [fetch_stock(s) for s in symbols]
    return await asyncio.gather(*tasks)

# ❌ Bad - 同步呼叫 async 函式
def fetch_all_stocks(symbols):
    for s in symbols:
        asyncio.run(fetch_stock(s))  # 效率差
```

### httpx 使用

```python
# ✅ Good
async with httpx.AsyncClient() as client:
    response = await client.get(url, timeout=30)
    response.raise_for_status()
    return response.json()

# ❌ Bad - 無 timeout、無錯誤處理
response = httpx.get(url)
return response.json()
```

## 爬蟲特定（stock_commentary）

### 請求延遲

```python
# ✅ Good - 使用配置的延遲
REQUEST_DELAY = 0.5  # 常數定義

async def fetch(self, url):
    await asyncio.sleep(REQUEST_DELAY)
    return await self._client.get(url)
```

### 錯誤處理

```python
# ✅ Good - 完整的錯誤處理
async def fetch_with_retry(self, url: str, max_retries: int = 3) -> dict:
    for attempt in range(max_retries):
        try:
            response = await self._client.get(url)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429:  # Rate limited
                await asyncio.sleep(2 ** attempt)
            else:
                raise
    raise MaxRetriesExceeded(url)
```

### User-Agent 輪替

```python
# ✅ Good
USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ...",
]

def get_random_user_agent() -> str:
    return random.choice(USER_AGENTS)
```

## 檢查清單

style-reviewer 應檢查：

- [ ] 命名規範符合 PEP 8
- [ ] 公開函式有 type hints
- [ ] 使用 f-string 而非 format/concat
- [ ] 使用 context manager 管理資源
- [ ] List comprehension 不過度複雜
- [ ] 使用 dataclass 定義資料結構
- [ ] async 程式正確使用 await
- [ ] 爬蟲有適當的延遲和錯誤處理
- [ ] 無 magic number（用常數取代）
