cat >/usr/local/bin/svc <<'EOF'
#!/bin/bash

case "$1" in
    start|stop|restart|reload|status|enable|disable)
        systemctl "$1" "$2"
        ;;

    now)
        systemctl enable --now "$2"
        ;;

    off)
        systemctl disable --now "$2"
        ;;

    rf)
        if [ -z "$2" ]; then
            systemctl reset-failed
        else
            systemctl reset-failed "${2%.service}.service"
        fi
        ;;
    dr|daemon-reload)
        systemctl daemon-reload
        echo "✓ daemon-reload 完成"
        ;;

    ls)
        printf "%-25s %-10s\n" "SERVICE" "STATUS"
        echo "----------------------------------------"

        for f in /etc/systemd/system/*.service; do
            [ -f "$f" ] || continue

            name=$(basename "$f" .service)
            status=$(systemctl is-active "$name" 2>/dev/null)

            printf "%-25s %s\n" "$name" "$status"
        done
        ;;

    all)
        systemctl list-units --type=service
        ;;

    files)
        systemctl list-unit-files --type=service
        ;;

    fail|failed)
        systemctl --failed
        ;;

    log)
        journalctl -u "$2" -f
        ;;

    logs)
        journalctl -u "$2" -n "${3:-100}"
        ;;

    cat)
        systemctl cat "$2"
        ;;

    edit)
        systemctl edit --full "$2"
        ;;

    active)
        systemctl is-active "$2"
        ;;

    enabled)
        systemctl is-enabled "$2"
        ;;

    py)
        echo "Python Services:"
        for file in /etc/systemd/system/*.service; do
            [ -f "$file" ] || continue
            if grep -qi "python" "$file"; then
                basename "$file"
            fi
        done
        ;;

    mk)
        if [ -z "$2" ]; then
            echo "Usage:"
            echo "  svc mk <service-name>"
            exit 1
        fi

        cat >/etc/systemd/system/$2.service <<EOL
[Unit]
Description=$2
After=network.target

[Service]
WorkingDirectory=/data/$2
ExecStart=/data/$2/venv/bin/python /data/$2/main.py
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOL

        systemctl daemon-reload

        echo
        echo "✓ 已创建:"
        echo "/etc/systemd/system/$2.service"
        ;;

    rm)
        if [ -z "$2" ]; then
            echo "Usage: svc rm <service>"
            exit 1
        fi

        systemctl stop "$2" 2>/dev/null
        systemctl disable "$2" 2>/dev/null

        rm -f /etc/systemd/system/$2.service

        systemctl daemon-reload
        systemctl reset-failed

        echo "✓ 已删除 $2.service"
        ;;

    *)
        cat <<EOL

========== Service Manager ==========

svc start <service>
svc stop <service>
svc restart <service>
svc reload <service>
svc status <service>

svc enable <service>
svc disable <service>

svc now <service>        启动并开机自启
svc off <service>        停止并取消开机自启

svc rf <service>         重置失败服务

svc log <service>        实时日志
svc logs <service> [n]   最近 n 行日志(默认100)

svc cat <service>        查看service
svc edit <service>       编辑service

svc active <service>
svc enabled <service>

svc ls                   正在运行的服务
svc files                所有service
svc fail                 查看失败服务

svc py                   查看Python服务

svc mk <service>         创建Python服务模板
svc rm <service>         删除service

svc dr                   daemon-reload

====================================

EOL
        ;;
esac
EOF

chmod +x /usr/local/bin/svc

