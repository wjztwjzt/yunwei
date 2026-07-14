#!/usr/bin/env python3
"""MySQL 全量备份脚本：备份所有数据库 → 压缩 → 上传 WebDAV → 保留最近 N 份。"""

import os
import sys
import time
import logging
import subprocess
from datetime import datetime

from dotenv import load_dotenv
from webdav4.client import Client

load_dotenv()

# ── 配置（全部从环境变量读取）──────────────────────────────────
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "")
WEBDAV_URL = os.getenv("WEBDAV_URL", "")
WEBDAV_USER = os.getenv("WEBDAV_USER", "")
WEBDAV_PASS = os.getenv("WEBDAV_PASS", "")
WEBDAV_DIR = os.getenv("WEBDAV_DIR", "db_backups")
MAX_KEEP = int(os.getenv("MAX_KEEP", "3"))
LOCAL_TEMP_DIR = os.getenv("LOCAL_TEMP_DIR", "/tmp/db_backups")
LOG_FILE = os.getenv("LOG_FILE", "")

EXCLUDE_DBS = {"information_schema", "performance_schema", "sys", "mysql"}

# ── 日志 ────────────────────────────────────────────────────────
log_handlers = [logging.StreamHandler(sys.stdout)]
if LOG_FILE:
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    log_handlers.append(logging.FileHandler(LOG_FILE, encoding="utf-8"))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=log_handlers,
)
logger = logging.getLogger("db_backup")


def check_config():
    """检查必要配置是否填写。"""
    missing = []
    for key, val in [
        ("DB_PASS", DB_PASS),
        ("WEBDAV_URL", WEBDAV_URL),
        ("WEBDAV_USER", WEBDAV_USER),
        ("WEBDAV_PASS", WEBDAV_PASS),
    ]:
        if not val:
            missing.append(key)
    if missing:
        logger.error("缺少必要配置: %s，请检查 .env 文件", ", ".join(missing))
        sys.exit(1)


def get_all_databases():
    """通过 mysql 命令行获取所有非系统数据库。"""
    cmd = (
        f"mysql -u{DB_USER} -p'{DB_PASS}' "
        "-e 'SHOW DATABASES;' -s --skip-column-names"
    )
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True,
            executable="/bin/bash", timeout=30,
        )
        if result.returncode != 0:
            logger.error("获取数据库列表失败: %s", result.stderr.strip())
            return []
        dbs = [db.strip() for db in result.stdout.strip().split("\n") if db.strip()]
        valid = [db for db in dbs if db not in EXCLUDE_DBS]
        return valid
    except subprocess.TimeoutExpired:
        logger.error("获取数据库列表超时")
        return []
    except Exception as e:
        logger.error("获取数据库列表异常: %s", e)
        return []


def backup_database(db_name, timestamp, client):
    """备份单个数据库：导出 → 压缩 → 上传 → 清理旧版。"""
    filename = f"{db_name}_{timestamp}.sql.gz"
    local_path = os.path.join(LOCAL_TEMP_DIR, filename)
    remote_path = f"{WEBDAV_DIR}/{filename}"

    # 1. 导出 + 压缩
    dump_cmd = f"mysqldump -u{DB_USER} -p'{DB_PASS}' {db_name} | gzip > {local_path}"
    try:
        subprocess.run(dump_cmd, shell=True, check=True, executable="/bin/bash", timeout=600)
        size_mb = os.path.getsize(local_path) / 1024 / 1024
        logger.info("[%s] 导出完成 (%.2f MB)", db_name, size_mb)
    except subprocess.TimeoutExpired:
        logger.error("[%s] 导出超时，跳过", db_name)
        return False
    except subprocess.CalledProcessError as e:
        logger.error("[%s] 导出失败，跳过", db_name)
        return False

    # 2. 上传
    try:
        logger.info("[%s] 正在上传...", db_name)
        client.upload_file(local_path, remote_path, overwrite=True)
        logger.info("[%s] 上传成功", db_name)
    except Exception as e:
        logger.error("[%s] 上传失败: %s", db_name, e)
        if os.path.exists(local_path):
            os.remove(local_path)
        return False

    # 3. 清理旧备份（按文件名前缀精确匹配）
    try:
        all_files = client.ls(WEBDAV_DIR)
        backups = [
            f for f in all_files
            if f.get("type") == "file" and f["name"].startswith(f"{db_name}_")
        ]
        backups.sort(key=lambda x: x["name"])

        if len(backups) > MAX_KEEP:
            for f in backups[:-MAX_KEEP]:
                client.remove(f"{WEBDAV_DIR}/{f['name']}")
                logger.info("[%s] 已删除旧备份: %s", db_name, f["name"])
        else:
            logger.info("[%s] 历史版本 %d/%d，无需清理", db_name, len(backups), MAX_KEEP)
    except Exception as e:
        logger.warning("[%s] 清理旧备份时出错: %s", db_name, e)

    # 4. 删除本地临时文件
    if os.path.exists(local_path):
        os.remove(local_path)

    return True


def main():
    logger.info("========== 数据库备份任务开始 ==========")

    check_config()

    databases = get_all_databases()
    if not databases:
        logger.warning("没有需要备份的数据库，任务结束")
        return

    logger.info("检测到 %d 个数据库: %s", len(databases), ", ".join(databases))

    os.makedirs(LOCAL_TEMP_DIR, exist_ok=True)

    logger.info("正在连接 WebDAV...")
    client = Client(WEBDAV_URL, auth=(WEBDAV_USER, WEBDAV_PASS))

    if not client.exists(WEBDAV_DIR):
        client.mkdir(WEBDAV_DIR)
        logger.info("已创建远程目录: %s", WEBDAV_DIR)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    success = 0
    fail = 0
    for db_name in databases:
        result = backup_database(db_name, timestamp, client)
        if result:
            success += 1
        else:
            fail += 1

    logger.info("========== 备份完成: 成功 %d, 失败 %d ==========", success, fail)


if __name__ == "__main__":
    main()
