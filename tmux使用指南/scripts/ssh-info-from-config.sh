#!/bin/bash

# 从 ~/.ssh/config 读取 SSH 配置信息

# 检查是否为 SSH 连接
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    # 获取当前主机名
    current_hostname=$(hostname -s)
    
    # 获取服务器 IP
    if [ -n "$SSH_CONNECTION" ]; then
        read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    else
        server_ip=$(hostname -I | awk '{print $1}')
        server_port=22
    fi
    
    # 尝试从客户端的 SSH 配置文件匹配主机别名
    # 注意：这需要在客户端机器上运行，服务器端无法访问客户端的 ~/.ssh/config
    
    # 获取端口（优先从 sshd_config，其次从连接信息）
    if [ -r /etc/ssh/sshd_config ]; then
        port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
        [ -z "$port" ] && port=$server_port
    else
        port=$server_port
    fi
    
    # 显示格式：@ hostname:port (IP)
    if [ "$port" != "22" ]; then
        # 非标准端口用黄色
        echo "#[fg=#f9e2af]@ ${current_hostname}:${port}#[fg=#7f849c] (${server_ip})"
    else
        # 标准端口
        echo "@ ${current_hostname}:${port} (${server_ip})"
    fi
else
    echo ""
fi
