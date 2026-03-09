# AI 決策與澄清原則

## 核心原則
- 澄清 > 猜測
- 不確定性識別是專業行為
- 承認不知道比錯誤假設更有價值

## 自信度檢查機制
- 信心度 < 95% → 必須澄清
- 涉及業務邏輯假設 → 立即停止詢問
- 預設值或格式不明 → 先確認再實作

## 澄清範本
當遇到不確定情況時，使用以下格式：
"根據分析，我發現 [具體情況]，但 [不確定點]，請確認應該如何處理？"

---

# 系統環境保護（強制執行）

> **禁止未經許可修改系統環境或依賴套件**

## 禁止操作清單

以下操作**必須先詢問並獲得明確許可**才能執行：

### 套件管理
- `bundle install` / `bundle update` / `gem install`
- `npm install` / `npm update` / `yarn add` / `pnpm add`
- `pip install` / `pip install --upgrade`
- `brew install` / `brew upgrade`

### 系統環境
- 修改 `.ruby-version` / `.node-version` / `.python-version`
- 修改 `rbenv` / `pyenv` / `nvm` 設定
- 修改 shell 設定（`.zshrc`, `.bashrc`）
- 修改環境變數

### 設定檔
- 修改 `Gemfile` / `package.json` / `requirements.txt`
- 修改 `Dockerfile` / `docker-compose.yml`
- 修改 CI/CD 設定（`.github/workflows/`）

## 正確做法

當需要上述操作時，使用以下格式詢問：

```
我發現需要 [操作描述]，原因是 [為什麼需要]。
這會影響：[影響範圍]
請問是否允許執行？
```

## 例外情況

以下操作**不需要**詢問：
- `bundle exec` 執行已安裝的指令
- `npm run` / `yarn run` 執行已定義的 script
- `pytest` / `rspec` / `jest` 執行測試
- 讀取設定檔（不修改）

---

# 專案目錄與版本管理（重要）

> **必須進入專案目錄才能取得正確的語言/框架版本**

各專案使用 `rbenv`、`nvm`、`pyenv` 等版本管理工具，透過專案根目錄的設定檔自動切換版本。專案配置定義於 `.claude/config/projects.yml`。

**在錯誤目錄執行會使用錯誤版本！**

```bash
# 正確 - 先 cd 到專案目錄
cd {project_path} && bundle exec rspec spec/

# 錯誤 - 會使用系統預設版本
bundle exec rspec {project_path}/spec/
```

所有需要執行專案指令的 Agent（tester、coder）在使用 Bash 時：

1. **必須**先 `cd` 到對應專案目錄
2. 使用 `&&` 串接指令確保在正確目錄執行
3. 不要假設當前目錄是專案目錄

---

# ATDD 任務工作流程

> **本專案使用 Command-Driven 工作流程。所有專案任務必須透過 Slash Command 啟動。**

## 命令速查

### 任務啟動
```
/feature {project}, {標題}     # 新功能開發
/fix {project}, {標題}         # Bug 修復
/refactor {project}, {標題}    # 程式碼重構
/test {project}, {標題}        # 建立 E2E 測試套件
```

### 任務控制
```
/continue          # 繼續到下一階段
/status            # 查看當前進度
/abort             # 放棄當前任務
/e2e-manual        # 標記使用人工 E2E 驗證
```

### 結案
```
/done              # Commit + 結案（最常用）
/commit            # 僅 Commit
/close             # 僅結案
```

### 測試套件
```
/test-list {project}                  # 列出測試套件
/test-run {project}, {suite-id}       # 執行測試套件
/test-history {project}, {suite-id}   # 查看執行歷史
/test-edit {project}, {suite-id}      # 修改測試套件
```

### 知識管理
```
/knowledge {project}, {主題描述}              # 知識討論（自動偵測 domain）
```

### Review 後修復
```
/fix-critical      # 修復 Critical 問題
/fix-high          # 修復 Critical + High 問題
/fix-all           # 修復所有問題
```

### /test 執行控制
| 命令 | 說明 | 測試繼續？ |
|------|------|-----------|
| `/test-pause` | 暫停等待人工介入 | 暫停 |
| `/test-resume` | 繼續暫停的測試 | 繼續 |
| `/test-skip` | 跳過當前步驟/場景 | 繼續 |
| `/test-fail` | 標記失敗並停止 | 停止 |
| `/test-fix` | 開 Fix 票並繼續 | 繼續 |
| `/test-fix-stop` | 開 Fix 票並停止 | 停止 |
| `/test-revise` | 修正場景預期（系統正確，測試錯） | 暫停確認 |
| `/test-knowledge` | 測試不該存在，退回 requirement | 停止 (invalid) |
| `/test-feature` | 發現缺少功能，建立 Feature 任務 | 繼續 |
| `/test-refactor` | 發現架構問題，建立 Refactor 任務 | 繼續 |

---

# Context 傳遞機制

> Agent 間的 context 傳遞**不依賴對話記憶**，而是透過任務 JSON 檔案傳遞。

用戶可在任何階段轉移時安全地 `/clear` 清理對話。`/continue` 會自動讀取任務 JSON 恢復狀態。

---

# 架構文檔索引

以下資源由系統在對應時機自動載入，不需要手動讀取：

| 資源 | 位置 | 載入時機 |
|------|------|----------|
| Agent 定義與職責 | `.claude/agents/*.md` | Task tool 生成 agent 時 |
| 命令邏輯 | `.claude/commands/*.md` | Slash command 執行時 |
| 任務 JSON 格式 | `.claude/commands/shared/task-json-template.md` | 命令引用 |
| 階段流程圖 | `.claude/commands/shared/task-flow-diagrams.md` | 命令引用 |
| Agent 呼叫模式 | `.claude/commands/shared/agent-call-patterns.md` | 命令引用 |
| Kanban 操作 | `.claude/commands/shared/kanban-operations.md` | 命令引用 |
| Kanban 卡片模板 | `.claude/templates/kanban-card.md` | 命令引用 |
| 驗收框架 | `acceptance/registry.yml` | Agent 讀取 |
| 風格指南 | `style-guides/*.md` | style-reviewer 讀取 |
| 專案配置 | `.claude/config/projects.yml` | Hooks + 命令讀取 |
| Domain 知識 | `domains/{project}/*.md` | Agent 讀取 |
