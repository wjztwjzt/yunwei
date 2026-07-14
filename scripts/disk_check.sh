#!/bin/bash
# 磁盘空间检查：超过阈值时输出警告
# 用法: ./disk_check.sh [阈值百分比，默认90]

set -e

THRESHOLD="${1:-90}"
ALERT_MSG=""

while IFS= read -r line; do
    usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$usage" -ge "$THRESHOLD" ]; then
        ALERT_MSG+="[!] $mount 使用率 ${usage}%（阈值 ${THRESHOLD}%）\n"
    fi
done < <(df -h | grep '^/dev/')

if [ -n "$ALERT_MSG" ]; then
    echo "========== 磁盘告警 =========="
    echo ""
    echo -e "$ALERT_MSG"
    echo ""
    df -h | grep '^/dev/'
    echo ""
    echo "=============================="
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') 磁盘正常，所有分区低于 ${THRESHOLD}%"
