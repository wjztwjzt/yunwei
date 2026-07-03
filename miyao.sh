#!/bin/bash

# 1. 定义你的公钥（请确保引号内是你的完整公钥）
PUBLIC_KEY=""

# 2. 创建目录并写入公钥
mkdir -p ~/.ssh
echo "$PUBLIC_KEY" > ~/.ssh/authorized_keys

# 3. 设置权限 (严格模式)
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 4. 修改 sshd_config 配置
# 开启公钥认证
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# 禁用密码登录
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# 设置 root 禁止密码登录 (允许密钥登录)
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# 5. 重启 SSH 服务使配置生效
sudo systemctl restart ssh

echo "------------------------------------------------"
echo "✅ SSH 安全配置完成！"
echo "🔑 已启用公钥登录，已彻底禁用密码登录。"
echo "⚠️  注意：请确保你本地已保存私钥，否则断开连接后将无法登录！"
echo "------------------------------------------------"