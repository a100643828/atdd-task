# Fix Investigation

系統性地調查 Bug，整合多種資料來源。

## 使用時機

- Fix 任務的 requirement 階段
- 需要系統性調查 Bug 根因
- 需要整合多種調查工具的結果

## 快速開始

```
使用 fix-investigation skill 來：
1. 識別 Discovery Source（D1-D19）
2. 執行對應的調查流程
3. 彙整調查結果和根因分析
```

## Discovery Sources

| ID | 名稱 | 調查工具 |
|----|------|---------|
| D1 | UI 顯示-靜態 | Browser → Code |
| D2 | UI 顯示-資料 | Browser → Code → Log → Runner |
| D5 | Worker 失敗 | Log → Code → Runner |
| D8 | 效能問題 | APM → Code → Benchmark |

## 相關文件

- [SKILL.md](./SKILL.md) - 完整使用說明
- [fix-discovery-flows.yml](../../../acceptance/fix-discovery-flows.yml) - 調查流程定義
