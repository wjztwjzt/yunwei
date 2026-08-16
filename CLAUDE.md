# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

VPS 运维脚本集合（yunwei）。包含 MySQL 数据库全量备份、系统更新、磁盘检查、SSL 证书检查等常用运维脚本。

## 项目结构

```
├── db_backup.py           # MySQL 全量备份脚本（核心）
├── requirements.txt       # Python 依赖
├── .env.example           # 环境变量模板
├── deploy/                # systemd timer 部署文件
│   ├── db-backup.service
│   ├── db-backup.timer
│   └── install.sh         # 一键部署脚本
└── scripts/               # 其他运维脚本
    ├── system_update.sh   # 系统更新
    ├── disk_check.sh      # 磁盘空间检查
    ├── ssl_check.sh       # SSL 证书到期检查
    └── service_status.sh  # 关键服务状态
```

## 部署备份定时任务

在 VPS 上执行：

```bash
# 1. 克隆仓库
git clone https://github.com/wjztwjzt/yunwei.git /opt/yunwei

# 2. 配置环境变量
cp /opt/yunwei/.env.example /opt/yunwei/.env
vim /opt/yunwei/.env

# 3. 一键部署 systemd timer
sudo bash /opt/yunwei/deploy/install.sh
```

部署后每天凌晨 5:00 自动执行全量备份。常用命令：

```bash
systemctl status db-backup.timer    # 查看定时任务状态
systemctl list-timers db-backup.timer  # 查看下次执行时间
systemctl start db-backup.service   # 手动执行一次
journalctl -u db-backup.service -f  # 实时查看日志
```

## 备份脚本逻辑

`db_backup.py`：
1. 通过 `mysql` CLI 获取所有数据库（排除 information_schema, performance_schema, sys, mysql）
2. 逐个 `mysqldump | gzip` 压缩导出
3. 上传到 WebDAV 网盘
4. 每个数据库保留最近 `MAX_KEEP`（默认 3）份，自动清理旧版
5. 同时输出日志到控制台和 `LOG_FILE`（如果配置）

## 注意事项

- `db_backup.py` 依赖系统安装的 `mysql` 和 `mysqldump` 客户端
- `.env` 文件包含敏感信息，已在 `.gitignore` 中排除，不会提交到 Git
