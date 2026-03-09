# Fix 驗收 Profile 指南

Fix Profile 採用**兩階段分類**：

1. **Fix Profile**（任務建立時決定）— 按問題表象分類，決定初始調查工具
2. **Affected Layer**（調查後確定）— 按架構層分類，決定修復方式與測試類型

機器可讀的完整定義請見：
- `acceptance/fix-profiles.yml` — Fix Profile 與 Affected Layer
- `acceptance/fix-discovery-flows.yml` — 14 個 Discovery Source 調查流程

---

## 7 個 Fix Profile

### ui — 頁面/UI 問題

從頁面發現的顯示或互動問題。

| 項目 | 說明 |
|------|------|
| **問題表象** | 畫面、顯示、按鈕、表單、跑版、CSS、前端 |
| **Discovery Sources** | D1（View Layer）、D2（資料相關）、D3（流程錯誤）、D19（跨瀏覽器/裝置） |
| **可能影響層** | Presentation、Application、Domain |

**調查流程**：

| Source | 流程 |
|--------|------|
| D1 頁面顯示錯誤（View Layer） | Browser → Read Code → (?) 修復 / Git History → (?) 修復 / 返回人類 |
| D2 頁面顯示錯誤（資料相關） | Browser → Read Code → (?) / Server Log → (?) / Rails Runner → (?) / Domain Context → (?) / 詢問 Migrate → Local Debug → (?) / Git History → (?) / 返回人類 |
| D3 頁面流程錯誤 | Browser → Read Spec → Read Code → (?) / Server Log → Domain Context → (?) / Git History → (?) / 返回人類 |
| D19 跨瀏覽器/裝置問題 | Browser(問題環境) → Browser(對照) → Read Code → (?) / Git History → (?) / 返回人類 |

---

### data — 資料問題

從報表或資料庫發現的資料錯誤。

| 項目 | 說明 |
|------|------|
| **問題表象** | 資料、報表、數字、統計、遺失、重複、不一致 |
| **Discovery Sources** | D4（資料面錯誤）、D14（資料重複/遺失） |
| **可能影響層** | Domain、Infrastructure |

**調查流程**：

| Source | 流程 |
|--------|------|
| D4 資料面錯誤 | Read Code → (?) / Rails Runner → Server Log → (?) / Domain Context → (?) / Migrate → Local 並發測試 → (?) / 返回人類 |
| D14 資料重複/遺失 | Read Code → (?) / Rails Runner → (?) / Server Log → (?) / Domain Context → RDS/Redis Log → (?) / Migrate → Local 並發測試 → (?) / 返回人類 |

---

### worker — 背景任務問題

從 Sidekiq/排程介面發現的任務錯誤。

| 項目 | 說明 |
|------|------|
| **問題表象** | Sidekiq、Job、Queue、Worker、排程、背景、非同步 |
| **Discovery Sources** | D5（資料相關）、D6（程式問題） |
| **可能影響層** | Application、Domain、Infrastructure |

**調查流程**：

| Source | 流程 |
|--------|------|
| D5 佇列/排程錯誤（資料相關） | App Status → Error Tracking → Read Code → (?) / Rails Runner → (?) / Server Log → (?) / Domain Context → (?) / Migrate → Local Sidekiq → (?) / Git History → (?) / 返回人類 |
| D6 佇列/排程錯誤（程式問題） | App Status → Error Tracking → Read Code → (?) / Local Sidekiq → Server Log → (?) / Git History → (?) / 返回人類 |

---

### performance — 效能問題

從監控或用戶回報發現的效能問題。

| 項目 | 說明 |
|------|------|
| **問題表象** | 慢、timeout、效能、memory、CPU、N+1、slow query |
| **Discovery Sources** | D8（APM 效能警報）、D9（用戶回報慢） |
| **可能影響層** | Presentation、Application、Domain、Infrastructure |

**調查流程**：

| Source | 流程 |
|--------|------|
| D8 APM 效能警報 | APM → Read Code → (?) / 分支(DB: RDS Log / Ruby: 分析邏輯 / External: Server Log / Memory: 分析邏輯) → (?) / Git History → (?) / 返回人類 |
| D9 用戶回報慢 | Browser → 分支(前端慢: DevTools / 後端慢: APM / 無法重現: Server Log) → Read Code → Local Benchmark → (?) / 返回人類 |

---

### integration — 整合問題

與第三方服務串接相關的錯誤。

| 項目 | 說明 |
|------|------|
| **問題表象** | API、串接、金流、ERP、Webhook、第三方、外部 |
| **Discovery Sources** | D10（外部服務錯誤） |
| **可能影響層** | Infrastructure |

**調查流程**：

| Source | 流程 |
|--------|------|
| D10 外部服務錯誤 | Error Tracking → Server Log → Read Code → (?) / 分支(Request 錯誤 / Response 處理錯誤 / 間歇性: Script 測試連線) → (?) / Domain Context → (?) / 返回人類 |

---

### alert — 監控警報問題

從 Log 或監控系統發現的錯誤。

| 項目 | 說明 |
|------|------|
| **問題表象** | Log、Error、Alert、監控、Rollbar、Sentry |
| **Discovery Sources** | D7（Log 紀錄錯誤） |
| **可能影響層** | Presentation、Application、Domain、Infrastructure |

**調查流程**：

| Source | 流程 |
|--------|------|
| D7 Log 紀錄錯誤 | Server Log → Error Tracking → Read Code → (?) / Rails Runner → (?) / Git History → Read 最近部署 → (?) / 返回人類 |

---

### security — 安全問題

權限錯誤或安全漏洞。

| 項目 | 說明 |
|------|------|
| **問題表象** | 權限、登入、授權、安全、XSS、注入 |
| **Discovery Sources** | D12（權限錯誤）、D13（安全掃描） |
| **可能影響層** | Presentation、Application、Infrastructure |

**調查流程**：

| Source | 流程 |
|--------|------|
| D12 權限錯誤 | Read Code → Read Feature Spec → (?) / Rails Runner → (?) / Domain Context → (?) / 返回人類 |
| D13 安全掃描 | Read Code → 分支(Dependency: 更新需人類確認 / Code: 定位漏洞) → (?) / 返回人類 |

---

## Affected Layer 與測試類型對照

調查確定 Affected Layer 後，決定修復方式與測試類型：

| Affected Layer | 別名 | 測試類型 | 測試重點 |
|----------------|------|----------|----------|
| **Presentation** | View / UI / Frontend | system | 頁面顯示正確、互動行為正確 |
| **Application** | Controller / Use Case / Service | integration | 流程正確執行、錯誤正確處理、權限正確檢查 |
| **Domain** | Model / Business Logic / Entity | unit | 計算結果正確、業務規則符合、邊界條件處理 |
| **Infrastructure** | Repository / Adapter / External | integration | 資料正確存取、外部服務正確呼叫、錯誤正確處理 |

---

## 共通原則

### 信心度門檻

- **信心度 ≥ 95%** → 進行修復
- **信心度 < 95%** → 返回人類，提供調查結果與建議

返回人類時需提供：目前調查結果、已使用的工具和發現、已排除的可能性、無法釐清的具體問題、建議的下一步。

### Production 不可變

- **Query 工具**（Browser、AWS Connect、Read、Error Tracking、APM）— 只讀取，不改變狀態
- **Command 工具**（Write、Bash、Migrate、Git、Debugger）— 可改變狀態，**僅限 Local/Staging**
- 禁止直接寫入 Production 資料庫
- 禁止從 Local/Staging 反向遷移到 Production

### TDD 流程

Fix 任務遵循 TDD 驅動：

```
PreTest（紅燈）→ Fix 實作 → Test（綠燈）
```

1. 根據 Affected Layer 決定測試類型
2. 撰寫 PreTest，預期失敗（紅燈）
3. 修復程式碼
4. 執行測試確認通過（綠燈）
5. 執行相關測試確認無 regression

### 調查流程符號說明

| 符號 | 意義 |
|------|------|
| `→` | 下一步 |
| `(?) 修復` | 如果釐清（信心度 ≥ 95%）則修復 |
| `/` | 否則繼續下一步 |
| `詢問` | 需要人類確認才能執行 |
| `分支(...)` | 根據情況選擇路徑 |
| `返回人類` | 信心度不足，將調查結果回報人類 |
