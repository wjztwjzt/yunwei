#!/bin/bash
# 系统更新脚本：更新包列表 + 升级所有包 + 清理
# 建议配置 cron: 0 3 * * 0 /opt/yunwei/scripts/system_update.sh

set -e

LOG_FILE="/var/log/system_update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========== 开始系统更新 =========="

log "更新软件包列表..."
apt update -y >> "$LOG_FILE" 2>&1

log "升级已安装的软件包..."
apt upgrade -y >> "$LOG_FILE" 2>&1

log "清理不再需要的依赖..."
apt autoremove -y >> "$LOG_FILE" 2>&1
apt autoclean -y >> "$LOG_FILE" 2>&1

# 检查是否需要重启
if [ -f /var/run/reboot-required ]; then
    log "[!] 系统需要重启以完成更新"
fi

log "========== 系统更新完成 =========="
