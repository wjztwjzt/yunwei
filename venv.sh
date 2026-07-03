cat >> ~/.bashrc <<'EOF'

# Python venv aliases
alias vmk='python3 -m venv venv'
alias von='source venv/bin/activate'
alias voff='deactivate'
alias vpy='./venv/bin/python'
alias vpip='./venv/bin/pip'

EOF

source ~/.bashrc