sudo ufw allow 9527 && bash -c 'cat > aa.sh << "EOF"
#!/bin/bash

set -e

PROXY_USER="usrpoxy"
PROXY_PASS="$(openssl rand -base64 12)"
PORT="9527"
INTERFACE=$(ip route get 1 | awk '"'"'{print $5;exit}'"'"')

echo ">>> 使用网卡: $INTERFACE"

apt update -y
apt install dante-server -y

id "$PROXY_USER" &>/dev/null || useradd -M -s /usr/sbin/nologin "$PROXY_USER"
echo "$PROXY_USER:$PROXY_PASS" | chpasswd

cat > /etc/danted.conf <<EOL
logoutput: syslog

internal: 0.0.0.0 port = $PORT
external: $INTERFACE

method: username

user.privileged: root
user.unprivileged: nobody
user.libwrap: nobody

client pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: connect disconnect
}

pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
protocol: tcp udp
}
EOL

systemctl restart danted
systemctl enable danted

sleep 2
systemctl status danted --no-pager

SERVER_IP=$(curl -s ifconfig.me || curl -s ip.sb)

echo ">>> 服务器IP: $SERVER_IP"

RESULT=$(curl -s --proxy socks5://$PROXY_USER:$PROXY_PASS@$SERVER_IP:$PORT ifconfig.me || echo "fail")

echo ">>> 代理返回IP: $RESULT"

if [[ "$RESULT" == "$SERVER_IP" ]]; then
echo "🎉 SOCKS5 代理搭建成功！"
else
echo "❌ 代理可能有问题，请检查端口/防火墙"
fi

echo "==== 连接信息 ===="
echo "$PROXY_USER:$PROXY_PASS@$SERVER_IP:$PORT"
EOF
chmod +x aa.sh
bash aa.sh'