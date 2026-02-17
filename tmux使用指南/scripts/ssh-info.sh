#!/bin/bash

# 获取 SSH 连接信息
if [ -n "$SSH_CONNECTION" ]; then
    # 获取主机名
    hostname=$(hostname -s)
    
    # 尝试从 sshd_config 读取配置的端口
    if [ -r /etc/ssh/sshd_config ]; then
        # 读取 Port 配置（可能有多个，取第一个）
        port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
        
        # 如果没有配置 Port，使用默认端口 22
        if [ -z "$port" ]; then
            port=22
        fi
    else
        # 无法读取配置文件，从 SSH_CONNECTION 获取
        read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
        port=$server_port
    fi
    
    # 显示主机名和端口
    echo "@ ${hostname}:${port}"
else
    # 本地连接，不显示
    echo ""
fi
