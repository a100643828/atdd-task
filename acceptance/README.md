# Acceptance Framework

> 驗收 = 測試 = 確認結果是否正確

本框架定義任務的驗收標準和測試層級，由 tester/coder 在 testing/development 階段執行，gatekeeper 彙總結果。

## 核心概念

### 測試分類

```
┌─────────────────────────────────────────────────────────────┐
│ 分類           │ 性質               │ 存放位置              │
├─────────────────────────────────────────────────────────────┤
│ E2E Tests      │ 單點驗收（任務形態） │ atdd-hub tests/      │
├─────────────────────────────────────────────────────────────┤
│ Integration    │ 防守型城牆（回歸）   │ 各專案 spec/         │
│ Tests          │                     │                      │
├─────────────────────────────────────────────────────────────┤
│ Unit Tests     │ 防守型城牆（回歸）   │ 各專案 spec/         │
└─────────────────────────────────────────────────────────────┘
```

- **E2E**：任務驅動的單點驗收，驗證特定需求/修復是否完成，由 atdd-hub 管理
- **Integration / Unit**：專案層級的回歸測試，每次 CI/CD 自動觸發以卡控品質，存放在各專案 repo 內

## 目錄結構

```
acceptance/                      # 驗收框架定義
├── README.md                    # 本文件
├── registry.yml                 # 驗收配置註冊表（可擴充）
├── templates/                   # 模板檔案
│   ├── fixture.yml              # Fixture 模板
│   ├── test.yml                 # /test 任務主檔案模板
│   ├── scenario.yml             # /test 場景模板
│   └── seed_script.rb.erb       # Seed Script 模板
├── tips/                        # E2E 測試技巧（經驗知識庫）
│   ├── README.md                # Tips 總覽
│   ├── chrome-mcp-tips.md       # Chrome MCP 使用技巧
│   ├── selectors.md             # 選擇器最佳實踐
│   ├── common-issues.md         # 常見問題與解法
│   └── wait-strategies.md       # 等待策略
└── fixtures/                    # 任務驗收資料
    └── {project_id}/
        └── {task_id}.yml

tests/                           # E2E 測試套件（atdd-hub 管理）
└── {project_id}/
    └── suites/{suite-id}/
        ├── suite.yml            # 套件定義
        ├── scenarios/           # 場景詳細步驟
        ├── fixtures/            # setup/cleanup 腳本
        └── runs/                # 執行記錄與錄影

# Integration / Unit 測試存放在各專案 repo 內（非 atdd-hub）
# {project_path}/spec/domains/**/integration/
# {project_path}/spec/domains/**/unit/
```

## 流程

```
requirement → specification → testing → development → review → gate
                                 │           │                   │
                            tester 生成   coder 執行      gatekeeper
                            測試代碼     測試並修復      彙總報告
```

## 使用方式

### 1. Specist 識別 acceptanceProfile

根據需求關鍵字自動識別，寫入任務 JSON：

```json
{
  "acceptance": {
    "profile": "ui",
    "testLayers": {
      "unit": { "required": true },
      "integration": { "required": true },
      "e2e": { "required": true, "executor": "chrome-mcp" }
    }
  }
}
```

### 2. Tester 生成測試

根據 `testLayers` 生成對應測試：
- Unit Tests: RSpec/Jest/Pytest
- Integration Tests: 整合測試
- E2E Tests: Fixture 檔案（供 Chrome MCP 執行）

### 3. Coder 執行測試

執行所有測試，包括使用 Chrome MCP 執行 E2E 測試。

### 4. Gatekeeper 彙總報告

輸出測試結果總覽 + 人類驗收指南。

## 擴充方式

### 新增 Profile

編輯 `registry.yml`，在 `profiles` 區塊新增：

```yaml
profiles:
  new_profile:
    name: "新類型"
    keywords: ["關鍵字1", "關鍵字2"]
    testLayers:
      unit: { required: true }
      # ...
```

### 新增 Executor

編輯 `registry.yml`，在 `executors` 區塊新增：

```yaml
executors:
  new_executor:
    name: "新執行器"
    description: "說明"
    capabilities: [...]
```

## 參考文件

- Profile 定義：`registry.yml`
- Fixture 格式：`templates/fixture.yml`
- Agent 文件：`.claude/agents/`

## E2E 測試技巧

執行 E2E 測試時遇到問題？查閱 `tips/` 目錄：

| 文檔 | 內容 |
|------|------|
| [chrome-mcp-tips.md](tips/chrome-mcp-tips.md) | Chrome MCP 工具使用詳解 |
| [selectors.md](tips/selectors.md) | 選擇器最佳實踐 |
| [common-issues.md](tips/common-issues.md) | 常見問題與解法 |
| [wait-strategies.md](tips/wait-strategies.md) | 等待策略 |
