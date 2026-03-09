# Clean Architecture 專業知識

## 依賴規則

**核心原則**：依賴方向只能向內
- 外層依賴內層
- 內層不知道外層的存在
- Domain 層（Entities）不依賴任何外層

## 層次結構

```
┌─────────────────────────────────────┐
│          Frameworks & Drivers       │  ← 最外層（DB、Web、UI）
│   ┌─────────────────────────────┐   │
│   │     Interface Adapters      │   │  ← Controllers、Gateways
│   │   ┌─────────────────────┐   │   │
│   │   │     Use Cases       │   │   │  ← Application Logic
│   │   │   ┌─────────────┐   │   │   │
│   │   │   │  Entities   │   │   │   │  ← 最內層（Domain）
│   │   │   └─────────────┘   │   │   │
│   │   └─────────────────────┘   │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## 各層職責

| 層次 | 職責 | 範例 |
|------|------|------|
| **Entities** | 核心業務規則 | Domain Model, Value Objects |
| **Use Cases** | 應用程式邏輯 | Use Case Classes, Services |
| **Interface Adapters** | 格式轉換 | Controllers, Presenters, Gateways |
| **Frameworks** | 外部工具 | Rails, React, PostgreSQL |

## 架構分析檢查點

跨域盤點時需要分析：
- [ ] 依賴方向是否正確？
- [ ] 是否有違反 Dependency Rule 的設計？
- [ ] 層次分離是否清晰？
- [ ] Use Case 層是否直接依賴外部 Domain？

## 架構問題範例

```
- {ModuleA} 依賴 {ModuleB}，這個依賴方向是否正確？是否需要反轉？
- {Component} 屬於哪一層？Use Case、Interface Adapter、還是 Framework？
- 跨域呼叫應該透過 Port/Adapter 還是直接引用？
```

## 跨域整合分析

處理兩個 Domain 時：

1. **識別整合點的層次**
   - 是在 Use Case 層整合？
   - 還是在 Interface Adapter 層？

2. **確認依賴方向**
   - 核心 Domain 不應依賴輔助 Domain
   - 使用 Port/Adapter 隔離依賴

3. **建議整合模式**
   - Sync API（同步呼叫）
   - Async Events（非同步事件）
   - ACL（防腐層）
