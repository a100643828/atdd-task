# 知識盤點工作流程

## Phase 1: Knowledge Audit（知識盤點 + 代碼調查）

### 1.1 讀取規範（必須）

```
先讀取：
1. knowledge/access/reader.md - 了解讀取規範
2. knowledge/access/writer.md - 了解寫入規範
```

### 1.2 讀取知識文件

```
domains/{project}/ul.md
domains/{project}/business-rules.md
domains/{project}/strategic/{domain}.md（商務邏輯）
domains/{project}/tactical/{domain}.md（系統設計）
domains/{project}/domain-map.md（跨域時）

fallback（未遷移的 domain）：
domains/{project}/contexts/{domain}.md
```

對每筆讀取到的知識，標註來源 `[文件]`，含路徑和章節。

### 1.3 代碼調查

> **Curator 有 Glob/Grep/Read 能力，必須用來調查專案程式碼。**
> 專案程式碼路徑由呼叫者透過 prompt 提供（`專案程式碼路徑`）。

調查步驟：

1. **Glob 搜尋**：搜尋相關 models/services/domains 檔案
   ```
   Glob: {project_path}/app/models/*{topic_keyword}*.rb
   Glob: {project_path}/app/services/*{topic_keyword}*.rb
   ```

2. **Grep 搜尋**：搜尋主題相關 class name、method name
   ```
   Grep: {topic_keyword} in {project_path}/app/
   ```

3. **Read 關鍵檔案**：class 定義、associations、validations、state machine、enums
   - 重點關注：`has_many`/`belongs_to`、`validates`、`aasm`/`state_machine`、`scope`、`enum`
   - 記錄每個發現，標註 `[code]`，含完整檔案路徑

4. **記錄發現**：整理為結構化清單
   ```
   [code] {project_path}/app/models/foo.rb
   - class Foo < ApplicationRecord
   - belongs_to :bar
   - has_many :bazzes
   - aasm column: :status do ...
   ```

### 1.4 重複檢查

> **禁止提案已存在的知識。**

將所有即將報告的術語、規則 vs ul.md / business-rules.md 現有條目交叉比對：

| 分類 | 處理方式 |
|------|----------|
| 已知且完整 | 不列入提案，在盤點報告標記為「已覆蓋」 |
| 已知但不完整 | 列入提案為 `[修正]`，標註缺失部分 |
| 未知 | 列入提案為 `[新增]` |

### 1.5 評估知識完整度

參考 `.claude/config/confidence/knowledge.yml`：

| 維度 | 權重 | 檢查項 |
|------|------|--------|
| 術語完整度 | 10% | Entity 都有定義、含類型、範例、交叉引用 |
| 規則覆蓋度 | 25% | VR/ST/CA/AU/CD 規則完整，跨域 CD 有對應 |
| 領域邊界清晰度 | 15% | 責任明確、關係清楚、整合點有文件 |
| 物件模型清晰度 | 15% | 核心概念已識別、關係清楚、商務邏輯歸屬明確 |
| 跨文件一致性 | 15% | 各文件無矛盾、狀態機與規則匹配 |
| 知識可操作性 | 10% | 下游 Agent 可直接使用、規則有具體數值 |
| 文件結構完整度 | 10% | strategic 各區塊齊全、Knowledge Gaps 已記錄 |

### 1.6 輸出盤點報告

```
═══ 知識盤點報告 ═══

📊 信心度: {X}%

📌 知識完整度:
- 術語: {N} 個定義 / {M} 個預期 ({score}/10)
- 規則: {N} 條 / {M} 預期 ({score}/25)
- 邊界: {description} ({score}/15)
- 物件模型: {description} ({score}/15)
- 一致性: {description} ({score}/15)
- 可操作性: {description} ({score}/10)
- 文件結構: {description} ({score}/10)

📂 我找到了什麼:

  [文件] 來源:
  - domains/{project}/ul.md: {N} 個相關術語（已覆蓋: {list}）
  - domains/{project}/strategic/{domain}.md: {summary}
  - ...

  [code] 來源:
  - {path}/app/models/foo.rb: {發現摘要}
  - {path}/app/models/bar.rb: {發現摘要}
  - ...

⚠️ Knowledge Gaps（無法從文件或代碼確認）:
1. [Gap] {description}

❌ 矛盾發現（標註雙方來源）:
1. [Conflict] {description}
   - 來源 A [文件]: {path} 說 ...
   - 來源 B [code]: {path} 顯示 ...

📋 重複檢查結果:
- 已覆蓋（不提案）: {list}
- 不完整（將修正）: {list}
- 未知（將新增）: {list}
```

---

## Phase 2: Deep Interview（深度訪談）

> **核心原則**：用戶是知識來源，Curator 是策展者。
> 此階段取代原本淺層的 Clarification，改為結構化深度訪談。

### 2.1 展示盤點報告

先向用戶展示 Phase 1 的完整盤點報告（含來源標籤），讓用戶了解 Curator 已經知道什麼、不知道什麼。

### 2.2 整理訪談主題清單

從盤點報告整理待討論主題：

```
═══ 訪談主題清單 ═══

來自 Knowledge Gaps:
1. {topic from gap}
2. {topic from gap}

來自矛盾發現:
3. {topic from conflict}

來自代碼調查（結構存在但意圖不明）:
4. {topic from code discovery}

總計: {N} 個主題待討論
```

### 2.3 逐主題訪談

**規則**：

1. **一次只討論一個主題** — 不可在同一個 AskUserQuestion 混合多個主題
2. **追問模式**（按序推進）：
   - 開放式：「關於 {X}，能說明它的用途嗎？」
   - 確認式：「所以 {X} 是用來 {Y}，對嗎？」
   - 邊界式：「{X} 的範圍到哪裡？{Z} 算不算在內？」
   - 追問：「你提到 {A}，這和 {B} 的關係是什麼？」
3. **每個回答記錄為 `[用戶]`**，標明訪談輪次（Q1, Q2, ...）
4. **追問到底** — 一個主題追問到邊界清楚才換下一個

**禁止行為**：

- 禁止在用戶未回答前假設答案
- 禁止說「根據一般慣例，通常...」填補空白
- 禁止使用 LLM 通用知識填充回答
- 禁止 3 輪 Q&A 之前宣稱結構信心度 >= 70%

### 2.4 追蹤訪談進度

每輪 Q&A 後輸出進度：

```
═══ 訪談進度 ═══

已完成主題: {list}
當前主題: {current}
待討論主題: {remaining}
Q&A 輪數: {N}（最少 3 輪）
結構信心度: {X}%（目標: >= 70%）
```

### 2.5 退出條件

**必須全部滿足**：
- 結構信心度 >= 70%
- Q&A >= 3 輪
- 所有 Knowledge Gaps 已討論（可標記為 [待確認] 但不可忽略）

---

## Phase 3: Proposal（帶來源標註的知識更新提案）

> **重要**：提案必須展示**完整的擬寫內容**，而非僅列出變更摘要。
> 用戶需要看到實際要寫入的文字，才能判斷是否正確。
> **每條知識必須標註來源**，無來源的知識不得列入提案。

### 3.1 產出完整擬寫內容

對每個要更新的文件，展示：
- 要新增/修改的**完整文字內容**（不是摘要）
- 每個項目標註 Curator 的**內容信心度**（百分比）
- 信心度 < 95% 的項目標註**不確定的原因**
- **每個項目標註來源**

### 3.2 提案格式

見 `proposal-format.md`

### 3.3 來源對信心度的影響

| 來源 | 基礎信心度加成 | 說明 |
|------|---------------|------|
| `[用戶]` | 高 | 用戶親口說的 |
| `[文件]` | 中高 | 已記錄的 |
| `[code]` | 中 | 結構存在但意圖需確認 |
| `[推導]` | 低 | 需驗證 |
| `[待確認]` | 最低 | 必須在 Phase 4 解決 |

### 3.4 內容信心度標註

```
═══ 知識更新提案 ═══

📝 ul.md 變更:
┌─────────────────────────────────────┐
│ [新增] ErpPeriod                    │ 信心度: 95% ✅
│   中文: ERP 週期                    │ 來源: [用戶] Q2 + [code] app/models/erp_period.rb
│   定義: ...                         │
│   類型: Aggregate                   │
├─────────────────────────────────────┤
│ [新增] RecordType                   │ 信心度: 80% ⚠️
│   中文: 週期類型                    │ 來源: [code] app/models/erp_period.rb:L15
│   定義: ...                         │ 不確定：用戶說「週期類型」
│   類型: ValueObject                 │   但程式碼指向「記錄類型」
│                                     │   需要用戶確認
├─────────────────────────────────────┤
│ [新增] ExportBatch                  │ 信心度: 70% ❌
│   中文: 匯出批次                    │ 來源: [推導] A + B → C
│   定義: ...                         │ 推理鏈: erp_period has_many erp_records
│   類型: Entity                      │   + export 後狀態變 exported
│                                     │   → 推測存在批次概念
└─────────────────────────────────────┘
```

**信心度標記**：
- `>= 95%` → ✅ 可直接寫入
- `80-94%` → ⚠️ 需要用戶確認
- `< 80%` → ❌ 必須詢問後才能寫入

---

## Phase 4: Content Validation（不可跳過的驗證迴圈）⭐ 重要

> **核心原則**：提案內容的正確性必須經過用戶驗證，不能僅靠 Curator 推測。
> **即使 Phase 3 信心度很高，仍必須至少 1 輪驗證。Phase 4 不可跳過。**

### 4.1 強制要求

1. **至少 1 輪驗證** — 即使所有項目信心度 >= 95%，仍必須展示提案讓用戶逐項確認
2. **逐項詢問** — 每個項目問「正確/錯誤/需修改」
3. **重點關注**：
   - `[推導]` 項目 — 推理鏈是否成立？
   - `[待確認]` 項目 — 必須在此階段解決
   - 涉及數值/公式的項目 — 精確度要求高
   - `[code]` 項目 — 結構存在但意圖可能不同

### 4.2 驗證流程

```
┌─────────────────────┐
│ 展示提案內容         │
│ （含各項信心度+來源）│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 逐項詢問用戶         │
│ 「正確/錯誤/需修改」 │◄─────────┐
│ 使用 AskUserQuestion │          │
└──────────┬──────────┘          │
           │                     │
           ▼                     │
┌─────────────────────┐          │
│ 根據回答修正內容     │          │
│ 重新評估信心度       │          │
└──────────┬──────────┘          │
           │                     │
           ▼                     │
┌─────────────────────┐          │
│ 退出條件全滿足？     │── No ───┘
└──────────┬──────────┘
           │ Yes
           ▼
┌─────────────────────┐
│ 進入 Phase 5: Commit │
└─────────────────────┘
```

### 4.3 提問原則

- **具體而非抽象**：問「ErpRecord 的中文應該是『ERP 週期紀錄』還是『ERP 記錄』？」而非「這個定義對嗎？」
- **提供選項**：盡量給出 2-3 個選項讓用戶選擇
- **標註來源**：說明信心度不足的原因
- **批次提問**：同一主題的相關問題可以一次問（使用 AskUserQuestion 的多問題功能）

### 4.4 驗證報告

每輪驗證後輸出：

```
═══ 驗證進度 ═══

📊 內容信心度: {X}% → {Y}%（目標: 95%）

✅ 已確認項目:
- ErpPeriod 定義（用戶確認）[用戶]
- ErpRecord 定義（用戶修正：「ERP 週期紀錄」→「ERP 記錄」）[用戶]

⚠️ 待確認項目:
- RecordType 中文名稱（信心度 80%）[code]

❌ 需修正項目:
- PeriodNumber 範例（用戶指出格式錯誤）

🔍 [推導] 項目驗證狀態:
- ExportBatch: {已確認 | 待確認 | 用戶否決}

📝 剩餘問題: {N} 個
驗證輪數: {current}（最少 1 輪）
```

### 4.5 退出條件

**必須全部滿足**：
- 整體內容信心度 >= 95%
- 所有 `[推導]` 項目已獲用戶確認或否決
- 沒有 `[待確認]` 殘留
- 至少 1 輪完整驗證

---

## Phase 5: Commit（知識寫入）

> **前置條件**：內容信心度 >= 95%，Phase 4 退出條件全部滿足

### 5.1 最終確認

```
═══ 準備寫入 ═══

📊 內容信心度: {X}%（>= 95% ✅）

即將更新以下文件：
1. ul.md: 新增 {n} 術語
2. business-rules.md: 新增 {n} 規則
3. strategic/{domain}.md: {建立/更新}
4. tactical/{domain}.md: {建立/更新}
5. domain-map.md: {建立/更新}

確認寫入嗎？(y/n)
```

### 5.2 執行寫入

用戶確認後：

1. 讀取 writer.md 規範
2. 依序更新各文件（使用 Edit tool）
3. 更新每個文件的 Maintenance Log（含來源欄位）
4. 輸出更新摘要

### 5.3 Maintenance Log 格式

```
| {date} | {action} | curator | /knowledge session | 來源: {sources} |
```

其中 `{sources}` 列出本次寫入涉及的來源類型，例如：
- `來源: [用戶] Q2, Q5 + [code] app/models/foo.rb`
- `來源: [文件] strategic/Bar.md + [用戶] Q3`

### 5.4 完成摘要

```
═══ 更新完成 ═══

✅ ul.md: 新增 {n} 術語，修正 {m} 術語
✅ business-rules.md: 新增 {n} 規則，修正 {m} 規則
✅ strategic/{domain}.md: 更新 {sections}
✅ tactical/{domain}.md: 更新 {sections}

📋 Maintenance Log 已更新（含來源標註）

💡 提示：可使用 git diff domains/{project}/ 查看變更
```
