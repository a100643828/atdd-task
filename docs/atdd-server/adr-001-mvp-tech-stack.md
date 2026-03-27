# ADR-001: ATDD Server MVP 技術選型

**Status:** Accepted
**Date:** 2026-03-25
**Updated:** 2026-03-25 (AI 引擎從 SDK 改為 CLI)

## Context

ATDD 框架目前完全運行在 local CLI（Claude Code），只有開發者能用。
需要建立 atdd-server，讓 PM 在 Slack 發起任務、需求對話、知識管理，Dev 從 local 接棒開發。

### 架構

```
PM (Slack) → Slack Bot → spawn Claude CLI → parse output → Slack reply
                              ↑ cwd = atdd-hub
                              ↑ --resume $session_id（多輪對話）
Dev (Local CLI) → Server API ─┘
                               ↓
                         atdd-hub (GitHub private repo)
```

## Decisions

### 1. AI 引擎：Claude CLI (Max subscription)

**選擇原因：**
- 已有 Max 月費方案，不需額外 API 費用
- CLI `--print` + `--output-format stream-json` 支援非互動式呼叫
- CLI `--resume $session_id` 支援多輪對話
- CLI 在 cwd 下自動讀取 CLAUDE.md，與 local 開發體驗一致
- 已有 OpenClaw 串接 CLI 的實戰經驗

**呼叫模式：**
```bash
# 首輪：取得 session_id（在 atdd-hub 目錄下，自動讀 CLAUDE.md）
claude -p "需求描述..." --model claude-sonnet-4-6 --output-format stream-json

# 後續輪次：resume
claude --resume $session_id -p "PM 的回覆" --output-format stream-json
```

**驗證結果：**
- EC2 乾淨環境下 `claude -p` + Max 訂閱 ✓
- Local 多帳號環境會衝突，Server 單帳號無此問題

**排除方案：**
- Claude Agent SDK (API key)：需額外付費，且 CLI 已能滿足需求
- CrewAI / LangGraph：額外框架，增加複雜度
- OpenClaw：太重，個人助手定位，自建更輕量可控

### 2. Bot 語言：Python

**選擇原因：**
- Slack Bolt (Python) PoC 已驗證通過
- subprocess 呼叫 CLI + parse stream-json 很直覺
- 生態最大，文件最多

**排除方案：**
- TypeScript / Ruby：無明顯優勢

### 3. Dev 同步機制：Git Remote + Server API

**選擇原因：**
- Server 是 atdd-hub 的 single writer（PM 任務）
- Dev git pull 取得最新任務、需求、知識文件
- Dev 透過 Server API 做狀態變更（done, abort）
- Dev local 任務不進 server 視野（MVP 簡化）
- 零 conflict 風險

**資料流：**
```
Server → git commit + push → GitHub (atdd-hub) ← git pull ← Dev
  ↑                                                           │
  └──────────── API（狀態變更：done, abort）──────────────────┘
```

### 4. 部署方式：EC2 + Docker Compose

**選擇原因：**
- EC2 已開好（i-0ea3db0e802d2a4de, t4g.small, ap-northeast-1）
- HTTPS 已設定（atdd.sunnyfounder.com, Let's Encrypt）
- Docker Compose 簡單直覺，好 debug
- MVP 階段不需要自動擴展

**排除方案：**
- ECS Fargate：MVP 不需要
- PaaS (Railway/Render)：限制多、成本不透明

### 5. 資料保存：JSON + Git

**選擇原因：**
- 現有 task JSON 結構不用改
- 資料量極小（~3.5MB / 475 檔）
- Git 提供版本歷史和 audit trail
- Phase 7 再評估是否升級 DB

## Task State Machine（Server 擴展）

```
PM 任務流程（新增狀態以 * 標記）：
  requirement → specification → *pending_dev → testing → development
  → review → gate → *pending_acceptance → *accepted → [knowledge] → completed
                                        → *rejected → Dev 修改 → *pending_acceptance

Dev local 任務（不變）：
  requirement → specification → testing → development → review → gate → completed
```

向下相容：`task.ownership.createdBy == "pm"` 才走新流程。

## Consequences

- 綁定 Claude Max 訂閱（需保持月費）
- CLI subprocess 比 SDK 略粗糙，但已有 OpenClaw 實戰驗證
- Python 不是團隊主力語言（Ruby），但 server 是獨立服務，影響有限
- JSON + Git 在高併發場景有限制，Phase 7 評估
- EC2 需要手動運維，Phase 7 評估 PaaS 遷移

## Future Evaluation (Phase 7)

- Claude Agent SDK 替代 CLI（如果 API 費用合理或免費額度足夠）
- Jira MCP Server 整合（Atlassian 官方 MCP server 已就緒）
- DB 替代 JSON+Git
- PaaS 遷移
