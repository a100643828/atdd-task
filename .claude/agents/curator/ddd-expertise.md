# DDD 專業知識

## Strategic Design

### Bounded Context
明確的領域邊界，每個 Context 有自己的 Ubiquitous Language。

### Context Mapping
Bounded Context 之間的關係和整合模式。

### Ubiquitous Language
在特定 Bounded Context 內統一使用的領域語言。

## Tactical Design

| 概念 | 說明 |
|------|------|
| **Aggregate** | 一致性邊界，包含 Root 和內部 Entities |
| **Entity** | 有唯一識別碼，狀態可變 |
| **Value Object** | 不可變，由值定義相等性 |
| **Domain Service** | 無狀態的領域操作 |
| **Domain Event** | 領域中發生的重要事件 |
| **Repository** | Aggregate 的持久化介面 |

## Context Mapping Patterns

| 模式 | 描述 | 適用場景 |
|------|------|----------|
| **Customer-Supplier** | 上游提供服務，下游消費 | 明確的服務關係 |
| **Conformist** | 下游直接使用上游模型 | 無法影響上游時 |
| **Anti-Corruption Layer** | 下游透過翻譯層保護自己 | 需要隔離外部變化 |
| **Shared Kernel** | 小型共享模型 | 謹慎使用，耦合高 |
| **Partnership** | 互相依賴的演進 | 團隊緊密合作 |
| **Published Language** | 穩定發布的標準模型 | 對外公開的 API |

## DDD 分析檢查點

盤點時需要分析：
- [ ] Aggregate 邊界是否明確？
- [ ] Entity vs Value Object 分類是否正確？
- [ ] Domain Event 是否已識別？
- [ ] Ubiquitous Language 是否一致？
- [ ] Context Mapping 關係是否清楚？

## DDD 問題範例

```
- {Entity} 應該是 Aggregate Root 還是屬於其他 Aggregate？
- {Concept} 應該建模為 Entity（有 ID）還是 Value Object（不可變）？
- 當 {Event} 發生時，需要觸發哪些 Domain Event？
- {DomainA} 和 {DomainB} 之間的關係是 Customer-Supplier、ACL、還是 Shared Kernel？
```
