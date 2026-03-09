# Fix 任務工作流程

> Fix 任務用於修復 Bug，採用簡化流程，重點在於快速定位問題並修復。

## 概述

Fix 任務與 Feature 任務的差異：

| 項目 | Feature | Fix |
|------|---------|-----|
| 流程 | requirement → specification → testing → development → review → gate | requirement → testing → development → review → gate |
| 目標 | 實現新功能 | 修復現有問題 |
| 信心度門檻 | 90% | 80%（快速進入修復） |
| 調查工具 | 無 | 14 個 Discovery Source 流程 |

## 啟動 Fix 任務

```bash
/fix {project_id}, {問題描述}
```

**範例**：
```bash
/fix sf_project, 發票金額顯示 NaN
/fix core_web, 登入頁面在 Safari 無法顯示
```

## Fix 階段流程

```
requirement → testing → development → review → gate
    ↓           ↓           ↓           ↓       ↓
 specist     tester      coder    reviewers  gatekeeper
```

### 1. Requirement 階段（Specist）

Specist 負責：
1. **識別 Discovery Source (Dx)** - 根據問題描述判斷屬於哪個 Dx
2. **執行調查流程** - 依照對應 Dx 的 Tool 流程調查
3. **確認 Affected Layer** - 確定問題位於哪個架構層
4. **達成信心度** - 需達 80% 以上才進入下一階段

### 2. Testing 階段（Tester）

Tester 負責：
1. **撰寫失敗測試** - 根據問題描述撰寫預期失敗的測試
2. **確認測試紅燈** - 測試必須先失敗，證明問題存在
3. **準備驗收標準** - 定義修復後的預期行為

### 3. Development 階段（Coder）

Coder 負責：
1. **修復問題** - 根據調查結果修復程式碼
2. **測試綠燈** - 確認測試通過
3. **回歸測試** - 確認沒有影響其他功能

### 4. Review 階段（Reviewers）

- **Risk Reviewer**：檢查安全/效能/風險
- **Style Reviewer**：檢查程式碼風格（Refactor 任務才需要）

### 5. Gate 階段（Gatekeeper）

Gatekeeper 負責：
1. **最終品質確認**
2. **生成報告**
3. **知識更新建議**

## Discovery Source (Dx) 調查流程

### 流程符號說明

| 符號 | 說明 |
|------|------|
| `→` | 下一步 |
| `(?) 修復` | 如果釐清（信心度 ≥95%）則修復 |
| `/` | 否則繼續下一步 |
| `詢問` | 需要人類確認才能執行 |
| `分支(...)` | 根據情況選擇 |
| `返回人類` | 信心度不足，回報調查結果 |

### UI Profile

| Dx | 名稱 | 流程 |
|----|------|------|
| D1 | 頁面顯示錯誤（View Layer） | Browser → Read Code → (?) 修復 / Git History → (?) 修復 / 返回人類 |
| D2 | 頁面顯示錯誤（資料相關） | Browser → Read Code → (?) 修復 / Server Log → (?) 修復 / Rails Runner → (?) 修復 / Domain Context → (?) 修復 / 詢問 Migrate → Local Debug → (?) 修復 / Git History → (?) 修復 / 返回人類 |
| D3 | 頁面流程錯誤 | Browser → Read Spec → Read Code → (?) 修復 / Server Log → Domain Context → (?) 修復 / Git History → (?) 修復 / 返回人類 |
| D19 | 跨瀏覽器/裝置問題 | Browser(問題環境) → Browser(對照) → Read Code → (?) 修復 / Git History → (?) 修復 / 返回人類 |

### Data Profile

| Dx | 名稱 | 流程 |
|----|------|------|
| D4 | 資料面錯誤 | Read Code → (?) 修復 / Rails Runner → Server Log → (?) 修復 / Domain Context → (?) 修復 / Migrate → Local 並發測試 → (?) 修復 / 返回人類 |
| D14 | 資料重複/遺失 | Read Code → (?) 修復 / Rails Runner → (?) 修復 / Server Log → (?) 修復 / Domain Context → RDS/Redis Log → (?) 修復 / Migrate → Local 並發測試 → (?) 修復 / 返回人類 |

### Worker Profile

| Dx | 名稱 | 流程 |
|----|------|------|
| D5 | 佇列/排程錯誤（資料相關） | App Status → Error Tracking → Read Code → (?) 修復 / Rails Runner → (?) 修復 / Server Log → (?) 修復 / Domain Context → (?) 修復 / Migrate → Local Sidekiq → (?) 修復 / Git History → (?) 修復 / 返回人類 |
| D6 | 佇列/排程錯誤（程式問題） | App Status → Error Tracking → Read Code → (?) 修復 / Local Sidekiq → Server Log → (?) 修復 / Git History → (?) 修復 / 返回人類 |

### Performance Profile

| Dx | 名稱 | 流程 |
|----|------|------|
| D8 | APM 效能警報 | APM → Read Code → (?) 修復 / 分支(DB: RDS Log / Ruby: 分析邏輯 / External: Server Log / Memory: 分析邏輯) → (?) 修復 / Git History → (?) 修復 / 返回人類 |
| D9 | 用戶回報慢 | Browser → 分支(前端慢: DevTools / 後端慢: APM / 無法重現: Server Log) → Read Code → Local Benchmark → (?) 修復 / 返回人類 |

### Integration Profile

| Dx | 名稱 | 流程 |
|----|------|------|
| D10 | 外部服務錯誤 | Error Tracking → Server Log → Read Code → (?) 修復 / 分支(Request 錯誤 / Response 處理錯誤 / 間歇性: Script 測試連線) → (?) 修復 / Domain Context → (?) 修復 / 返回人類 |

### Alert Profile

| Dx | 名稱 | 流程 |
|----|------|------|
| D7 | Log 紀錄錯誤 | Server Log → Error Tracking → Read Code → (?) 修復 / Rails Runner → (?) 修復 / Git History → Read 最近部署 → (?) 修復 / 返回人類 |

### Security Profile

| Dx | 名稱 | 流程 |
|----|------|------|
| D12 | 權限錯誤 | Read Code → Read Feature Spec → (?) 修復 / Rails Runner → (?) 修復 / Domain Context → (?) 修復 / 返回人類 |
| D13 | 安全掃描 | Read Code → 分支(Dependency: 更新需人類確認 / Code: 定位漏洞) → (?) 修復 / 返回人類 |

## 工具分類

### Query Tools（只讀取）

| 工具 | 說明 |
|------|------|
| browser | Chrome 瀏覽器操作 |
| aws_connect.rails_runner | 遠端 Rails Runner（只可查詢） |
| aws_connect.server_log | 遠端 Log 查詢 |
| aws_connect.app_status | Sidekiq/Redis 狀態 |
| aws_connect.rds_log | RDS/Redis Log |
| aws_connect.script | 上傳執行腳本（用完刪除） |
| read.local_codebase | 讀取程式碼 |
| read.domain_context | 讀取 Domain 文件 |
| read.git_history | 讀取 Git 歷史 |
| error_tracking | Sentry/Rollbar（人工操作） |
| apm | NewRelic/Datadog（人工操作） |

### Command Tools（可改變狀態，僅限 Local/Staging）

| 工具 | 說明 |
|------|------|
| write | 修改程式碼 |
| bash.rspec | 執行測試 |
| bash.rails_runner | 本地 Rails Runner |
| bash.sidekiq_local | 本地 Sidekiq |
| bash.benchmark | 本地效能測試（待開發 Skill） |
| migrate | 資料遷移（Production → Local） |
| git_command | Git 寫入操作 |
| debugger | 除錯工具 |

## 核心原則

1. **Production 資料不可變** - 所有 Command 操作僅限 Local/Staging
2. **Rails Runner 必須在 Read Code 之後** - 沒看過 code 怎麼知道要 run 什麼
3. **Git History 放到最後一站** - 用盡所有 debug 方式才質疑 git 版本
4. **信心度 ≥95% 才可修復** - 不確定時返回人類確認

## 返回人類時需提供

當信心度 <95% 需要返回人類時，必須提供：
1. 目前調查結果
2. 已使用的工具和發現
3. 已排除的可能性
4. 無法釐清的具體問題
5. 建議的下一步

## Review 後修復

當 Review 發現問題時，可選擇修復而非直接進入 Gate：

```bash
/fix-critical   # 修復 Critical 問題
/fix-high       # 修復 Critical + High 問題
/fix-all        # 修復所有問題（含 suggestions）
```

修復流程（TDD）：
```
review → testing（補測試）→ development（修復）→ review → gate
```

## 相關文件

- `fix-profiles.yml` - Profile 定義與 Affected Layer
- `fix-tools.yml` - 工具清單（Query/Command 分類）
- `fix-discovery-flows.yml` - 14 個 Discovery Source 調查流程
- `registry.yml` - 驗收配置註冊表
