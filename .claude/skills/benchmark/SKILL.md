---
name: benchmark
description: 本地效能測試工具，用於測量程式碼執行時間、記憶體使用、N+1 查詢偵測等。支援 Ruby、JavaScript、Python。
version: 1.0.0
---

# Benchmark

本地效能測試和分析工具。

## Core Principles

> **量測先於優化** - 先確認效能瓶頸，再進行針對性優化

### 效能測試類型

| 類型 | 用途 | 工具 |
|------|------|------|
| 執行時間 | 測量程式碼執行速度 | Benchmark, benchmark-ips |
| 記憶體使用 | 測量記憶體消耗 | memory_profiler |
| N+1 偵測 | 找出 N+1 查詢問題 | bullet |
| HTTP 負載 | API 壓力測試 | ab, wrk |
| 資料庫查詢 | SQL 效能分析 | EXPLAIN ANALYZE |

## Instructions

### 1. Ruby 效能測試

#### 基本 Benchmark

```ruby
# 執行時間測量
require 'benchmark'

result = Benchmark.measure do
  # 要測試的程式碼
  1000.times { User.find(1) }
end

puts result
# user     system      total        real
# 0.123456 0.012345   0.135801 (  0.140000)
```

#### Benchmark IPS（每秒迭代次數）

```ruby
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("方法 A") { method_a }
  x.report("方法 B") { method_b }
  x.compare!
end
```

#### 記憶體分析

```ruby
require 'memory_profiler'

report = MemoryProfiler.report do
  # 要分析的程式碼
  large_array = (1..100000).map { |i| "string #{i}" }
end

report.pretty_print
```

#### N+1 查詢偵測

```ruby
# 使用 bullet gem（需在 Gemfile 中添加）
# config/environments/development.rb
Bullet.enable = true
Bullet.alert = true
Bullet.bullet_logger = true

# 或手動檢查
ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  puts "SQL (#{event.duration.round(1)}ms): #{event.payload[:sql]}"
end

# 然後執行要測試的程式碼
projects = Project.all
projects.each { |p| puts p.invoices.count }  # N+1!
```

### 2. JavaScript/Node.js 效能測試

#### Console Time

```javascript
console.time('operation');
// 要測試的程式碼
for (let i = 0; i < 1000; i++) {
  someFunction();
}
console.timeEnd('operation');
// operation: 123.456ms
```

#### Performance API

```javascript
const { performance } = require('perf_hooks');

const start = performance.now();
// 要測試的程式碼
await someAsyncOperation();
const end = performance.now();

console.log(`執行時間: ${end - start} ms`);
```

#### Benchmark.js

```javascript
const Benchmark = require('benchmark');

const suite = new Benchmark.Suite;

suite
  .add('方法 A', function() {
    methodA();
  })
  .add('方法 B', function() {
    methodB();
  })
  .on('complete', function() {
    console.log('最快的是: ' + this.filter('fastest').map('name'));
  })
  .run();
```

### 3. HTTP 負載測試

#### Apache Bench (ab)

```bash
# 基本測試：100 個請求，10 個併發
ab -n 100 -c 10 http://localhost:3000/api/projects

# 帶認證的測試
ab -n 100 -c 10 -H "Authorization: Bearer TOKEN" http://localhost:3000/api/projects

# POST 請求
ab -n 100 -c 10 -p data.json -T 'application/json' http://localhost:3000/api/projects
```

**輸出解讀**：

```
Requests per second:    150.00 [#/sec] (mean)  # 每秒處理請求數
Time per request:       66.67 [ms] (mean)      # 平均回應時間
Time per request:       6.67 [ms] (mean, across all concurrent requests)

Percentage of the requests served within a certain time (ms)
  50%     60    # 50% 的請求在 60ms 內完成
  90%    100    # 90% 的請求在 100ms 內完成
  99%    200    # 99% 的請求在 200ms 內完成
```

#### wrk（更進階的負載測試）

```bash
# 基本測試
wrk -t12 -c400 -d30s http://localhost:3000/api/projects

# 帶 Lua 腳本
wrk -t12 -c400 -d30s -s post.lua http://localhost:3000/api/projects
```

### 4. 資料庫查詢分析

#### PostgreSQL EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT * FROM invoices
WHERE project_id = 123
AND status = 'pending';
```

**輸出解讀**：

```
Seq Scan on invoices  (cost=0.00..1000.00 rows=100 width=200) (actual time=0.020..10.000 rows=100 loops=1)
  Filter: ((project_id = 123) AND (status = 'pending'))
  Rows Removed by Filter: 9900
Planning Time: 0.100 ms
Execution Time: 10.200 ms
```

**關注點**：
- `Seq Scan` vs `Index Scan`：Seq Scan 表示全表掃描
- `actual time`：實際執行時間
- `Rows Removed by Filter`：被過濾掉的行數

#### Rails 中執行 EXPLAIN

```ruby
# 在 Rails console
Invoice.where(project_id: 123, status: 'pending').explain

# 或
ActiveRecord::Base.connection.execute("EXPLAIN ANALYZE SELECT * FROM invoices WHERE project_id = 123")
```

### 5. 效能測試腳本範本

#### Ruby 完整效能測試

```ruby
# benchmark_test.rb
require 'benchmark'
require 'benchmark/ips'
require 'memory_profiler'

puts "=== 執行時間測試 ==="
Benchmark.bm(20) do |x|
  x.report("原始方法:") { original_method }
  x.report("優化方法:") { optimized_method }
end

puts "\n=== IPS 比較 ==="
Benchmark.ips do |x|
  x.report("原始方法") { original_method }
  x.report("優化方法") { optimized_method }
  x.compare!
end

puts "\n=== 記憶體使用 ==="
report = MemoryProfiler.report { original_method }
puts "總分配: #{report.total_allocated_memsize} bytes"
puts "總保留: #{report.total_retained_memsize} bytes"
```

執行：
```bash
# 路徑從 .claude/config/projects.yml 取得
cd {project_path} && bundle exec rails runner benchmark_test.rb
```

## Common Patterns

### Pattern 1: 比較兩種實作

```ruby
require 'benchmark/ips'

# 方法 A: 使用 each
def method_a(items)
  result = []
  items.each { |i| result << i * 2 }
  result
end

# 方法 B: 使用 map
def method_b(items)
  items.map { |i| i * 2 }
end

items = (1..10000).to_a

Benchmark.ips do |x|
  x.report("each + push") { method_a(items) }
  x.report("map")         { method_b(items) }
  x.compare!
end
```

### Pattern 2: 找出 N+1 查詢

```ruby
# 開啟 SQL 日誌
ActiveRecord::Base.logger = Logger.new(STDOUT)

# 測試程式碼
projects = Project.all  # 1 次查詢
projects.each do |p|
  puts p.invoices.count  # N 次查詢！
end

# 修正後
projects = Project.includes(:invoices).all  # 2 次查詢
projects.each do |p|
  puts p.invoices.size  # 0 次額外查詢
end
```

### Pattern 3: API 回應時間分析

```bash
# 測試單一 endpoint
ab -n 100 -c 1 http://localhost:3000/api/projects | grep -E "Time per request|Requests per second"

# 比較不同 endpoint
for endpoint in projects invoices users; do
  echo "=== $endpoint ==="
  ab -n 100 -c 10 http://localhost:3000/api/$endpoint 2>/dev/null | grep "Time per request.*mean\)"
done
```

## Output Format

測試完成後輸出：

```markdown
┌──────────────────────────────────────────────────────┐
│ 📊 效能測試報告                                      │
├──────────────────────────────────────────────────────┤
│ 測試項目：Invoice 查詢優化                           │
│ 測試環境：Local (MacBook Pro, 16GB RAM)             │
│                                                      │
│ 📈 執行時間比較：                                    │
│ ┌────────────────┬──────────┬──────────┐            │
│ │ 方法           │ 時間     │ 改善     │            │
│ ├────────────────┼──────────┼──────────┤            │
│ │ 原始方法       │ 150ms    │ -        │            │
│ │ 優化方法       │ 45ms     │ 70% ⬇️   │            │
│ └────────────────┴──────────┴──────────┘            │
│                                                      │
│ 💾 記憶體使用：                                      │
│ • 原始：50 MB                                        │
│ • 優化：15 MB（-70%）                               │
│                                                      │
│ 🔍 SQL 查詢：                                        │
│ • 原始：101 次（N+1）                               │
│ • 優化：2 次（includes）                            │
│                                                      │
│ 💡 建議：採用優化方法，效能提升 70%                 │
└──────────────────────────────────────────────────────┘
```

## Safety Guidelines

```
✅ 在 Local/Test 環境執行效能測試
✅ 使用 limit 限制測試資料量
✅ 避免在效能測試中修改資料

❌ 在 Production 執行負載測試
❌ 使用 Production 資料進行測試
❌ 長時間佔用資源的測試
```

## Integration with ATDD Workflow

效能測試在以下情況使用：

1. **Fix 任務（D8/D9）**：效能問題調查
2. **Feature 任務**：新功能效能驗證
3. **Refactor 任務**：重構前後效能比較

```
調查階段：找出效能瓶頸
測試階段：建立效能基準測試
開發階段：實作優化
驗收階段：確認效能改善
```
