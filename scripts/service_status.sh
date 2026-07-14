#!/bin/bash
# 关键服务状态检查
# 用法: ./service_status.sh

SERVICES=(
    nginx
    mysql
    redis-server
    sshd
    cron
    docker
)

echo "========================================"
echo "  服务状态检查  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        printf "  %-20s \033[32m● running\033[0m\n" "$svc"
    elif systemctl is-enabled --quiet "$svc" 2>/dev/null; then
        printf "  %-20s \033[31m● stopped\033[0m\n" "$svc"
    else
        printf "  %-20s \033[90m- not installed\033[0m\n" "$svc"
    fi
done

echo "========================================"
