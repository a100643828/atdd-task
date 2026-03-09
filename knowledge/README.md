# Knowledge Access Layer

> **Purpose**: 正規化的知識存取層，確保所有 Agent 以一致的方式讀取和寫入 domain 知識。

---

## 概述

此目錄定義了知識存取的規範和 Schema，供 Agent（特別是 curator）在操作 `domains/` 目錄下的知識文件時遵循。

```
knowledge/
├── README.md              # 本文件
├── schemas/               # 資料結構定義
│   ├── ul-entry.yml       # 術語條目 Schema
│   ├── business-rule.yml  # 規則條目 Schema
│   └── (已搬移至 .claude/config/confidence/knowledge.yml)
│
└── access/                # 存取規範
    ├── reader.md          # 讀取模式
    └── writer.md          # 寫入模式
```

---

## 知識文件位置

所有 domain 知識儲存在 `domains/{project}/` 目錄下：

| 文件 | 路徑 | 說明 |
|------|------|------|
| 術語表 | `domains/{project}/ul.md` | Ubiquitous Language 定義 |
| 業務規則 | `domains/{project}/business-rules.md` | 核心業務規則 |
| 領域邊界 | `domains/{project}/domain-map.md` | Context Mapping 和邊界定義 |
| 深度知識 | `domains/{project}/contexts/{domain}.md` | 特定 domain 的詳細知識 |

---

## 使用方式

### 對於 Curator Agent

1. **開始前必讀**：
   - `knowledge/access/reader.md` - 了解如何正確讀取知識
   - `knowledge/access/writer.md` - 了解如何正確寫入知識

2. **Schema 參考**：
   - 新增術語時，參考 `schemas/ul-entry.yml`
   - 新增規則時，參考 `schemas/business-rule.yml`
   - 評估信心度時，參考 `.claude/config/confidence/knowledge.yml`

### 對於其他 Agent

- **specist**：讀取知識以了解 domain 背景
- **tester**：讀取業務規則以生成測試案例
- **coder**：讀取規則以確保實作正確
- **gatekeeper**：驗證知識更新提案

---

## 原則

### 1. 提案優先

所有知識變更必須先生成提案，經用戶確認後才能寫入。

### 2. 最小變更

只修改必要的部分，不重寫整個文件。保留原有格式和結構。

### 3. 格式一致

遵循 `domains/TEMPLATE-*.md` 的格式。新增內容必須與現有內容格式一致。

### 4. 版本追蹤

所有變更都要：
- 更新文件的 Maintenance Log
- 透過 git 版控追蹤

---

## DDD 和 Clean Architecture 視角

Curator Agent 在處理知識時，會從以下視角分析：

### DDD 視角

- **術語分類**：確保每個術語正確標記為 Entity、Value Object、Aggregate、Service、Event 或 Concept
- **Aggregate 邊界**：識別 Aggregate Root 和內部 Entity
- **Domain Event**：識別重要的業務事件
- **Context Mapping**：定義 Bounded Context 之間的關係

### Clean Architecture 視角

- **依賴方向**：確保依賴只向內（外層依賴內層）
- **層次分離**：區分 Entities、Use Cases、Interface Adapters
- **邊界識別**：確保模組邊界清晰

---

## 相關文件

- 知識模板：`domains/TEMPLATE-*.md`
- 實際知識：`domains/{project}/`
- Curator Agent：`.claude/agents/curator.md`
- Knowledge Command：`.claude/commands/knowledge.md`

---

**Last Updated**: 2026-02-01
**Maintained By**: ATDD Hub
