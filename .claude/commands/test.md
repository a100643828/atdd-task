---
description: 啟動獨立 E2E 測試任務
---

# Test: $ARGUMENTS

> **此命令為 `/test-create` 的別名**

## 說明

`/test` 用於建立新的 E2E 測試套件。

建立後可透過 `/test-run` 重複執行。

---

## 使用方式

```
/test {project}, {測試標題}
```

等同於：
```
/test-create {project}, {測試標題}
```

---

## 相關命令

| 命令 | 說明 |
|------|------|
| `/test-create` | 建立新測試套件（完整說明） |
| `/test-list` | 列出專案的測試套件 |
| `/test-run` | 執行測試套件 |
| `/test-history` | 查看執行歷史 |

---

## 執行控制（測試進行中）

| Command | 繼續？ | Fix 票？ |
|---------|--------|----------|
| `/test-pause` | ⏸️ | ❌ |
| `/test-resume` | ✅ | ❌ |
| `/test-skip` | ✅ | ❌ |
| `/test-fail` | ❌ | ❌ |
| `/test-fix` | ✅ | ✅ |
| `/test-fix-stop` | ❌ | ✅ |

---

## 詳細流程

請參考 `/test-create` 命令說明。
