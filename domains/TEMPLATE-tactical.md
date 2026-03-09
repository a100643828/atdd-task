# {DomainName} — 系統設計

> **Domain**: {DomainName}
> **Project**: {project_id}
> **Last Updated**: {ISO timestamp}

## Domain Model

### Aggregates
#### Aggregate: {AggregateName}
**Aggregate Root**: {RootEntityName}
**Purpose**: {purpose}
**Consistency Boundary**: {boundary}
**Components**: (含欄位、型別)
**Invariants**: (不變式)
**Code Location**: `{path}`

### Entities
#### Entity: {EntityName}
**Identity**: {id strategy}
**Attributes**: (含型別)
**Lifecycle**: {create/modify/delete}
**Code Location**: `{path}`

### Value Objects
#### Value Object: {ValueObjectName}
**Purpose**: {purpose}
**Format/Values**: {format or values}
**Code Location**: `{path}`

### Domain Services
#### Service: {ServiceName}
**Purpose**: {purpose}
**Code Location**: `{path}`

## Use Cases
| UseCase | 狀態變化 | 說明 |

## 狀態轉移實作
| From | To | Trigger UseCase | Side Effects |

## Integration 技術細節
### Upstream
| Domain | Integration Method | Failure Handling |
### Downstream
| Domain | What We Provide | Method |

## Patterns & Anti-Patterns
### Pattern: {Name}
**Where**: {Code Location}
**Why**: {reason}
### Anti-Pattern: {Name}
**Problem / Alternative**

## Common Pitfalls
### Pitfall: {description}
**Symptom / Cause / Solution**

## Testing Guidelines
## Performance Considerations

## Related Documentation
- **Domain Code**: `{path}`
- **Tests**: `{path}`

## Change History
| Date | Change | Changed By | Reason |
