#!/bin/bash

# 调试版本 - 显示详细信息

echo "=== SSH Info Debug ===" >&2

# 检查 SSH_CONNECTION
echo "SSH_CONNECTION: $SSH_CONNECTION" >&2

# 检查 SSH_CLIENT
echo "SSH_CLIENT: $SSH_CLIENT" >&2

# 检查 SSH_TTY
echo "SSH_TTY: $SSH_TTY" >&2

# 主逻辑
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    hostname=$(hostname -s)
    
    # 尝试读取 sshd_config
    if [ -r /etc/ssh/sshd_config ]; then
        port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
        [ -z "$port" ] && port=22
        echo "Port from config: $port" >&2
    else
        port=22
        echo "Cannot read sshd_config, using default port 22" >&2
    fi
    
    # 获取 IP
    if [ -n "$SSH_CONNECTION" ]; then
        read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
        echo "Server IP: $server_ip" >&2
    else
        server_ip=$(hostname -I | awk '{print $1}')
        echo "Server IP (from hostname): $server_ip" >&2
    fi
    
    # 输出结果
    result="@ ${hostname}:${port} (${server_ip})"
    echo "Output: $result" >&2
    echo "$result"
else
    echo "Not an SSH connection" >&2
    echo ""
fi
