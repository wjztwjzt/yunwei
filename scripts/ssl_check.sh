#!/bin/bash
# SSL 证书到期检查：批量检查域名证书剩余天数
# 用法: ./ssl_check.sh example.com www.example.com
#   或: cat domains.txt | xargs ./ssl_check.sh

set -e

ALERT_DAYS="${SSL_ALERT_DAYS:-30}"

check_domain() {
    local domain="$1"
    local port="${2:-443}"

    if ! command -v openssl &> /dev/null; then
        echo "请先安装 openssl: apt install openssl"
        exit 1
    fi

    local end_date
    end_date=$(echo | openssl s_client -servername "$domain" -connect "$domain:$port" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$end_date" ]; then
        echo "[FAIL] $domain - 无法获取证书信息"
        return 1
    fi

    local end_epoch
    local now_epoch
    end_epoch=$(date -d "$end_date" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$end_date" +%s 2>/dev/null)
    now_epoch=$(date +%s)

    local days_left=$(( (end_epoch - now_epoch) / 86400 ))

    if [ "$days_left" -lt 0 ]; then
        echo "[EXPIRED] $domain - 证书已过期 ${days_left#-} 天 ($end_date)"
    elif [ "$days_left" -lt "$ALERT_DAYS" ]; then
        echo "[WARN] $domain - 还剩 ${days_left} 天到期 ($end_date)"
    else
        echo "[OK] $domain - 还剩 ${days_left} 天到期 ($end_date)"
    fi
}

if [ $# -eq 0 ]; then
    echo "用法: $0 <domain1> [domain2] ..."
    exit 1
fi

echo "SSL 证书检查（告警阈值: ${ALERT_DAYS} 天）"
echo "=========================================="
for domain in "$@"; do
    check_domain "$domain"
done
