# Agent 模型選擇指南

## 評估標準

| 標準 | Haiku 適合 | Sonnet/Opus 適合 |
|------|-----------|------------------|
| 任務複雜度 | 簡單、規則導向 | 複雜、需要推理 |
| 創造性需求 | 低（模式匹配） | 高（生成代碼） |
| 判斷需求 | 規則判斷 | 模糊判斷 |
| 知識需求 | 一般 | 專家級 |

## Agent 模型建議

| Agent | 建議模型 | 原因 |
|-------|----------|------|
| **style-reviewer** | `haiku` | 規則匹配、命名檢查，不需要深度推理 |
| **risk-reviewer** | `sonnet` | 安全審查需要較強的模式識別和推理 |
| **specist** | `sonnet` | 需求分析需要理解模糊需求、做出判斷 |
| **tester** | `sonnet` | 生成測試需要理解業務邏輯、創造測試案例 |
| **coder** | `sonnet`/`opus` | 實作需要最強的代碼生成能力 |
| **gatekeeper** | `sonnet` | 綜合判斷、整合各方資訊 |
| **curator** | `opus` | DDD 專家、需要深度架構知識 |

## 成本效益分析

| 模型 | 相對成本 | 適用場景 |
|------|----------|----------|
| `haiku` | 1x（最低） | 簡單審查、規則檢查 |
| `sonnet` | 5x | 一般開發任務 |
| `opus` | 15x | 複雜架構、專家級任務 |

## 預期節省

如果 style-reviewer 使用 Haiku：
- Review 階段成本減少約 **20-30%**
- 整體任務成本減少約 **5-10%**

## 配置方式

在 Task tool 呼叫時指定 model 參數：

```
Task(
  subagent_type: "style-reviewer",
  model: "haiku",  // 使用 Haiku 模型
  prompt: "..."
)
```

## 使用建議

1. **預設使用 Sonnet** - 平衡成本和能力
2. **style-reviewer 可用 Haiku** - 節省成本
3. **curator 考慮用 Opus** - 需要最深的專業知識
4. **coder 複雜任務用 Opus** - 確保代碼品質

## 動態調整

根據任務複雜度動態選擇：

| 任務類型 | coder 模型 |
|----------|-----------|
| 簡單 fix | `sonnet` |
| 複雜 feature | `opus` |
| 架構重構 | `opus` |
