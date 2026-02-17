#!/bin/bash

# 紧凑版本：只显示 user@IP:port

# 检查是否为 SSH 连接
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    # 获取当前用户
    current_user=$(whoami)
    
    # 获取 IP 和端口
    if [ -n "$SSH_CONNECTION" ]; then
        read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    elif [ -n "$SSH_CLIENT" ]; then
        read client_ip client_port server_port <<< "$SSH_CLIENT"
        server_ip=$(hostname -I | awk '{print $1}')
    else
        server_ip=$(hostname -I | awk '{print $1}')
        server_port=22
    fi
    
    # 显示：@ user@IP:port
    echo "@ ${current_user}@${server_ip}:${server_port}"
else
    echo ""
fi
