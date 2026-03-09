#!/bin/bash
# 快速檢查生產環境服務狀態與日誌
# 用法: ./check_service.sh [service_name] [environment] [project]
# 範例: ./check_service.sh puma production core_web
#       ./check_service.sh postgresql staging sf_project

set -e

# ==================== 配置 ====================

SERVICE=${1:-"puma"}
ENVIRONMENT=${2:-"production"}
PROJECT=${3:-"sf_project"}
SSH_KEY="${HOME}/.ssh/${PROJECT}_${ENVIRONMENT}.pem"
SSH_USER="ubuntu"

# ==================== 顏色輸出 ====================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

error() {
  echo -e "${RED}❌ $1${NC}" >&2
}

success() {
  echo -e "${GREEN}✅ $1${NC}"
}

info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

warn() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

header() {
  echo -e "${CYAN}$1${NC}"
}

# ==================== 取得實例 IP ====================

get_instance_ip() {
  info "正在查詢 ${ENVIRONMENT} 環境的 EC2 實例..."

  INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Environment,Values=${ENVIRONMENT}" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>&1)

  if [ $? -ne 0 ] || [ "$INSTANCE_IP" == "None" ] || [ -z "$INSTANCE_IP" ]; then
    error "找不到運行中的 ${ENVIRONMENT} 實例"
    exit 1
  fi

  success "找到實例: $INSTANCE_IP"
}

# ==================== 執行服務檢查 ====================

check_service() {
  echo ""
  header "╔══════════════════════════════════════════════════════════════╗"
  header "║  服務檢查: ${SERVICE} @ ${ENVIRONMENT}"
  header "╚══════════════════════════════════════════════════════════════╝"
  echo ""

  ssh -i "$SSH_KEY" \
      -o ConnectTimeout=10 \
      -o StrictHostKeyChecking=no \
      "${SSH_USER}@${INSTANCE_IP}" bash << EOF
#!/bin/bash

SERVICE="${SERVICE}"

# 顏色定義（遠端）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "\${CYAN}━━━ 1. 服務狀態 ━━━\${NC}"
echo ""

if sudo systemctl is-active \${SERVICE} &>/dev/null; then
  echo -e "\${GREEN}✅ \${SERVICE} 運行中\${NC}"
  sudo systemctl status \${SERVICE} --no-pager | head -15
else
  echo -e "\${RED}❌ \${SERVICE} 未運行\${NC}"
  sudo systemctl status \${SERVICE} --no-pager | head -15
fi

echo ""
echo -e "\${CYAN}━━━ 2. 最近日誌 (最近 30 行) ━━━\${NC}"
echo ""
sudo journalctl -u \${SERVICE} -n 30 --no-pager

echo ""
echo -e "\${CYAN}━━━ 3. 錯誤日誌 (最近 10 行) ━━━\${NC}"
echo ""
ERROR_COUNT=\$(sudo journalctl -u \${SERVICE} -p err --since "1 hour ago" --no-pager | wc -l)
if [ "\$ERROR_COUNT" -gt 0 ]; then
  echo -e "\${YELLOW}⚠️  過去 1 小時內有 \${ERROR_COUNT} 個錯誤\${NC}"
  sudo journalctl -u \${SERVICE} -p err -n 10 --no-pager
else
  echo -e "\${GREEN}✅ 過去 1 小時內沒有錯誤\${NC}"
fi

echo ""
echo -e "\${CYAN}━━━ 4. 資源使用 ━━━\${NC}"
echo ""

# 記憶體和 CPU
PROCESSES=\$(ps aux | grep -i \${SERVICE} | grep -v grep)
if [ -n "\$PROCESSES" ]; then
  echo "\$PROCESSES" | awk '{printf "  PID: %-6s  CPU: %5s%%  MEM: %5s%%  CMD: %s\n", \$2, \$3, \$4, \$11}'
else
  echo "  (找不到運行的進程)"
fi

echo ""

# 監聽端口
PORTS=\$(sudo netstat -tlnp 2>/dev/null | grep \${SERVICE})
if [ -n "\$PORTS" ]; then
  echo -e "\${BLUE}🔌 監聽端口:\${NC}"
  echo "\$PORTS"
else
  echo "  (未找到監聽端口)"
fi

echo ""
echo -e "\${CYAN}━━━ 5. 系統資源概覽 ━━━\${NC}"
echo ""

# 系統負載
echo -e "\${BLUE}📊 系統負載:\${NC}"
uptime | awk '{print "  " \$0}'

echo ""

# 磁碟空間
echo -e "\${BLUE}💾 磁碟使用:\${NC}"
df -h / | tail -1 | awk '{printf "  使用: %s / %s (%s)\n", \$3, \$2, \$5}'

echo ""

# 記憶體
echo -e "\${BLUE}🧠 記憶體使用:\${NC}"
free -h | grep Mem | awk '{printf "  使用: %s / %s\n", \$3, \$2}'

EOF
}

# ==================== Rails 專用日誌 ====================

check_rails_logs() {
  if [ "$SERVICE" == "puma" ] || [ "$SERVICE" == "rails" ]; then
    echo ""
    header "╔══════════════════════════════════════════════════════════════╗"
    header "║  Rails Application Logs"
    header "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    ssh -i "$SSH_KEY" "${SSH_USER}@${INSTANCE_IP}" bash << 'EOF'
LOG_FILE="/home/apps/${PROJECT}/shared/log/production.log"

if [ -f "$LOG_FILE" ]; then
  echo "📋 Rails Production Log (最近 50 行):"
  echo ""
  tail -50 "$LOG_FILE"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "❌ Rails 錯誤 (最近 10 個):"
  echo ""
  grep -i "error\|exception\|fatal" "$LOG_FILE" | tail -10
else
  echo "⚠️  找不到 Rails log 文件: $LOG_FILE"
fi
EOF
  fi
}

# ==================== 主程式 ====================

main() {
  echo ""
  info "服務: $SERVICE"
  info "環境: $ENVIRONMENT"
  info "SSH Key: $SSH_KEY"
  echo ""

  get_instance_ip
  check_service
  check_rails_logs

  echo ""
  success "檢查完成！"
  echo ""
}

# 執行主程式
main "$@"
