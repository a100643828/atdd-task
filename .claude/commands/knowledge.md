---
description: 討論特定主題的 domain 知識，豐富或修正既有知識架構
---

# Knowledge Discussion: $ARGUMENTS

## 解析參數

請解析參數格式：`{project}, {主題描述}`

- **專案**：第一個逗號前的內容（去除空白）
- **主題描述**：第一個逗號後的所有內容（去除前後空白）

有效的專案 ID：`sf_project`, `core_web`, `core_web_frontend`, `digiwin_erp`, `stock_commentary`, `jv_project`, `aws_infra`

如果格式不正確或專案不存在，請提示正確格式：

```
用法：/knowledge {project}, {主題描述}
範例：/knowledge core_web, 電錶租費的三種計算模式
範例：/knowledge core_web, ErpPeriod 匯出後發票狀態追蹤
```

---

## Step 1: 驗證專案目錄

```bash
ls domains/{project}/
```

如果專案目錄不存在，提示：

```markdown
┌──────────────────────────────────────────────────────┐
│ ❌ 專案不存在                                         │
├──────────────────────────────────────────────────────┤
│ 找不到專案 `{project}` 的知識庫                       │
│ 請確認專案 ID 是否正確                                │
│                                                      │
│ 有效的專案：                                          │
│ • sf_project                                         │
│ • core_web                                           │
│ • core_web_frontend                                  │
│ • jv_project                                         │
│ • aws_infra                                          │
└──────────────────────────────────────────────────────┘
```

---

## Step 2: Domain 偵測

> **主 Agent 在呼叫 Curator 之前執行 domain 偵測。**
> 用戶不需要知道 domain 名稱，系統自動從主題描述中偵測。

### 2a. 讀取 Domain 資訊

1. 讀取 `domains/{project}/domain-map.md` — 了解所有 domain 邊界和關係
2. Grep `domains/{project}/ul.md` 搜尋主題相關術語
3. Grep `domains/{project}/business-rules.md` 搜尋主題相關規則

### 2b. 比對與識別

將主題描述中的關鍵字 vs domain boundaries 比對：

- 識別 **Primary Domain**（主要相關的 domain）
- 識別 **Related Domains**（次要相關的 domain，0~N 個）

### 2c. 信心度檢查

- 信心度 >= 70%：直接使用偵測結果
- 信心度 < 70% 或多個 domain 等權重：詢問用戶確認

使用 AskUserQuestion 詢問：
```
根據主題「{topic}」，我偵測到以下相關 domain：
- Primary: {detected_primary}
- Related: {detected_related}

這個判斷正確嗎？或者應該調整？
```

### 2d. 輸出偵測結果

```markdown
┌──────────────────────────────────────────────────────┐
│ 🔍 Domain 偵測結果                                    │
├──────────────────────────────────────────────────────┤
│ 主題：{topic}                                        │
│ Primary Domain：{primary}                            │
│ Related Domains：{related_list or 無}                │
│ 偵測信心度：{X}%                                     │
└──────────────────────────────────────────────────────┘
```

---

## Step 3: 取得專案程式碼路徑

從 `.claude/config/projects.yml` 讀取專案的 `path` 設定。

例如 `core_web` → `/Users/liu/sunnyfounder/core_web`

如果 projects.yml 中沒有該專案，`專案程式碼路徑` 設為空。

---

## Step 4: 輸出討論啟動訊息

```markdown
┌──────────────────────────────────────────────────────┐
│ 📚 知識討論：{topic}                                  │
├──────────────────────────────────────────────────────┤
│ 📁 專案：{project}                                   │
│ 🎯 Primary Domain：{primary}                        │
│ 🔗 Related Domains：{related_list or 無}             │
│                                                      │
│ 正在啟動知識策展流程...                              │
└──────────────────────────────────────────────────────┘
```

---

## Step 5: 呼叫 Curator Agent

使用 Task tool 呼叫 curator：

```
Task(
  subagent_type: "curator",
  prompt: "
    === 任務資訊 ===

    專案：{project}
    主題描述：{topic}
    Primary Domain：{primary}
    Related Domains：{related_list or 無}
    專案程式碼路徑：{project_path}（來自 projects.yml）

    === 基本規則 ===

    你是知識的策展者，不是創造者。嚴格遵守以下規則：

    1. 禁止使用 LLM 通用知識填補空白
    2. 每條知識必須標註來源：[文件]、[code]、[用戶]、[推導]
    3. [推導] 必須展示推理鏈（A + B → C）
    4. 不確定的內容標記 [待確認]，在 Phase 4 解決
    5. 提案不得包含 ul.md 已存在的術語（除非修正）

    === 必讀規範 ===

    在開始之前，請先讀取：
    1. knowledge/access/reader.md - 了解知識讀取規範
    2. knowledge/access/writer.md - 了解知識寫入規範

    === 知識文件路徑 ===

    - 術語表：domains/{project}/ul.md
    - 業務規則：domains/{project}/business-rules.md
    - 領域邊界：domains/{project}/domain-map.md
    - 商務邏輯：domains/{project}/strategic/{primary}.md
    - 系統設計：domains/{project}/tactical/{primary}.md
    - Related domains 的 strategic/tactical 也一併讀取
    - fallback：domains/{project}/contexts/{domain}.md（未遷移時）

    === 執行流程 ===

    Phase 1: Knowledge Audit（知識盤點 + 代碼調查）
    1. 讀取上述知識文件，每筆標註 [文件]
    2. 使用 Glob/Grep/Read 調查專案程式碼（路徑：{project_path}），標註 [code]
       - Glob: {project_path}/app/models/*相關*.rb
       - Grep: 主題關鍵字 in {project_path}/app/
       - Read: 關鍵 model 的 class 定義、associations、validations、state machine
    3. 重複檢查：所有發現 vs ul.md/business-rules.md 交叉比對
    4. 評估知識完整度（信心度）
    5. 以 DDD 視角分析 Aggregate、Domain Event、Context Mapping
    6. 以 Clean Architecture 視角分析依賴方向（跨域時）
    7. 識別 Knowledge Gaps、矛盾，標註來源
    8. 輸出盤點報告（按來源 [文件]/[code] 分類）

    Phase 2: Deep Interview（深度訪談）
    - 展示盤點報告（含來源標籤）
    - 整理訪談主題清單（來自 Gaps + Conflicts + code 發現）
    - 逐主題訪談，規則：
      * 一次只討論一個主題
      * 追問模式：開放式 → 確認式 → 邊界式 → 追問
      * 不可在同一個 AskUserQuestion 混合多個主題
      * 每個回答記錄為 [用戶]
      * 禁止說「根據一般慣例，通常...」填補空白
      * 禁止 3 輪 Q&A 之前宣稱信心度 >= 70%
    - 退出條件：結構信心度 >= 70% 且 Q&A >= 3 輪

    Phase 3: Proposal（帶來源標註的知識更新提案）
    - 產出每個文件的完整擬寫內容（非摘要）
    - 每個項目標註來源 + 內容信心度
    - [推導] 項目附推理鏈
    - 展示給用戶審閱

    Phase 4: Content Validation（不可跳過的驗證迴圈）⭐
    - 即使信心度很高，仍必須至少 1 輪驗證
    - 逐項詢問「正確/錯誤/需修改」
    - 重點：[推導] 項目、[待確認] 項目、數值/公式
    - 退出條件：信心度 >= 95% + 所有 [推導] 已確認 + 無 [待確認] + 至少 1 輪

    Phase 5: Commit（知識寫入）
    - 內容信心度 >= 95% 後，用戶最終確認
    - 依序更新各文件
    - 更新 Maintenance Log（含來源欄位）
    - 輸出更新摘要

    === 跨域模式特殊處理 ===

    如果有 Related Domains：
    - 額外關注 domain-map.md 的關係定義
    - 識別 domain 間的整合點和資料流
    - 分析 Context Mapping 模式
    - 提案可能包含 Context Mapping 更新、ACL 設計建議

    請開始執行 Phase 1。
  "
)
```

---

## Step 6: 處理完成

curator 執行完成後，輸出摘要：

```markdown
┌──────────────────────────────────────────────────────┐
│ ✅ 知識討論完成                                       │
├──────────────────────────────────────────────────────┤
│ 📁 專案：{project}                                   │
│ 🎯 主題：{topic}                                     │
│ 🏷️ Primary Domain：{primary}                        │
│                                                      │
│ 📊 更新摘要：                                         │
│ • ul.md：新增 {n} 術語，修正 {m} 術語                │
│ • business-rules.md：新增 {n} 規則                   │
│ • strategic/{domain}.md：更新 {sections}             │
│ • tactical/{domain}.md：更新 {sections}              │
│                                                      │
│ 💡 提示：                                             │
│ • 可使用 git diff domains/{project}/ 查看變更       │
│ • 可使用 /knowledge 繼續補充其他主題                 │
└──────────────────────────────────────────────────────┘
```

---

## 注意事項

### 不建立任務記錄

`/knowledge` 與 `/feature`、`/fix` 不同，**不建立任務 JSON**。

原因：domain 文件會透過 git 版控追蹤變更，不需要額外的任務記錄。

### 變更追蹤

- 透過 git commit history 追蹤
- 透過各文件的 Maintenance Log 追蹤（含來源標註）

### 安全守則

- 只修改 `domains/` 目錄下的知識文件
- 所有寫入需要用戶確認
- 不會修改程式碼
