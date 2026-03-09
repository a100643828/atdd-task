# Knowledge Writer Protocol

> **Purpose**: 定義 Agent 寫入 domain 知識的標準模式。

---

## 核心原則

### 1. 提案優先 + 內容驗證

**所有變更必須先生成提案，經內容驗證達 95% 信心度後才能寫入。**

```
錯誤 ❌：直接修改文件
錯誤 ❌：顯示摘要 → 用戶確認 → 執行寫入（內容未經驗證）
正確 ✅：展示完整擬寫內容 → 用戶逐項審閱 → 驗證迴圈 → 信心度 >= 95% → 寫入
```

**寫入前置條件**：
- 提案必須展示**完整擬寫內容**（非僅變更摘要）
- 每個項目標註**內容信心度**
- 信心度 < 95% 的項目必須經過驗證迴圈（Phase 4）
- 整體內容信心度 >= 95% 才能進入寫入（Phase 5）

### 2. 最小變更

只修改必要的部分，不重寫整個文件。

```
錯誤 ❌：重寫整個 ul.md
正確 ✅：使用 Edit tool 只修改特定區塊
```

### 3. 格式一致

遵循現有模板格式。參考：
- `domains/TEMPLATE-ul.md`
- `domains/TEMPLATE-business-rules.md`
- `domains/TEMPLATE-strategic.md`（商務邏輯）
- `domains/TEMPLATE-tactical.md`（系統設計）
- `domains/TEMPLATE-context.md`（⚠️ DEPRECATED，僅供未遷移的 domain 參考）
- `domains/TEMPLATE-domain-map.md`

### 4. 版本追蹤

所有變更都要：
- 更新文件的 Maintenance Log
- 透過 git 版控追蹤

---

## 提案格式

### 結構化提案

```
═══ 知識更新提案 ═══

📝 {filename} 變更:
┌─────────────────────────────────────┐
│ [{操作}] {項目名稱}                  │
│   {欄位}: {值}                       │
│   {欄位}: {值}                       │
├─────────────────────────────────────┤
│ [{操作}] {另一個項目}                │
│   原: {舊值}                         │
│   新: {新值}                         │
│   原因: {修改原因}                   │
└─────────────────────────────────────┘

═══════════════════════════════════════
確認寫入這些變更嗎？(y/n)
```

**操作類型**：
- `[新增]` - 新增項目
- `[修正]` - 修改現有項目
- `[刪除]` - 移除項目（謹慎使用）
- `[更新]` - 更新章節內容

---

## 寫入操作

### 1. 新增術語（ul.md）

#### 步驟

1. **讀取現有文件**，了解現有術語和格式
2. **找到插入位置**：按字母順序，找到對應的字母區塊
3. **生成術語內容**：遵循 Schema（`schemas/ul-entry.yml`）
4. **使用 Edit tool** 插入新術語
5. **更新 Maintenance Log**

#### 定位規則

```
術語 "ErpRecord"
  → 找到 "## E" 區塊
  → 在該區塊內按字母順序插入
  → 如果 "## E" 不存在，在 "## D" 之後建立
```

#### 格式範本

```markdown
### {TermName}
**中文**: {chinese}
**定義**: {definition}
**類型**: {Entity | ValueObject | Aggregate | Service | Event | Concept}
**所屬 Aggregate**: {aggregateRoot}（如適用）
**相關 Entity/Component**: {relatedEntities}
**業務規則**: {businessRules}
**範例**: {examples}

**注意事項**:
- {note1}
- {note2}

**相關詞彙**: {relatedTerms}
```

#### Maintenance Log 更新

```markdown
| {YYYY-MM-DD} | Added term: {TermName} | curator | /knowledge session |
```

### 2. 新增規則（business-rules.md）

#### 步驟

1. **讀取現有規則**，找到最大 ID
2. **分配新 ID**：`{類別}-{最大ID+1}`
3. **找到插入位置**：對應類別區塊
4. **生成規則內容**：遵循 Schema
5. **使用 Edit tool** 插入
6. **更新 Maintenance Log**

#### ID 分配規則

```
現有最大 VR-xxx = VR-023
新規則 ID = VR-024
```

#### 定位規則

```
規則類別 "validation"
  → 找到 "### 1. Validation Rules" 區塊
  → 在該區塊末尾插入（或按 ID 順序）
```

#### 格式範本（依類別）

**Validation Rule (VR-xxx)**：
```markdown
#### Rule: {RuleName}
**ID**: `VR-{number}`
**Domain**: {domain}
**Description**: {description}

**Condition**: {condition}

**Validation Logic**:
```{language}
{logic}
```

**Error Message**: "{errorMessage}"

**Enforcement Location**:
- Database: {database_constraint}
- Application: {application_location}

**Test Coverage**:
- [ ] Positive case
- [ ] Negative case
- [ ] Edge cases

**Examples**:
```
✅ Valid: {valid_example}
❌ Invalid: {invalid_example} → {error}
```

**Related Rules**: {relatedRules}
```

**State Transition Rule (ST-xxx)**：
```markdown
#### Rule: {EntityName} State Transitions
**ID**: `ST-{number}`
**Domain**: {domain}
**Entity**: {entity}

**States**: {state_list}

**Valid Transitions**:
```mermaid
graph LR
    {mermaid_diagram}
```

**Transition Rules**:
| From State | To State | Condition | Triggered By | Side Effects |
|------------|----------|-----------|--------------|--------------|
{transition_table}

**Forbidden Transitions**:
- ❌ {from} → {to}: {reason}
```

### 3a. 更新 Strategic（strategic/{domain}.md）

#### 步驟

1. **讀取現有文件**，了解結構
2. **定位目標章節**：`## {SectionName}`
3. **準備更新內容**（僅商務邏輯，不含 Code Location 或欄位定義）
4. **使用 Edit tool** 替換或插入
5. **更新 Change History**

#### 常見更新章節

| 章節 | 更新場景 |
|------|----------|
| 商務目的 / 商務能力 | 商務定位變更 |
| 範疇定義 | 邊界調整 |
| 狀態流程 | 商務流程變更 |
| 商務規則 | 新增或連結規則 |
| 商務依賴 | 上下游關係變更 |
| 常見問題 | 新增商務面 FAQ |

### 3b. 更新 Tactical（tactical/{domain}.md）

#### 步驟

1. **讀取現有文件**，了解結構
2. **定位目標章節**：`## {SectionName}`
3. **準備更新內容**（含完整技術細節、Code Location、欄位定義）
4. **使用 Edit tool** 替換或插入
5. **更新 Change History**

#### 常見更新章節

| 章節 | 更新場景 |
|------|----------|
| Domain Model → Aggregates | 新增或修改 Aggregate 定義（含欄位） |
| Domain Model → Entities | 新增或修改 Entity 定義（含欄位） |
| Use Cases | 新增 UseCase |
| Integration 技術細節 | 更新整合方式和錯誤處理 |
| Patterns & Anti-Patterns | 記錄設計模式 |
| Common Pitfalls | 新增常見陷阱 |

### 3c. 更新 Context（contexts/{domain}.md）— ⚠️ DEPRECATED

> 僅用於尚未遷移到 strategic/ + tactical/ 的 domain。新 domain 請使用 3a + 3b。

#### 步驟

1. **讀取現有文件**，了解結構
2. **定位目標章節**：`## {SectionName}`
3. **準備更新內容**
4. **使用 Edit tool** 替換或插入
5. **更新 Change History**

#### 常見更新章節

| 章節 | 更新場景 |
|------|----------|
| Domain Model → Aggregates | 新增或修改 Aggregate 定義 |
| Domain Model → Entities | 新增或修改 Entity 定義 |
| Domain Events | 新增 Domain Event |
| Business Rules | 新增或連結規則 |
| Integration Points | 更新整合點 |
| FAQ | 新增常見問題 |

#### 新增 Aggregate 範本

```markdown
#### Aggregate: {AggregateName}

**Aggregate Root**: {RootEntityName}

**Purpose**: {purpose}

**Consistency Boundary**: {boundary_description}

**Components**:
```
{AggregateName} (Root)
├── {Entity1}
│   ├── {attribute1}
│   └── {attribute2}
├── {Entity2}
└── {ValueObject1}
```

**Invariants**:
1. {invariant1}
2. {invariant2}

**Domain Methods**:
```ruby
class {AggregateName}
  # Commands
  def {method1}({params})
  def {method2}({params})

  # Queries
  def {query1}
end
```
```

#### 新增 Domain Event 範本

```markdown
### Event: {EventName}

**Trigger**: {trigger_description}

**Payload**:
```ruby
class {EventName} < DomainEvent
  attribute :aggregate_id, Types::String
  attribute :occurred_at, Types::DateTime
  attribute :{field1}, Types::{Type}
  attribute :{field2}, Types::{Type}
end
```

**Publishers**: {publisher_list}

**Subscribers**: {subscriber_list}

**Use Cases**:
- {use_case_1}
- {use_case_2}
```

### 4. 更新邊界（domain-map.md）

#### 步驟

1. **讀取現有文件**
2. **定位目標區塊**
3. **更新 Mermaid 圖表**（如需）
4. **更新描述文字**
5. **更新 Maintenance Log**

#### Context Mapping 更新範本

```markdown
#### Pattern: {PatternName}
**Upstream**: {UpstreamDomain}
**Downstream**: {DownstreamDomain}

**Description**: {description}

**Contract**:
- Upstream exposes: {api_or_events}
- Downstream consumes: {api_or_events}

**Integration Method**: [REST API | gRPC | Domain Events]

**Example**:
```
{integration_example}
```
```

---

## 衝突處理

當發現文件中存在矛盾時：

### 步驟

1. **列出衝突點**
```
[Conflict] ul.md 的「{term}」定義為 "{def1}"
           contexts/{domain}.md 的定義為 "{def2}"
```

2. **詢問用戶**
```
這兩個定義不一致，哪個是正確的？
1. ul.md 的版本
2. contexts/{domain}.md 的版本
3. 兩者都不對，正確的是：____
```

3. **統一更新**：確認後，更新所有涉及的文件

---

## 錯誤處理

| 情況 | 處理方式 |
|------|----------|
| 用戶拒絕 (n) | 不寫入任何變更，保留提案供後續參考 |
| 寫入失敗 | 報告錯誤，不繼續後續寫入 |
| 格式錯誤 | 自動修正格式，再次確認 |

---

## 安全守則

1. **只修改知識庫文件**：`domains/` 和 `knowledge/` 目錄
2. **不修改程式碼**：知識庫是文件，不是程式碼
3. **不刪除內容**：除非用戶明確要求，只新增或修改
4. **保留歷史**：所有變更記錄到 Maintenance Log
