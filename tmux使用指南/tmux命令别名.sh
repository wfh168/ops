#!/bin/bash
# Tmux 命令别名配置 - 简化版
# 将这些别名添加到 ~/.bashrc 或 ~/.zshrc

# 连接会话
alias ta='tmux attach -t'

# 创建会话
alias tn='tmux new -s'

echo "Tmux 别名已加载！"
echo "  ta <name>  - 连接会话"
echo "  tn <name>  - 创建会话"
