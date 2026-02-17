#!/bin/bash

# 本地版本：从窗格的命令行获取 SSH 连接信息
# 适用于本地 tmux，显示你 SSH 连接到哪台服务器

# 获取当前窗格的命令
pane_pid=$(tmux display-message -p '#{pane_pid}')
pane_command=$(ps -o command= -p $pane_pid 2>/dev/null)

# 检查是否是 SSH 命令
if echo "$pane_command" | grep -q "^ssh "; then
    # 提取 SSH 参数
    ssh_args=$(echo "$pane_command" | sed 's/^ssh //')
    
    # 解析不同的 SSH 格式
    if echo "$ssh_args" | grep -q "@"; then
        # 格式：user@host 或 user@ip
        user_host=$(echo "$ssh_args" | awk '{print $1}')
        user=$(echo "$user_host" | cut -d@ -f1)
        host=$(echo "$user_host" | cut -d@ -f2)
        
        # 检查是否有 -p 参数指定端口
        if echo "$ssh_args" | grep -q "\-p "; then
            port=$(echo "$ssh_args" | sed -n 's/.*-p \([0-9]*\).*/\1/p')
        else
            port=22
        fi
    else
        # 格式：只有 hostname（使用 ~/.ssh/config）
        host=$(echo "$ssh_args" | awk '{print $1}')
        
        # 从 ~/.ssh/config 读取配置
        if [ -f ~/.ssh/config ]; then
            # 读取 User
            user=$(awk -v host="$host" '
                /^Host / { current_host=$2 }
                current_host == host && /^[[:space:]]*User / { print $2; exit }
            ' ~/.ssh/config)
            
            # 读取 HostName (IP)
            hostname=$(awk -v host="$host" '
                /^Host / { current_host=$2 }
                current_host == host && /^[[:space:]]*HostName / { print $2; exit }
            ' ~/.ssh/config)
            
            # 读取 Port
            port=$(awk -v host="$host" '
                /^Host / { current_host=$2 }
                current_host == host && /^[[:space:]]*Port / { print $2; exit }
            ' ~/.ssh/config)
            
            # 如果没有配置，使用默认值
            [ -z "$user" ] && user=$(whoami)
            [ -z "$hostname" ] && hostname=$host
            [ -z "$port" ] && port=22
        else
            user=$(whoami)
            hostname=$host
            port=22
        fi
    fi
    
    # 如果 hostname 未设置，使用 host
    [ -z "$hostname" ] && hostname=$host
    
    # 显示格式：@ user@host:port (IP)
    if [ "$port" != "22" ]; then
        # 非标准端口用黄色
        if [ "$hostname" != "$host" ]; then
            echo "#[fg=#f9e2af]@ ${user}@${host}:${port}#[fg=#7f849c] (${hostname})"
        else
            echo "#[fg=#f9e2af]@ ${user}@${host}:${port}"
        fi
    else
        # 标准端口
        if [ "$hostname" != "$host" ]; then
            echo "@ ${user}@${host}:${port} (${hostname})"
        else
            echo "@ ${user}@${host}:${port}"
        fi
    fi
else
    # 不是 SSH 连接，不显示
    echo ""
fi
