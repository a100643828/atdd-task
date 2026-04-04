# ATDD Platform Evolution — 設計決策文件

> 此文件記錄 ATDD 從 CLI 工具演進為團隊品質平台的完整設計。
> 用於跨 session 延續開發 context。

## 背景

分析 259 筆任務數據發現：
- Gate 通過率 ≈ 100%，但 **True Completion Rate ≈ 70%**
- Fix : Feature 比 = 1:2（每做 2 個功能就要修 1 次）
- 多個 domain fix rate > 100%（修比做多）
- Fix cascade 現象：修一個壞另一個，連鎖三次
- 知識庫雙向寫入衝突（PM via Slack、Dev via Local）

## 核心架構決策

### Source of Truth 轉移
- **現在**：Git (atdd-hub) 是唯一 source of truth
- **未來**：PostgreSQL (API Server) 為 source of truth，Git 降為 version history + 備份

### API Server 為中央協調點
- 所有寫入透過 API（Slack Bot、Claude Code、Web Dashboard、Cron）
- Claude Code 透過 **ATDD MCP Server** 連接 API
- 知識庫改為 DB 段落級存儲，解決雙向寫入衝突（見 `docs/atdd-server/knowledge-sync-problem.md`）

### Hexagonal Architecture
- Inbound Ports: SlackPort, WebPort, MCPPort, CronPort
- Core: TaskService, DomainHealthService, CausationService, KnowledgeService, ReportService
- Outbound Ports: TaskRepository, KnowledgeRepository, NotificationPort, GitPort, CodeAnalysisPort

### Multi-Organization（多組織支援）
- 最外層 context boundary = Organization（公司 vs 個人 vs 其他）
- Core 不感知 org，org_id 像 request scope 從最外層傳入
- 每個 org 獨立的：projects, tasks, domains, knowledge, reports
- 每個 org 可自訂：gate 標準、health 閾值、部署策略、整合設定
- DB 用 `organizations` 表 + `org_id` FK 隔離
- Dashboard 用 org switcher 切換
- Claude Code MCP 用 `ATDD_ORG` env 指定
- 實作方式：Phase 2 DB schema 加 org_id，Phase 4 Dashboard 加 switcher

```
Organization: "公司"           Organization: "個人"
├─ core_web                   ├─ side-project
├─ sf_project                 ├─ open-source-x
├─ aws_infra                  └─ ...
├─ Server: EC2                ├─ Server: localhost or same EC2
├─ Gate: 嚴格(95%, E2E必要)   ├─ Gate: 輕量(85%, E2E可選)
└─ Team: PM, Dev, Manager     └─ Team: 只有自己
```

### CQRS Lite
- Write Path: Claude Code / Slack Bot → API → PostgreSQL
- Read Path: Dashboard / API → PostgreSQL
- File Sync: DB → File Generator → local files（Claude Code agent 讀取用）
- Git: 保留作為 version history + 備份

---

## Phase 0: 資料地基（不動架構）

### 0-1. Domain Name Normalization ✅ 完成
- Script: `.claude/scripts/domain-normalize.py`
- 統一 19 筆命名不一致的任務 JSON
- Mapping: ErpPeriod→Tools::ErpPeriod, DigiwinErp→Tools::DigiwinErp, Tool::Receipt→Receipt, ProjectManagement→Project::Management, infrastructure→InfrastructureAutomation
- 逗號分隔的多 domain 拆分為 domain + relatedDomains

### 0-2. Task JSON causation 欄位 ✅ 完成
- 更新 `task-json-template.md`：新增 `causation` 欄位
- 更新 `/fix` command：specist 調查階段填寫 causedBy、rootCauseType、discoveredIn
- 欄位設計：
  ```json
  "causation": {
    "causedBy": null | { "taskId": "", "commitHash": "", "description": "" },
    "rootCauseType": "feature-defect|fix-regression|legacy|unknown|environment|dependency",
    "discoveredIn": "production|staging|e2e|review|development",
    "discoveredAt": "",
    "timeSinceIntroduced": ""
  }
  ```

### 0-3. Domain Health Calculator ✅ 完成
- Script: `.claude/scripts/domain-health.py`
- 輸出: `~/atdd-hub/domain-health.json`（1694 行）
- 結果: 35 domains — 🟢 11 healthy, 🟡 21 degraded, 🔴 3 critical
- Top critical: ElectricityAccounting (35), Accounting::AccountsPayable (38)
- Top coupling: DigiwinErp↔ErpPeriod (29), ElecAccounting↔ErpPeriod (18)

### 0-4. Deployed/Verified/Escaped 狀態 ✅ 完成
- 擴充 `task-flow-diagrams.md`：gate → deployed → verified | escaped，含風險分級表
- 擴充 `task-state-update.md`：新增 Event 4/5/6（deployed/verified/escaped）
- 擴充 `workflow-router.sh`：gate 和 deployed 階段顯示新選項
- 新增 `/verify` command：確認 production 正常 → deployed → completed
- 新增 `/escape` command：回報 production 問題 → deployed → escaped，建議建 fix 票
- 檔案移動：active/ → deployed/ → completed/ 或 escaped/
- 向後相容：`/done` 傳統流程不受影響，`/done --deploy` 為新流程

---

## Phase 1: 核心引擎 ✅ 完成

### 1-1. Agent Context Injection ✅ 完成
- specist：Phase 1 Domain 識別後讀取 domain-health.json，degraded/critical 自動警告
- risk-reviewer：新增 Phase 4 Domain Impact Assessment，評估跨域風險
- gatekeeper：新增 Domain Health Gate，影響部署建議（healthy→/done, critical→/done --deploy）

### 1-2. Causation Tracer Script ✅ 完成
- Script: `.claude/scripts/causation-tracer.py`
- 功能：git blame → commit hash → 反查 task JSON（by commitHash 精確匹配 + commit message fuzzy 匹配）
- 用法：`python3 causation-tracer.py <repo-path> <file> <line> [hub-path]`

### 1-3. /domain-diagnose Skill ✅ 完成
- Command: `.claude/commands/domain-diagnose.md`
- 5 階段：任務健康度 → 程式碼品質(RuboCop/Reek/Flog) → 邊界分析 → 命名一致性 → 報告
- 輸出：結構化診斷報告含 Health Card、Code Quality、Boundary Violations、UL Alignment

---

## Phase 2: API Server + DB ✅ 完成

### 2-1. PostgreSQL Schema ✅ 完成
- Migration: `server/db/migrations/001_initial.sql`
- Runner: `server/db/migrate.py`（plain SQL, no ORM — 語言中立）
- Multi-org: 所有 tenant 表含 `org_id`，seed default org `personal`
- Tables: organizations, tasks, task_history, task_metrics, domains, domain_couplings, knowledge_entries, knowledge_terms, reports
- Auto `updated_at` triggers, composite indexes

### 2-2. FastAPI Application ✅ 完成
- Directory: `server/api/`
- DB: `db.py`（psycopg2 connection pool, raw SQL）
- Routers: `tasks.py`, `domains.py`, `reports.py`
- Endpoints: CRUD + upsert + history + metrics
- Docker: `server/api/Dockerfile`, auto-migrate on startup

### 2-3. Data Migration ✅ 完成
- Script: `server/db/import_data.py`
- Dry-run verified: 259 tasks, 973 knowledge entries, 55 domain health entries
- Supports: `--dry-run`, `--tasks-only`, `--knowledge-only`, `--health-only`
- Parses: task JSON fields, UL terms, markdown sections, domain-health.json

### 2-4. Slack Bot 切換 ✅ 完成（dual-write）
- `bot/api_client.py`: HTTP client for API（stdlib only, no extra deps）
- `bot/app.py`: BA 確認後 dual-write（file + API sync）
- API health check on startup
- Non-fatal: API sync 失敗不影響主流程（漸進遷移）
- `git_sync.py` 保留（GitHub 備份仍需要）

### Infrastructure
- `docker-compose.yml`: 加入 `db` (PostgreSQL 16) + `api` service
- `nginx.conf`: `/api/` proxy 到 api service
- `.env.example`: 加入 DATABASE_URL

---

## Phase 3: ATDD MCP Server ✅ 完成

### 3-1. MCP Server 開發 ✅ 完成
- Directory: `server/mcp/`
- Python MCP Server (FastMCP)，透過 HTTP 連接 API Server
- 22 Tools: atdd_task_* (7), atdd_domain_* (4), atdd_knowledge_* (7), atdd_report_* (3), atdd_health (1)
- `.mcp.json` 設定 MCP Server（venv with Python 3.13）
- API 補齊：新增 knowledge router（entries CRUD + terms upsert）

### 3-2. Skill/Command 遷移 ✅ 完成
- DB Migration: 擴充 `task_status` enum，加入 ATDD pipeline 名稱（requirement, specification, testing, development, review, failed）
- Migration runner: 支援 `ALTER TYPE ... ADD VALUE`（autocommit mode）
- Dual-Write 架構：MCP tools 為主寫入路徑，本地 JSON 保留給 subagent 讀取
- Shared modules 遷移（最高槓桿）：
  - `task-json-template.md`：任務建立改用 `atdd_task_create` → DB 產生 UUID
  - `task-state-update.md`：6 個事件全部加入 MCP 同步（`atdd_task_update` + `atdd_task_add_history`）
- Create commands（feature/fix/refactor）：Step 5 Jira 回寫加 MCP sync
- Read commands（continue/status/done/close/abort/escape/verify）：任務發現改用 `atdd_task_list`，保留 local fallback
- Utility commands（commit/e2e-manual）：加 MCP sync
- Agent prompt（agent-call-patterns）：加入 `任務 DB ID` 欄位（Phase 3-3 準備）
- Agent 知識讀取遷移：
  - `knowledge/access/reader.md`：所有讀取操作加入 MCP 優先路徑（atdd_term_list, atdd_knowledge_list, atdd_domain_list, atdd_coupling_list）
  - `specist.md`：Phase 1 UL 術語用 atdd_term_list，Domain Health 用 atdd_domain_list；Phase 2 規則/strategic/tactical 用 atdd_knowledge_list
  - `gatekeeper.md`：Domain Health Gate 用 atdd_domain_list
  - coder/tester：知識讀取較少，domain-map 未入 DB，維持 local
- File Generator：`server/mcp/file_generator.py` — DB → local JSON 同步腳本
  - 支援：`--project`, `--task`, `--all`, `--dry-run`
  - Status → directory 自動映射（active/deployed/completed/failed/escaped）
  - 自動清理舊目錄（任務狀態變更時移除舊位置的檔案）

---

## Phase 4: Web Dashboard ✅ 完成

### 4-1. 技術棧
- FastAPI + Jinja2 + HTMX + Chart.js + PicoCSS（全 CDN，無 npm build）
- HTMX partial swap（偵測 `HX-Request` header）
- 部署到現有 Nginx（`/dashboard` + `/static/` proxy）

### 4-2. 架構
- `server/api/routers/views.py`：5 個頁面路由 + task detail modal，直接查 DB（不走 HTTP API）
- `server/api/templates/`：Jinja2 模板（base + 5 pages + partials）
- `server/api/static/`：CSS + JS（dashboard.css, charts）
- Status → Kanban column 映射：14 個 DB status 對應 8 個 column，定義在 `views.py` 常數

### 4-3. 頁面（5 個）
1. **Executive Overview** (`/dashboard/`)：交付/品質/成本指標、週趨勢 line chart、成本 bar chart、時間/專案篩選
2. **Domain Health Map** (`/dashboard/domains`)：CSS Grid heatmap（green/yellow/red）、coupling table、點擊 drill-down
3. **Task Board** (`/dashboard/tasks`)：Kanban 8 欄（Requirement→Completed）、專案/類型篩選、點擊 task 開 modal 顯示 history timeline
4. **Causation Explorer** (`/dashboard/causation`)：Fix 任務表（root cause type + discovered in + caused by link）、fix-regression 標記、摘要統計
5. **Domain Diagnostic** (`/dashboard/domains/{name}`)：Health radar chart、fix timeline、knowledge doughnut、recent tasks table、coupling relationships

### 4-4. 未做（Phase 5 範圍）
- SSE 即時更新（目前用 HTMX 輪詢）
- 認證 + 角色權限
- Org switcher

---

## Phase 5: 智慧閉環 ✅ 完成

### 5-1. 週報自動產生 ✅ 完成
- Script: `server/worker/weekly_report.py`
- DB 聚合計算：交付（completed/created by type, cycle time）、品質（escape rate, true completion rate）、成本（tokens by type, fix cost ratio）、domain hotspots
- 輸出格式：text（Slack 用）、JSON（API 用）
- CLI: `--week 2026-W14 --project core_web --save --all-projects`
- API trigger: `POST /api/v1/workers/weekly-report`
- Cron: 每週一 8:00 自動執行

### 5-2. Deployed Auto-Verify ✅ 完成
- Script: `server/worker/auto_verify.py`
- 風險分級自動判斷：domain health status + task type + explicit riskLevel
- Low risk: 7 天無 fix 票自動 verified
- Medium risk: 14 天自動 verified
- High risk: 不自動，超 14 天 Slack 提醒
- 檢查 causation.causedBy 是否有相關 fix 票
- API trigger: `POST /api/v1/workers/auto-verify`
- Cron: 每日 9:00

### 5-3. Domain Health 自動重算 ✅ 完成
- Script: `server/worker/domain_health_recalc.py`
- 從 DB 聚合計算：fix rate, coupling, change freq, knowledge coverage, escape rate
- Upsert 到 domains 表 + 重算 coupling pairs
- API trigger: `POST /api/v1/workers/domain-health`
- Cron: 每日 2:00

### 5-4. SSE 即時更新 ✅ 完成
- Router: `server/api/routers/events.py`
- SSE endpoint: `GET /api/v1/events/stream`
- Events: task.updated, task.created, domain.recalculated, report.generated, deploy.verified, deploy.alert
- Dashboard `base.html` 自動訂閱，收到事件後 HTMX partial refresh
- Toast notification（5 秒自動消失）

### 5-5. Worker Trigger API ✅ 完成
- Router: `server/api/routers/workers.py`
- `POST /api/v1/workers/weekly-report` — 觸發週報
- `POST /api/v1/workers/auto-verify` — 觸發 auto-verify
- `POST /api/v1/workers/domain-health` — 觸發 health 重算
- 每個 trigger 自動 broadcast SSE event

### 5-6. Docker Compose Worker Service ✅ 完成
- `docker-compose.yml` 加入 `worker` service
- Cron schedule: auto-verify(每日9am), domain-health(每日2am), weekly-report(每週一8am)

### 5-7. 未做（未來擴展）
- 認證 + 角色權限（PM/Dev/Manager/Client）
- Org switcher（multi-org dashboard 切換）
- 靜態分析整合（RuboCop/Reek/Flog/Packwerk — 已有 /domain-diagnose skill 框架）
- Escape rate 回饋 → 自動校準 gate 標準
- 多專案對比分析

---

## 技術選型

| 元件 | 選擇 | 理由 |
|------|------|------|
| API | FastAPI | 已有 Python server，async 支援 |
| DB | PostgreSQL | 多人 concurrent writes，JSONB 欄位 |
| Frontend | HTMX + Jinja2 + Chart.js | 不需 npm build，server-rendered |
| 即時更新 | SSE | 單向推送，比 WebSocket 簡單 |
| Claude Code 整合 | MCP Server | 原生整合，雙向 |
| 部署 | Docker Compose on EC2 | 現有基礎設施 |

## Domain Health Score 公式

| 維度 | 權重 | 計算 |
|------|------|------|
| Fix Rate | 30% | fix_count / feature_count |
| Coupling Rate | 25% | cross_domain_tasks / total_tasks |
| Change Frequency | 15% | 近 30 天任務數 / 總任務數 |
| Knowledge Coverage | 15% | 有知識文件 / 應有知識文件 |
| Escape Rate | 15% | discoveredIn=production / total |

閾值：healthy >= 70, degraded 40-69, critical < 40

---

## Docker Compose 最終形態

```yaml
services:
  db:        # PostgreSQL 16
  api:       # FastAPI (REST API + Dashboard + MCP Server)
  bot:       # Slack Bot (改為呼叫 API)
  worker:    # Background jobs (health calc, auto-verify, reports)
  nginx:     # Reverse proxy (/api, /dashboard, /mcp)
```
