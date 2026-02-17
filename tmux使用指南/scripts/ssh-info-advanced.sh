#!/bin/bash

# 高级版本：显示更多 SSH 配置信息

if [ -n "$SSH_CONNECTION" ]; then
    hostname=$(hostname -s)
    
    # 读取 sshd_config 配置
    if [ -r /etc/ssh/sshd_config ]; then
        # 读取端口配置
        port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
        [ -z "$port" ] && port=22
        
        # 读取是否允许密码登录
        password_auth=$(grep -E "^PasswordAuthentication " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
        
        # 读取是否允许 root 登录
        root_login=$(grep -E "^PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
        
        # 构建显示信息
        info="@ ${hostname}:${port}"
        
        # 添加安全标识
        if [ "$password_auth" = "no" ]; then
            info="${info} 🔑"  # 只允许密钥登录
        fi
        
        if [ "$root_login" = "no" ]; then
            info="${info} 🛡️"  # 禁止 root 登录
        fi
        
        echo "$info"
    else
        # 无法读取配置，使用基本信息
        read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
        echo "@ ${hostname}:${server_port}"
    fi
else
    echo ""
fi
