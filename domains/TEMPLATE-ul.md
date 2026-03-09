# {project_id} Ubiquitous Language (專有名詞表)

> **Purpose**: Define the Ubiquitous Language used across {project_name}. This includes domain terminology, verbs (actions), states, and their semantic relationships to ensure consistent understanding among team members and AI agents.

**Last Updated**: {ISO timestamp}
**Maintained By**: Development Team + atdd-knowledge-curator

---

## How to Use This Glossary

- **For Developers**: Reference when encountering unfamiliar domain terms
- **For AI Agents**: Load before working on domain-specific tasks
- **For Updates**: Use atdd-knowledge-curator to propose additions

---

## A

### {Term}
**中文**: {Chinese term}
**定義**: {Clear definition of what this term means in this domain}
**類型**: [Entity | Value Object | Aggregate | Service | Event | Concept]
**相關 Entity/Component**: {Related code components}
**業務規則**: {Key business rules associated with this term}
**範例**: {Concrete example demonstrating the term}

**注意事項**:
- {Important consideration 1}
- {Important consideration 2}

**相關詞彙**: {Link to related terms}

---

## B

### {Term}
...

---

## C

...

---

## Format Guidelines

### Required Fields
- **中文**: Chinese translation/name
- **定義**: Clear, unambiguous definition
- **類型**: Entity/Value Object/Aggregate/Service/Event/Concept
- **相關 Entity/Component**: Code references

### Optional Fields
- **業務規則**: Business rules (if applicable)
- **範例**: Examples (recommended for complex terms)
- **注意事項**: Important notes, gotchas, common mistakes
- **相關詞彙**: Links to related terms

### Naming Conventions
- Use consistent term casing (PascalCase for entities, camelCase for attributes)
- Include both English and Chinese terms
- Link to actual code files when possible

---

## Maintenance Log

| Date | Change | Changed By |
|------|--------|------------|
| {ISO date} | Initial UL created | {name/agent} |
| {ISO date} | Added term: {TermName} | {name/agent} |
