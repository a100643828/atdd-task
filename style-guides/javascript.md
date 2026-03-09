# JavaScript/TypeScript Style Guide

本指南定義 JavaScript/TypeScript 專案的代碼風格標準，供 `style-reviewer` agent 使用。

## 命名規範

### 類別與介面

```typescript
// ✅ Good - PascalCase
class UserService {
}

interface UserProfile {
}

type OrderStatus = 'pending' | 'approved';

// ❌ Bad
class userService {}      // camelCase
interface user_profile {} // snake_case
```

### 函式與方法

```typescript
// ✅ Good - camelCase
function calculateTotal(): number {
}

const fetchUserData = async (id: string): Promise<User> => {
};

// ❌ Bad
function CalculateTotal() {}  // PascalCase
function calculate_total() {} // snake_case
```

### 變數

```typescript
// ✅ Good - camelCase
const userName = "John";
let totalAmount = 100;
const isActive = true;

// ❌ Bad
const user_name = "John";  // snake_case
const UserName = "John";   // PascalCase
```

### 常數

```typescript
// ✅ Good - SCREAMING_SNAKE_CASE 或 camelCase
const MAX_RETRY_COUNT = 3;
const DEFAULT_TIMEOUT = 30;
const API_BASE_URL = "https://api.example.com";

// 或者（物件/陣列常數可用 camelCase）
const defaultConfig = { timeout: 30 };

// ❌ Bad - 不一致
const maxRetryCount = 3;  // 簡單值應用 SCREAMING
const DEFAULT_CONFIG = {} // 物件可用 camelCase
```

### React Components

```typescript
// ✅ Good - PascalCase
function UserProfile({ user }: UserProfileProps) {
  return <div>{user.name}</div>;
}

const OrderList: React.FC<OrderListProps> = ({ orders }) => {
  return <ul>{orders.map(o => <li key={o.id}>{o.name}</li>)}</ul>;
};

// ❌ Bad
function userProfile() {}  // camelCase
const order_list = () => {} // snake_case
```

### Hooks

```typescript
// ✅ Good - use 前綴 + camelCase
function useUserData(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  // ...
  return user;
}

function useLocalStorage<T>(key: string, initialValue: T) {
  // ...
}

// ❌ Bad
function UserData() {}     // 沒有 use 前綴
function use_user_data() {} // snake_case
```

## 代碼結構

### 函式長度

```typescript
// ✅ Good - 函式保持簡短
function processOrder(order: Order): ProcessedOrder {
  const validated = validateOrder(order);
  const calculated = calculateTotal(validated);
  return formatOrder(calculated);
}

// ❌ Bad - 函式過長
function doEverything(data: any) {
  // ... 100+ 行
}
```

### Early Return

```typescript
// ✅ Good
function process(user: User | null): Result {
  if (!user) {
    return { error: 'No user' };
  }

  if (!user.isActive) {
    return { error: 'Inactive user' };
  }

  return { data: execute(user) };
}

// ❌ Bad - 深層嵌套
function process(user: User | null): Result {
  if (user) {
    if (user.isActive) {
      return { data: execute(user) };
    } else {
      return { error: 'Inactive user' };
    }
  } else {
    return { error: 'No user' };
  }
}
```

## TypeScript 特定

### 明確的型別

```typescript
// ✅ Good - 函式參數和回傳值有型別
function fetchUser(id: string): Promise<User> {
  // ...
}

// 物件解構也要有型別
function createOrder({ items, userId }: CreateOrderParams): Order {
  // ...
}

// ❌ Bad - 使用 any
function fetchUser(id: any): any {
  // ...
}
```

### Interface vs Type

```typescript
// ✅ Good - 物件結構用 interface
interface User {
  id: string;
  name: string;
  email: string;
}

// ✅ Good - union/intersection 用 type
type Status = 'pending' | 'approved' | 'rejected';
type UserWithOrders = User & { orders: Order[] };

// ❌ Bad - 混用無規則
type User = { id: string }  // 物件應用 interface
interface Status = 'pending' | 'approved'  // union 應用 type
```

### Strict Mode

```typescript
// ✅ Good - 使用 strict mode 特性
function getUser(id: string): User | undefined {
  return users.find(u => u.id === id);
}

// 使用時要檢查
const user = getUser('123');
if (user) {
  console.log(user.name);  // TypeScript 知道這裡 user 不是 undefined
}

// ❌ Bad - 忽略 null/undefined
const user = getUser('123');
console.log(user.name);  // 可能是 undefined
```

## 現代 JavaScript 語法

### Destructuring

```typescript
// ✅ Good
const { name, email } = user;
const [first, second, ...rest] = items;

function processUser({ id, name }: User) {
  // ...
}

// ❌ Bad
const name = user.name;
const email = user.email;
```

### Optional Chaining & Nullish Coalescing

```typescript
// ✅ Good
const avatar = user?.profile?.avatar ?? defaultAvatar;
const count = data?.items?.length ?? 0;

// ❌ Bad
const avatar = user && user.profile && user.profile.avatar
  ? user.profile.avatar
  : defaultAvatar;
```

### Arrow Functions

```typescript
// ✅ Good - 簡單 callback 用 arrow
const names = users.map(u => u.name);
const active = users.filter(u => u.isActive);

// ✅ Good - 需要 this 的用 function
const obj = {
  value: 1,
  getValue() {
    return this.value;
  }
};

// ❌ Bad - 不一致
const names = users.map(function(u) { return u.name; });
```

### const vs let

```typescript
// ✅ Good - 預設用 const
const user = await fetchUser(id);
const items = [1, 2, 3];

// let 只在需要重新賦值時使用
let count = 0;
for (const item of items) {
  count += item.value;
}

// ❌ Bad
var user = await fetchUser(id);  // 不要用 var
let items = [1, 2, 3];           // 不需要重新賦值，用 const
```

## React 特定

### Component 結構

```typescript
// ✅ Good - 清晰的結構
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
}

function UserCard({ user, onEdit }: UserCardProps) {
  const handleClick = useCallback(() => {
    onEdit(user.id);
  }, [user.id, onEdit]);

  return (
    <div className="user-card">
      <h2>{user.name}</h2>
      <button onClick={handleClick}>Edit</button>
    </div>
  );
}
```

### Hooks 使用

```typescript
// ✅ Good - 正確的 dependency array
useEffect(() => {
  fetchData(userId);
}, [userId]);

const memoizedValue = useMemo(() => {
  return expensiveCalculation(data);
}, [data]);

// ❌ Bad - 缺少 dependencies
useEffect(() => {
  fetchData(userId);  // userId 應該在 dependency array
}, []);
```

### Event Handlers

```typescript
// ✅ Good - handle 前綴
const handleSubmit = (e: FormEvent) => {
  e.preventDefault();
  // ...
};

const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
  setValue(e.target.value);
};

// ❌ Bad - 不一致的命名
const onSubmit = () => {};
const submitHandler = () => {};
const doSubmit = () => {};
```

## 檢查清單

style-reviewer 應檢查：

- [ ] 命名規範符合（PascalCase/camelCase）
- [ ] TypeScript 型別完整（無 any）
- [ ] 使用 const 而非 let/var（除非需要重新賦值）
- [ ] 使用 optional chaining 和 nullish coalescing
- [ ] 使用 destructuring
- [ ] Arrow function 用於 callback
- [ ] React component 有明確的 Props interface
- [ ] Hooks dependencies 正確
- [ ] 無 magic number/string
- [ ] 一致的錯誤處理模式
