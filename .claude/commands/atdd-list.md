# ATDD List Command

列出所有 ATDD 任務的詳細資訊，包含**專案**、**領域**和**類型**。

## 執行命令

```bash
# 使用 Node.js 腳本列出任務
cd {{PROJECT_PATH}}
node -e "
const fs = require('fs');
const path = require('path');

const tasksDir = 'tasks';
const locations = ['active', 'completed', 'failed'];

console.log('\\n📋 ATDD 任務列表\\n');
console.log('='.repeat(80) + '\\n');

for (const loc of locations) {
  const locPath = path.join(tasksDir, loc);
  if (fs.existsSync(locPath)) {
    const files = fs.readdirSync(locPath).filter(f => f.endsWith('.json'));

    if (files.length > 0) {
      console.log(\`\\n## \${loc.toUpperCase()} (\${files.length} 個任務)\\n\`);

      files.forEach(file => {
        const content = fs.readFileSync(path.join(locPath, file), 'utf-8');
        const task = JSON.parse(content);

        const emoji = task.type === 'feature' ? '✨' :
                     task.type === 'fix' ? '🐛' :
                     task.type === 'refactor' ? '♻️' :
                     task.type === 'health-check' ? '🏥' : '📝';

        const typeLabel = task.type === 'feature' ? 'Feature' :
                         task.type === 'fix' ? 'Fix' :
                         task.type === 'refactor' ? 'Refactor' :
                         task.type === 'health-check' ? 'Health Check' : 'Spec Update';

        console.log(\`\${emoji} [\${task.id.substring(0, 8)}] \${task.description}\`);
        console.log(\`   📦 專案: \${task.projectName || task.projectId}\`);
        console.log(\`   📂 領域: \${task.domain || 'N/A'}\`);
        console.log(\`   🏷️  類型: \${typeLabel}\`);
        console.log(\`   📊 狀態: \${task.status}\`);
        console.log(\`   🕐 建立: \${new Date(task.createdAt).toLocaleString()}\`);
        console.log(\`   🔄 更新: \${new Date(task.updatedAt).toLocaleString()}\`);
        console.log('');
      });
    }
  }
}

console.log('='.repeat(80));
console.log('\\n💡 提示：使用 /atdd-kanban 查看看板視圖\\n');
"
```

## 顯示格式

每個任務顯示：
- 🔹 類型 Emoji + 任務 ID (前 8 碼)
- 📦 **專案名稱**（跨專案識別）
- 📂 **領域名稱**（從 Domain 分析取得）
- 🏷️ **任務類型**（Feature/Fix/Refactor/Health Check/Spec Update）
- 📊 任務狀態
- 🕐 建立時間
- 🔄 更新時間
- 📈 相關指標（如果有）

## 範例輸出

```
📋 ATDD 任務列表
================================================================================

## ACTIVE (2 個任務)

✨ [550e8400] 建立使用者註冊功能
   📦 專案: my-app
   📂 領域: User
   🏷️  類型: Feature
   📊 狀態: implementing
   🕐 建立: 2025-12-05 10:00:00
   🔄 更新: 2025-12-05 10:25:00

🐛 [11112222] 修復登入 session 問題
   📦 專案: my-app
   📂 領域: Auth
   🏷️  類型: Fix
   📊 狀態: testing
   🕐 建立: 2025-12-05 09:00:00
   🔄 更新: 2025-12-05 09:45:00

## COMPLETED (1 個任務)

✨ [99998888] 建立商品列表功能
   📦 專案: shop-system
   📂 領域: Product
   🏷️  類型: Feature
   📊 狀態: completed
   🕐 建立: 2025-12-03 14:00:00
   🔄 更新: 2025-12-03 15:30:00

================================================================================

💡 提示：使用 /atdd-kanban 查看看板視圖
```
