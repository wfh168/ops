#!/bin/bash

# 简单版本：显示 user@hostname:port (IP)

# 检查是否为 SSH 连接
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    # 获取当前用户
    current_user=$(whoami)
    
    # 获取主机名
    hostname=$(hostname -s)
    
    # 获取 IP 和端口
    if [ -n "$SSH_CONNECTION" ]; then
        # SSH_CONNECTION 格式: client_ip client_port server_ip server_port
        read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    elif [ -n "$SSH_CLIENT" ]; then
        # SSH_CLIENT 格式: client_ip client_port server_port
        read client_ip client_port server_port <<< "$SSH_CLIENT"
        server_ip=$(hostname -I | awk '{print $1}')
    else
        # 使用默认值
        server_ip=$(hostname -I | awk '{print $1}')
        server_port=22
    fi
    
    # 显示：@ user@hostname:port (IP)
    echo "@ ${current_user}@${hostname}:${server_port} (${server_ip})"
else
    echo ""
fi
