# Benchmark

本地效能測試和分析工具。

## 使用時機

- Fix 任務（D8/D9）效能問題調查
- Feature 任務效能驗證
- Refactor 任務前後比較

## 支援的測試類型

| 類型 | Ruby | JavaScript |
|------|------|------------|
| 執行時間 | Benchmark | console.time |
| 記憶體 | memory_profiler | - |
| N+1 偵測 | bullet | - |
| HTTP 負載 | ab, wrk | ab, wrk |

## 快速開始

```ruby
# Ruby 執行時間測試
require 'benchmark'
Benchmark.bm { |x| x.report("test") { your_code } }

# HTTP 負載測試
ab -n 100 -c 10 http://localhost:3000/api/endpoint
```

## 相關文件

- [SKILL.md](./SKILL.md) - 完整使用說明
