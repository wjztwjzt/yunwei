#!/bin/bash
# 一键部署 db-backup timer 到 systemd
# 用法: sudo bash deploy/install.sh

set -e

DEPLOY_DIR="/opt/yunwei"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== 部署 MySQL 备份定时任务 ==="

# 1. 复制项目文件
echo "[1/4] 复制项目文件到 $DEPLOY_DIR ..."
mkdir -p "$DEPLOY_DIR"
cp "$PROJECT_DIR/db_backup.py" "$DEPLOY_DIR/"
cp "$PROJECT_DIR/requirements.txt" "$DEPLOY_DIR/"

# 2. 安装 Python 依赖
echo "[2/4] 安装 Python 依赖..."
pip3 install -r "$DEPLOY_DIR/requirements.txt" -q

# 3. 检查 .env 配置
if [ ! -f "$DEPLOY_DIR/.env" ]; then
    echo "[!] 请先创建 $DEPLOY_DIR/.env 文件（参考 $PROJECT_DIR/.env.example）"
    echo "    cp $PROJECT_DIR/.env.example $DEPLOY_DIR/.env"
    echo "    vim $DEPLOY_DIR/.env"
    exit 1
fi
echo "[3/4] .env 配置已存在 ✓"

# 4. 安装 systemd timer
echo "[4/4] 安装 systemd timer..."
cp "$SCRIPT_DIR/db-backup.service" /etc/systemd/system/
cp "$SCRIPT_DIR/db-backup.timer" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now db-backup.timer

echo ""
echo "=== 部署完成 ==="
echo "查看定时任务状态: systemctl status db-backup.timer"
echo "查看下次执行时间: systemctl list-timers db-backup.timer"
echo "手动执行一次测试: systemctl start db-backup.service"
echo "查看日志: journalctl -u db-backup.service -f"
