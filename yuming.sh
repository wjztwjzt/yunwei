#!/bin/bash

set -e

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
NC="\033[0m"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 运行${NC}"
    exit 1
fi

echo -e "${GREEN}====== Nginx + HTTPS 一键配置 ======${NC}"
echo

read -p "请输入域名(例如 example.com): " DOMAIN
read -p "请输入邮箱: " EMAIL
read -p "请输入本地反代端口(默认8000): " PORT

PORT=${PORT:-8000}

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}域名不能为空！${NC}"
    exit 1
fi

echo
echo "安装依赖..."

apt update

if ! command -v nginx >/dev/null 2>&1; then
    apt install -y nginx
fi

if ! command -v certbot >/dev/null 2>&1; then
    apt install -y certbot python3-certbot-nginx
fi

mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

CONF="/etc/nginx/sites-available/${DOMAIN}.conf"

# 如果配置已存在
if [ -f "$CONF" ]; then
    echo
    echo -e "${YELLOW}检测到该域名已经存在配置：${DOMAIN}${NC}"
    read -p "是否覆盖？(y/N): " COVER

    if [[ "$COVER" != "y" && "$COVER" != "Y" ]]; then
        echo "已取消。"
        exit 0
    fi
fi

cat > "$CONF" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {

        proxy_pass http://127.0.0.1:${PORT};

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

ln -sf "$CONF" "/etc/nginx/sites-enabled/${DOMAIN}.conf"

# 仅删除默认站点
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm -f /etc/nginx/sites-enabled/default
fi

echo
echo "检测 Nginx 配置..."

nginx -t

systemctl enable nginx
systemctl reload nginx

echo
echo "开始申请 SSL..."

certbot \
    --nginx \
    --non-interactive \
    --agree-tos \
    --redirect \
    -m "$EMAIL" \
    -d "$DOMAIN"

echo
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}HTTPS 配置完成！${NC}"
echo

echo "域名： https://${DOMAIN}"
echo "反代：127.0.0.1:${PORT}"

echo
echo "证书自动续期："

systemctl list-timers | grep certbot || true

echo
echo -e "${GREEN}完成！${NC}"
