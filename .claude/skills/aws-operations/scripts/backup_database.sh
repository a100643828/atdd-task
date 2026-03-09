#!/bin/bash
# AWS EC2 資料庫備份腳本
# 用法: ./backup_database.sh [project] [environment]
# 範例: ./backup_database.sh sf_project production
#       ./backup_database.sh core_web production

set -e

# ==================== 配置 ====================

PROJECT=${1:-"sf_project"}
ENVIRONMENT=${2:-"production"}
BACKUP_DIR="./backups/${PROJECT}/${ENVIRONMENT}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SSH_KEY_PATH="${HOME}/.ssh/${PROJECT}_${ENVIRONMENT}.pem"
SSH_USER="${3:-ubuntu}"

# ==================== 顏色輸出 ====================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# ==================== 前置檢查 ====================

check_prerequisites() {
  info "檢查前置條件..."

  # 檢查 AWS CLI
  if ! command -v aws &> /dev/null; then
    error "AWS CLI 未安裝，請執行: brew install awscli"
    exit 1
  fi

  # 檢查 SSH key
  if [ ! -f "$SSH_KEY_PATH" ]; then
    error "SSH key 不存在: $SSH_KEY_PATH"
    exit 1
  fi

  # 檢查 key 權限
  KEY_PERMS=$(stat -f "%OLp" "$SSH_KEY_PATH" 2>/dev/null || stat -c "%a" "$SSH_KEY_PATH" 2>/dev/null)
  if [ "$KEY_PERMS" != "400" ] && [ "$KEY_PERMS" != "600" ]; then
    warn "SSH key 權限不正確 ($KEY_PERMS)，正在修正為 400..."
    chmod 400 "$SSH_KEY_PATH"
  fi

  success "前置檢查通過"
}

# ==================== 取得實例資訊 ====================

get_instance_ip() {
  info "查詢 EC2 實例..."

  INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${PROJECT}-${ENVIRONMENT}" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>&1)

  if [ $? -ne 0 ] || [ "$INSTANCE_IP" == "None" ] || [ -z "$INSTANCE_IP" ]; then
    error "找不到運行中的實例: ${PROJECT}-${ENVIRONMENT}"
    error "AWS 錯誤: $INSTANCE_IP"
    exit 1
  fi

  success "找到實例: $INSTANCE_IP"
}

# ==================== 測試連接 ====================

test_connection() {
  info "測試 SSH 連接..."

  if ! ssh -i "$SSH_KEY_PATH" \
       -o ConnectTimeout=10 \
       -o StrictHostKeyChecking=no \
       -o BatchMode=yes \
       "${SSH_USER}@${INSTANCE_IP}" "echo 'Connection OK'" &> /dev/null; then
    error "無法連接到 $INSTANCE_IP"
    error "請檢查: 1) Security Group 允許 SSH (22), 2) 實例正在運行, 3) SSH key 正確"
    exit 1
  fi

  success "SSH 連接成功"
}

# ==================== 檢查遠端環境 ====================

check_remote_environment() {
  info "檢查遠端環境..."

  DB_INFO=$(ssh -i "$SSH_KEY_PATH" "${SSH_USER}@${INSTANCE_IP}" 'bash -s' << 'REMOTE_SCRIPT'
#!/bin/bash

# 檢查資料庫類型
if command -v pg_dump &> /dev/null; then
  echo "DB_TYPE=postgresql"

  # 檢查 PostgreSQL 狀態
  if sudo systemctl is-active postgresql &> /dev/null; then
    echo "DB_STATUS=active"
  else
    echo "DB_STATUS=inactive"
  fi

elif command -v mysqldump &> /dev/null; then
  echo "DB_TYPE=mysql"

  # 檢查 MySQL 狀態
  if sudo systemctl is-active mysql &> /dev/null || sudo systemctl is-active mariadb &> /dev/null; then
    echo "DB_STATUS=active"
  else
    echo "DB_STATUS=inactive"
  fi
else
  echo "DB_TYPE=unknown"
  echo "DB_STATUS=unknown"
fi

# 檢查磁碟空間
DISK_FREE=$(df -h /tmp | tail -1 | awk '{print $4}')
echo "DISK_FREE=$DISK_FREE"
REMOTE_SCRIPT
)

  eval "$DB_INFO"

  if [ "$DB_TYPE" == "unknown" ]; then
    error "無法偵測資料庫類型（PostgreSQL 或 MySQL）"
    exit 1
  fi

  if [ "$DB_STATUS" != "active" ]; then
    error "資料庫服務未運行"
    exit 1
  fi

  success "遠端環境: $DB_TYPE (運行中), 可用空間: $DISK_FREE"
}

# ==================== 執行備份 ====================

perform_backup() {
  info "開始備份 $DB_TYPE 資料庫..."

  # 建立備份目錄
  mkdir -p "$BACKUP_DIR"

  BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"

  case $DB_TYPE in
    postgresql)
      info "使用 pg_dump 備份..."
      ssh -i "$SSH_KEY_PATH" "${SSH_USER}@${INSTANCE_IP}" \
        "sudo -u postgres pg_dump -d ${PROJECT}_${ENVIRONMENT} -F c -b -v" \
        > "$BACKUP_FILE" 2>/tmp/backup_error.log
      ;;

    mysql)
      info "使用 mysqldump 備份..."
      # 注意: 生產環境應使用更安全的密碼管理方式
      ssh -i "$SSH_KEY_PATH" "${SSH_USER}@${INSTANCE_IP}" \
        "sudo mysqldump ${PROJECT}_${ENVIRONMENT} --single-transaction --quick" \
        > "$BACKUP_FILE" 2>/tmp/backup_error.log
      ;;

    *)
      error "不支援的資料庫類型: $DB_TYPE"
      exit 1
      ;;
  esac

  if [ $? -ne 0 ]; then
    error "備份失敗"
    cat /tmp/backup_error.log >&2
    exit 1
  fi

  success "備份完成: $BACKUP_FILE"
}

# ==================== 壓縮備份 ====================

compress_backup() {
  info "壓縮備份檔案..."

  gzip "$BACKUP_FILE"

  COMPRESSED_FILE="${BACKUP_FILE}.gz"
  BACKUP_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)

  success "壓縮完成: $COMPRESSED_FILE ($BACKUP_SIZE)"
}

# ==================== 清理舊備份 ====================

cleanup_old_backups() {
  info "清理 7 天前的舊備份..."

  OLD_COUNT=$(find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +7 | wc -l | xargs)

  if [ "$OLD_COUNT" -gt 0 ]; then
    find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +7 -delete
    success "已刪除 $OLD_COUNT 個舊備份"
  else
    info "沒有需要清理的舊備份"
  fi
}

# ==================== 驗證備份 ====================

verify_backup() {
  info "驗證備份完整性..."

  # 檢查檔案大小
  FILE_SIZE=$(stat -f%z "$COMPRESSED_FILE" 2>/dev/null || stat -c%s "$COMPRESSED_FILE" 2>/dev/null)

  if [ "$FILE_SIZE" -lt 1024 ]; then
    error "備份檔案太小 ($FILE_SIZE bytes)，可能有問題"
    exit 1
  fi

  # 檢查 gzip 完整性
  if ! gzip -t "$COMPRESSED_FILE" 2>/dev/null; then
    error "備份檔案損壞（gzip 測試失敗）"
    exit 1
  fi

  success "備份驗證通過 ($BACKUP_SIZE)"
}

# ==================== 主程式 ====================

main() {
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║            AWS EC2 資料庫備份腳本                              ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""

  info "專案: $PROJECT"
  info "環境: $ENVIRONMENT"
  info "SSH Key: $SSH_KEY_PATH"
  info "備份目錄: $BACKUP_DIR"
  echo ""

  check_prerequisites
  get_instance_ip
  test_connection
  check_remote_environment
  perform_backup
  compress_backup
  verify_backup
  cleanup_old_backups

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                      備份完成！                                ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""

  success "備份檔案: $COMPRESSED_FILE"
  success "檔案大小: $BACKUP_SIZE"

  # 列出最近 5 次備份
  echo ""
  info "最近 5 次備份:"
  ls -lht "$BACKUP_DIR"/backup_*.sql.gz | head -5 | \
    awk '{printf "  %s %s  %s\n", $6, $7, $9}'
  echo ""
}

# 執行主程式
main "$@"
