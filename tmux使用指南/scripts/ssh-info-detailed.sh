#!/bin/bash

# 详细版本：完全兼容所有 SSH 连接方式
# 支持：ssh user@ip, ssh hostname, ~/.ssh/config 配置
# 显示：user@hostname:port (IP)，非标准端口用颜色警告

# 检查是否为 SSH 连接（支持多种检测方式）
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    # 获取当前用户
    current_user=$(whoami)
    
    # 获取主机名（短格式）
    hostname=$(hostname -s)
    
    # 获取端口和 IP
    if [ -n "$SSH_CONNECTION" ]; then
        # SSH_CONNECTION 格式: client_ip client_port server_ip server_port
        read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
        port=$server_port
    elif [ -n "$SSH_CLIENT" ]; then
        # SSH_CLIENT 格式: client_ip client_port server_port
        read client_ip client_port server_port <<< "$SSH_CLIENT"
        server_ip=$(hostname -I | awk '{print $1}')
        port=$server_port
    else
        # 降级方案
        server_ip=$(hostname -I | awk '{print $1}')
        port=22
    fi
    
    # 如果无法获取 IP，使用主机名
    [ -z "$server_ip" ] && server_ip=$(hostname -I | awk '{print $1}')
    
    # 检测是否为非标准端口
    if [ "$port" != "22" ]; then
        # 非标准端口用黄色警告
        echo "#[fg=#f9e2af]@ ${current_user}@${hostname}:${port}#[fg=#7f849c] (${server_ip})"
    else
        # 标准端口
        echo "@ ${current_user}@${hostname}:${port} (${server_ip})"
    fi
else
    # 本地连接，不显示
    echo ""
fi
