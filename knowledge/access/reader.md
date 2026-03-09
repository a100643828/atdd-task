# Knowledge Reader Protocol

> **Purpose**: 定義 Agent 讀取 domain 知識的標準模式。

---

## 讀取前準備

1. 確認專案目錄存在：`domains/{project}/`
2. 確認 Domain 知識文件存在（優先順序）：
   - `domains/{project}/strategic/{domain}.md` + `domains/{project}/tactical/{domain}.md`（新格式）
   - `domains/{project}/contexts/{domain}.md`（舊格式，fallback）
3. 了解知識文件結構（見下方）

---

## 知識文件結構

### ul.md（術語表）

```markdown
## A

### TermName
**中文**: 中文名稱
**定義**: 定義描述
**類型**: Entity | ValueObject | Aggregate | ...
**相關 Entity/Component**: ...
...

## B

### AnotherTerm
...
```

**特點**：
- 按字母 A-Z 排序
- 每個術語以 `### TermName` 開頭
- 欄位以 `**欄位名**:` 格式

### business-rules.md（業務規則）

```markdown
### 1. Validation Rules (資料驗證規則)

#### Rule: RuleName
**ID**: `VR-001`
**Domain**: DomainName
**Description**: ...

### 2. Constraint Rules (約束條件規則)
...

### 3. State Transition Rules (狀態轉換規則)
...
```

**特點**：
- 按規則類別分區（6 大類）
- 每個規則以 `#### Rule:` 開頭
- ID 格式：`{VR|CR|ST|CA|AU|TE|CD}-{三位數字}`

### strategic/{domain}.md（商務邏輯）— 新格式

```markdown
## 商務目的
## 商務能力
## 範疇定義
## 核心概念
## 狀態流程
## 商務規則
## 商務依賴
## 常見問題
```

**特點**：
- 不含 Code Location、欄位定義、技術實作細節
- 讀者：specist、tester、stakeholder

### tactical/{domain}.md（系統設計）— 新格式

```markdown
## Domain Model
### Aggregates（含欄位、Code Location）
### Entities（含欄位、Code Location）
### Value Objects
### Domain Services（含 Code Location）
## Use Cases
## 狀態轉移實作（含 Side Effects）
## Integration 技術細節
## Patterns & Anti-Patterns
## Common Pitfalls
## Related Documentation
```

**特點**：
- 含完整技術細節
- 讀者：specist、coder、style-reviewer

### contexts/{domain}.md（深度知識）— ⚠️ DEPRECATED

```markdown
## Domain Overview
...

## Core Concepts
...

## Domain Model
### Aggregates
### Entities
### Value Objects
### Domain Services
...

## Business Rules
...

## Domain Events
...
```

**特點**：
- 固定的章節結構
- 每個章節以 `## SectionName` 開頭
- **待遷移至 strategic/ + tactical/**

### domain-map.md（領域邊界）

```markdown
## Domain Overview
...

## Domain Boundaries
### Domain: DomainName
...

## Domain Relationships
### Context Mapping
...
```

**特點**：
- 包含 Mermaid 圖表
- Context Mapping 模式定義

---

## 讀取操作

### 1. 術語查詢

#### 查詢單一術語

```
目標：找到特定術語的定義
路徑：domains/{project}/ul.md
方法：
  1. 搜尋 "### {TermName}"
  2. 讀取到下一個 "### " 或 "## " 之前的所有內容
```

**範例**：
```bash
# 使用 Grep 找到術語位置
grep -n "### ProjectFund" domains/sf_project/ul.md

# 使用 Read 讀取該區塊
Read domains/sf_project/ul.md, offset={line}, limit=20
```

#### 查詢 Domain 相關術語

```
目標：找到所有屬於特定 Domain 的術語
路徑：domains/{project}/ul.md
方法：
  1. 搜尋 "**Domain**: {domain}" 或類型欄位
  2. 收集所有匹配的術語區塊
```

#### 列出所有術語

```
目標：獲取術語清單（不含完整定義）
路徑：domains/{project}/ul.md
方法：
  1. 搜尋所有 "### " 開頭的行
  2. 提取術語名稱
```

### 2. 規則查詢

#### 依 ID 查詢

```
目標：找到特定規則
路徑：domains/{project}/business-rules.md
方法：
  1. 搜尋 "**ID**: `{rule_id}`"
  2. 向上找到 "#### Rule:" 作為區塊開始
  3. 向下讀取到下一個 "#### " 或 "### "
```

#### 依 Domain 查詢

```
目標：找到特定 Domain 的所有規則
路徑：domains/{project}/business-rules.md
方法：
  1. 搜尋 "**Domain**: {domain}"
  2. 收集所有匹配的規則區塊
```

#### 依類別查詢

```
目標：找到特定類別的所有規則
路徑：domains/{project}/business-rules.md
方法：
  1. 找到 "### {N}. {CategoryName}" 區塊
  2. 讀取該區塊內所有規則
```

**類別對照**：
| 類別 | 標題 | ID 前綴 |
|------|------|---------|
| 驗證規則 | Validation Rules | VR |
| 約束規則 | Constraint Rules | CR |
| 狀態轉換 | State Transition Rules | ST |
| 計算規則 | Calculation Rules | CA |
| 授權規則 | Authorization Rules | AU |
| 時間規則 | Temporal Rules | TE |
| 跨域規則 | Cross-Domain Rules | CD |

### 3. 深度知識查詢

#### 商務邏輯

```
目標：讀取 Domain 的商務邏輯知識
路徑（優先）：domains/{project}/strategic/{domain}.md
路徑（fallback）：domains/{project}/contexts/{domain}.md
方法：Read 整個文件

常用章節（strategic）：
- 商務目的
- 商務能力
- 範疇定義
- 狀態流程
- 商務規則
- 商務依賴
```

#### 系統設計

```
目標：讀取 Domain 的技術實作知識
路徑（優先）：domains/{project}/tactical/{domain}.md
路徑（fallback）：domains/{project}/contexts/{domain}.md
方法：Read 整個文件

常用章節（tactical）：
- Domain Model（Aggregates、Entities、Value Objects）
- Use Cases
- Integration 技術細節
- Patterns & Anti-Patterns
- Common Pitfalls
```

#### 向下相容

```
如果 strategic/ 或 tactical/ 不存在，fallback 到 contexts/{domain}.md。
未遷移的專案（sf_project、stock_commentary）仍使用 contexts/ 格式。
```

### 4. 邊界查詢

#### Domain 邊界

```
目標：讀取 Domain 的邊界定義
路徑：domains/{project}/domain-map.md
方法：
  1. 搜尋 "### Domain: {DomainName}"
  2. 讀取該 Domain 的邊界區塊
```

#### 跨域關係

```
目標：找到兩個 Domain 之間的關係
路徑：domains/{project}/domain-map.md
方法：
  1. 在 "## Domain Relationships" 區塊搜尋
  2. 找到同時包含 {DomainA} 和 {DomainB} 的區塊
  3. 識別 Context Mapping 模式
```

---

## DDD 視角的讀取

### 識別 Aggregate

```
位置（優先）：tactical/{domain}.md → Domain Model → Aggregates
位置（fallback）：contexts/{domain}.md → Domain Model → Aggregates
尋找：
- Aggregate Root 標記
- 內部 Entity 清單
- Value Object 清單
- Invariants（不變式）
```

### 識別 Domain Event

```
位置（優先）：tactical/{domain}.md → Domain Events
位置（fallback）：contexts/{domain}.md → Domain Events
尋找：
- Event 名稱（過去式動詞）
- Trigger（觸發條件）
- Payload（資料結構）
- Publishers/Subscribers
```

### 識別 Context Mapping

```
位置（優先）：strategic/{domain}.md → 商務依賴
位置（fallback）：domain-map.md → Domain Relationships
模式辨識：
- Customer-Supplier：上游/下游關係
- Conformist：直接使用上游模型
- ACL：有翻譯層
- Shared Kernel：共享模型
- Partnership：互相依賴
- Published Language：穩定發布
```

---

## 快取策略

- **同一對話內**：相同查詢結果可快取，避免重複讀取
- **檔案變更後**：快取失效，需重新讀取
- **跨對話**：不快取，每次重新讀取確保最新

---

## 錯誤處理

| 情況 | 處理方式 |
|------|----------|
| 專案目錄不存在 | 提示用戶確認專案 ID |
| Context 文件不存在 | 詢問是否建立新文件 |
| 術語/規則不存在 | 標記為 Knowledge Gap |
| 格式不符預期 | 嘗試模糊匹配，標記為需要修正 |
