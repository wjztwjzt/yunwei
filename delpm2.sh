pm2 stop all
pm2 delete all
pm2 save

pm2 unstartup
# 按照提示再执行它输出的那条 sudo env ... 命令

npm uninstall -g pm2

rm -rf /root/.pm2
