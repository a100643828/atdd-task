# Mock 使用指南

## 避免過度 Mock

過度 mock 會導致測試通過但實際執行失敗。

## Mock 規則

| 情況 | 可否 Mock | 說明 |
|------|-----------|------|
| 外部 API | ✅ 應該 Mock | 避免依賴外部服務 |
| 時間 (`Time.now`) | ✅ 可以 Mock | 確保測試可重現 |
| Repository | ⚠️ 謹慎 | 至少要有一個真實測試 |
| Domain Entity | ❌ 不要 Mock | 直接使用真實物件 |
| 核心業務邏輯 | ❌ 不要 Mock | 這正是要測試的東西 |

## 測試結構範例

```ruby
RSpec.describe SomeUseCase do
  # 初始化測試（避免過度 mock）
  describe '初始化' do
    it '可以使用預設值初始化' do
      expect { described_class.new }.not_to raise_error
    end
  end

  # 驗收測試（至少一個真實依賴測試）
  describe '驗收測試', :acceptance do
    let(:use_case) { described_class.new }  # 使用預設依賴

    it '完整流程驗收' do
      result = use_case.call(valid_params)
      expect(result).to be_success
    end
  end

  # 邊界情況測試（可以用 mock）
  describe '邊界情況' do
    let(:repository) { instance_double(SomeRepository) }
    let(:use_case) { described_class.new(repository: repository) }

    # ... 用 mock 測試各種情境
  end
end
```

## 失敗分析類型

| Failure Type | Indicators | Typical Fix |
|--------------|------------|-------------|
| Assertion | `expected X, got Y` | Logic error in implementation |
| Mock/Stub | `undefined method`, `not stubbed` | Missing or incorrect mock |
| Setup | `nil`, `not found` | Factory/fixture issue |
| Async | `timeout`, `pending` | Missing await/async handling |
| Time | `freeze_time not working` | Missing ActiveSupport::Testing::TimeHelpers |
