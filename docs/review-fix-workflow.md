# Review 後修復流程設計

本文檔描述當 Review 階段發現問題時，如何透過 TDD 流程進行修復，以及 Agent 之間的知識傳遞機制。

---

## 目錄

1. [設計背景](#設計背景)
2. [流程概覽](#流程概覽)
3. [Commands 定義](#commands-定義)
4. [reviewFindings 資料結構](#reviewfindings-資料結構)
5. [Agent 知識傳遞](#agent-知識傳遞)
6. [實作範例](#實作範例)

---

## 設計背景

### 問題

原本的流程在 Review 階段完成後，只有 `/continue` 一個選項進入 Gate 階段。但 Review 可能發現需要修復的問題，原流程沒有處理這個分支。

### 目標

1. 提供多種修復選項（依問題嚴重程度）
2. 使用 TDD 流程修復（先補測試，再實作）
3. 透過任務 JSON 傳遞知識，避免 Agent 間的知識損耗

---

## 流程概覽

```
                    review 完成
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
   /continue        /fix-critical    /fix-all
         │               │               │
         ▼               │               │
       gate              │               │
                         ▼               ▼
                  ┌────────────────────────┐
                  │  更新 fixScope         │
                  │  回到 testing 階段     │
                  └──────────┬─────────────┘
                             │
                             ▼
                  ┌────────────────────────┐
                  │  tester 補測試         │
                  │  讀取 reviewFindings   │
                  │  生成失敗測試（紅燈）   │
                  └──────────┬─────────────┘
                             │
                             ▼
                  ┌────────────────────────┐
                  │  coder 修復            │
                  │  讀取 reviewFindings   │
                  │  實作讓測試通過        │
                  └──────────┬─────────────┘
                             │
                             ▼
                  ┌────────────────────────┐
                  │  回到 review           │
                  │  (簡化審查)            │
                  └──────────┬─────────────┘
                             │
                             ▼
                           gate
```

### 階段說明

| 步驟 | 階段狀態 | Agent | 說明 |
|------|----------|-------|------|
| 1 | review → testing | - | 設定 fixScope，更新 status |
| 2 | testing | tester | 讀取 reviewFindings，補充測試 |
| 3 | development | coder | 讀取 reviewFindings + 測試，修復 |
| 4 | review | risk-reviewer | 簡化審查（只驗證修復項目）|
| 5 | gate | gatekeeper | 最終品質把關 |

---

## Commands 定義

### /fix-critical

修復 severity 為 `critical` 的問題。

**行為**：
1. 設定 `context.reviewFindings.fixScope = "critical"`
2. 更新 `status = "testing"`
3. 呼叫 tester agent

**適用場景**：安全漏洞、資料完整性問題

---

### /fix-high

修復 severity 為 `critical` 和 `high` 的問題。

**行為**：
1. 設定 `context.reviewFindings.fixScope = "high"`
2. 更新 `status = "testing"`
3. 呼叫 tester agent

**適用場景**：包含效能問題、N+1 查詢

---

### /fix-all

修復所有 severity 的問題（包含 suggestions）。

**行為**：
1. 設定 `context.reviewFindings.fixScope = "all"`
2. 更新 `status = "testing"`
3. 呼叫 tester agent

**適用場景**：全面改善代碼品質

---

## reviewFindings 資料結構

### 完整結構

```json
{
  "context": {
    "reviewFindings": {
      "fixScope": null,
      "styleReview": {
        "score": "92/100",
        "grade": "A",
        "issues": [],
        "suggestions": [
          {
            "id": "STYLE-001",
            "severity": "suggestion",
            "category": "readability",
            "file": "repositories/accounts_receivable.rb",
            "line": "71-88",
            "title": "複雜條件邏輯",
            "description": "should_clear_invoice_number? 邏輯較複雜",
            "suggestion": "可提取部分子條件為命名方法",
            "example": null
          }
        ]
      },
      "riskReview": {
        "riskLevel": "High",
        "findings": [
          {
            "id": "SEC-001",
            "severity": "critical",
            "category": "security",
            "file": "use_cases/void_current_invoice.rb",
            "line": "7-14",
            "title": "缺乏授權控制",
            "description": "任何人知道 serial 就能作廢發票",
            "impact": "水平/垂直越權風險",
            "suggestion": "加入 current_user 參數，檢查權限",
            "example": "yield authorize_user(receivable, current_user)",
            "testHint": "測試不同角色、不同專案的權限"
          },
          {
            "id": "SEC-002",
            "severity": "critical",
            "category": "concurrency",
            "file": "use_cases/void_current_invoice.rb",
            "line": "7-14",
            "title": "併發控制不足",
            "description": "可能產生 Race Condition",
            "suggestion": "加入 Redis Lock 或 Optimistic Locking",
            "example": "with_redis_lock(lock_key) { ... }",
            "testHint": "使用 Thread 模擬同時作廢"
          },
          {
            "id": "SEC-003",
            "severity": "critical",
            "category": "validation",
            "file": "use_cases/void_current_invoice.rb",
            "line": "8",
            "title": "輸入驗證缺失",
            "description": "void_reason 未驗證",
            "suggestion": "驗證不為空、長度限制 5-500 字元",
            "example": "return Failure('作廢原因不可為空') if void_reason.blank?",
            "testHint": "測試空值、超長字串、特殊字元"
          }
        ]
      }
    }
  }
}
```

### 欄位說明

| 欄位 | 類型 | 說明 |
|------|------|------|
| `fixScope` | string | 修復範圍：`null`/`critical`/`high`/`all` |
| `severity` | string | 嚴重程度：`critical`/`high`/`medium`/`low`/`suggestion` |
| `category` | string | 問題類別：`security`/`concurrency`/`validation`/`performance`/`readability` |
| `file` | string | 問題所在檔案（相對於 domain） |
| `line` | string | 問題所在行數 |
| `title` | string | 問題標題（簡短） |
| `description` | string | 問題描述（詳細） |
| `impact` | string | 影響說明（optional） |
| `suggestion` | string | 修復建議 |
| `example` | string | 程式碼範例（optional） |
| `testHint` | string | 測試建議（給 tester 用）|

### Severity 篩選邏輯

| fixScope | 包含的 severity |
|----------|-----------------|
| `critical` | critical |
| `high` | critical, high |
| `all` | critical, high, medium, low, suggestion |

---

## Agent 知識傳遞

### Tester Agent

當進入 testing 階段（修復模式）時，tester 的 prompt：

```
專案：{project}
任務：補充測試案例以覆蓋 review 發現的問題
任務 JSON：{task_json_path}
模式：fix-review

請執行：
1. 讀取任務 JSON 的 context.reviewFindings
2. 根據 fixScope 篩選要處理的問題
3. 為每個問題生成測試案例
   - 使用 testHint 作為測試設計參考
   - 測試應該先失敗（紅燈）
4. 執行測試確認失敗
5. 更新 context.testFiles 加入新測試檔案

輸出格式請遵循 tester agent 的標準格式。
```

### Coder Agent

當進入 development 階段（修復模式）時，coder 的 prompt：

```
專案：{project}
任務：修復 review 發現的問題，讓測試通過
任務 JSON：{task_json_path}
模式：fix-review

請執行：
1. 讀取任務 JSON 的 context.reviewFindings
2. 讀取 context.testFiles 了解測試案例
3. 根據 fixScope 篩選要修復的問題
4. 依序修復每個問題
   - 使用 suggestion 和 example 作為實作參考
   - 確保測試通過
5. 更新 context.modifiedFiles

輸出格式請遵循 coder agent 的標準格式。
```

### 知識流向圖

```
┌─────────────────┐
│ risk-reviewer   │
│ style-reviewer  │
└────────┬────────┘
         │ 寫入 reviewFindings
         ▼
┌─────────────────┐
│ Task JSON       │
│ (context)       │
└────────┬────────┘
         │ 讀取 reviewFindings
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│tester │ │coder  │
└───────┘ └───────┘
```

---

## 實作範例

### 範例：修復授權控制問題

#### 1. reviewFindings 內容

```json
{
  "id": "SEC-001",
  "severity": "critical",
  "category": "security",
  "file": "use_cases/void_current_invoice.rb",
  "line": "7-14",
  "title": "缺乏授權控制",
  "description": "任何人知道 serial 就能作廢發票",
  "suggestion": "加入 current_user 參數，檢查權限",
  "example": "yield authorize_user(receivable, current_user)",
  "testHint": "測試不同角色、不同專案的權限"
}
```

#### 2. tester 生成的測試

```ruby
# spec/domains/accounting/accounts_receivable/use_cases/void_current_invoice_spec.rb

describe 'Scenario: 授權控制 (SEC-001)' do
  describe '當用戶沒有專案權限' do
    let(:other_project_user) { create(:user, :accountant) }

    it '返回失敗結果' do
      result = use_case.call(
        serial: 'AR-2025-001',
        void_reason: '測試作廢',
        current_user: other_project_user
      )

      expect(result).to be_failure
      expect(result.failure).to eq('無權限操作此專案')
    end
  end

  describe '當用戶角色不允許作廢' do
    let(:viewer_user) { create(:user, :viewer) }

    it '返回失敗結果' do
      result = use_case.call(
        serial: 'AR-2025-001',
        void_reason: '測試作廢',
        current_user: viewer_user
      )

      expect(result).to be_failure
      expect(result.failure).to eq('無權限作廢發票')
    end
  end
end
```

#### 3. coder 實作的修復

```ruby
# domains/accounting/accounts_receivable/use_cases/void_current_invoice.rb

def steps(serial:, void_reason:, current_user:)
  receivable = yield retrieve_receivable(serial: serial)
  yield authorize_user(receivable: receivable, user: current_user)  # 新增
  yield validate_input(void_reason: void_reason)
  yield check_erp_settlement(serial: serial)
  # ...
end

private

def authorize_user(receivable:, user:)
  # 檢查專案權限
  project = Project.find_by(serial: receivable.project_serial)
  return Failure('無權限操作此專案') unless user.can_manage?(project)

  # 檢查角色權限
  return Failure('無權限作廢發票') unless user.has_role?(:accountant, :admin)

  Success()
end
```

---

## 設計原則

### 1. 單一資訊來源

reviewFindings 是唯一的知識傳遞媒介，所有 Agent 都從 Task JSON 讀取。

### 2. TDD 流程

修復必須先有測試（紅燈），再實作（綠燈），確保修復品質。

### 3. 可追蹤性

每個問題都有唯一 ID（如 SEC-001），可追蹤修復狀態。

### 4. 漸進式修復

透過 fixScope 控制修復範圍，可選擇只修復 Critical 或全部修復。

---

## 相關文件

- [continue.md](.claude/commands/continue.md) - 階段轉移邏輯
- [tester.md](.claude/agents/tester.md) - Tester Agent 定義
- [coder.md](.claude/agents/coder.md) - Coder Agent 定義
- [operation-manual.md](docs/operation-manual.md) - 操作手冊
