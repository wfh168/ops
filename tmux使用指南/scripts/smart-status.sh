#!/bin/bash

# 智能状态栏：自动检测本地或远程，显示对应的系统信息

# 获取当前窗格的 PID
pane_pid=$(tmux display-message -p '#{pane_pid}')

# 获取子进程
child_pid=$(pgrep -P $pane_pid | head -1)

if [ -n "$child_pid" ]; then
    pane_command=$(ps -o command= -p $child_pid 2>/dev/null)
else
    pane_command=$(ps -o command= -p $pane_pid 2>/dev/null)
fi

# 检查是否是 SSH 连接
if echo "$pane_command" | grep -q "^ssh "; then
    # ========== SSH 远程服务器 ==========
    
    # 提取 SSH 参数
    ssh_args=$(echo "$pane_command" | sed 's/^ssh //')
    
    # 解析主机信息
    if echo "$ssh_args" | grep -q "@"; then
        user_host=$(echo "$ssh_args" | awk '{print $1}')
        user=$(echo "$user_host" | cut -d@ -f1)
        host=$(echo "$user_host" | cut -d@ -f2)
        
        if echo "$ssh_args" | grep -q "\-p "; then
            port=$(echo "$ssh_args" | sed -n 's/.*-p \([0-9]*\).*/\1/p')
        else
            port=22
        fi
        
        hostname=$host
        ssh_host="$user@$host"
    else
        host=$(echo "$ssh_args" | awk '{print $1}')
        
        if [ -f ~/.ssh/config ]; then
            user=$(awk -v h="$host" 'BEGIN{IGNORECASE=1} /^Host[[:space:]]/ {if($2==h) found=1; else found=0} found && /^[[:space:]]*User[[:space:]]/ {print $2; exit}' ~/.ssh/config)
            hostname=$(awk -v h="$host" 'BEGIN{IGNORECASE=1} /^Host[[:space:]]/ {if($2==h) found=1; else found=0} found && /^[[:space:]]*HostName[[:space:]]/ {print $2; exit}' ~/.ssh/config)
            port=$(awk -v h="$host" 'BEGIN{IGNORECASE=1} /^Host[[:space:]]/ {if($2==h) found=1; else found=0} found && /^[[:space:]]*Port[[:space:]]/ {print $2; exit}' ~/.ssh/config)
            
            [ -z "$user" ] && user=$(whoami)
            [ -z "$hostname" ] && hostname=$host
            [ -z "$port" ] && port=22
        else
            user=$(whoami)
            hostname=$host
            port=22
        fi
        
        ssh_host="$user@$hostname"
    fi
    
    # 从远程服务器获取系统信息
    remote_info=$(ssh -o ConnectTimeout=2 -o BatchMode=yes $ssh_host "
        # CPU 使用率
        cpu=\$(top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1)
        [ -z \"\$cpu\" ] && cpu=\$(grep 'cpu ' /proc/stat | awk '{usage=(\$2+\$4)*100/(\$2+\$4+\$5)} END {printf \"%.0f\", usage}')
        
        # 内存使用
        mem=\$(free -h | awk 'NR==2{printf \"%s/%s\", \$3, \$2}')
        
        # 根分区使用
        disk=\$(df -h / | awk 'NR==2{print \$3\"/\"\$2}')
        
        echo \"CPU \${cpu}% | MEM \${mem} | / \${disk}\"
    " 2>/dev/null)
    
    # 显示格式
    if [ -n "$remote_info" ]; then
        if [ "$port" != "22" ]; then
            echo "#[fg=#f9e2af]@ ${user}@${host}:${port}#[fg=#7f849c] | ${remote_info}"
        else
            if [ "$hostname" != "$host" ]; then
                echo "@ ${user}@${host}:${port} (${hostname}) | ${remote_info}"
            else
                echo "@ ${user}@${host}:${port} | ${remote_info}"
            fi
        fi
    else
        # 无法获取远程信息，只显示连接信息
        if [ "$port" != "22" ]; then
            echo "#[fg=#f9e2af]@ ${user}@${host}:${port}"
        else
            if [ "$hostname" != "$host" ]; then
                echo "@ ${user}@${host}:${port} (${hostname})"
            else
                echo "@ ${user}@${host}:${port}"
            fi
        fi
    fi
else
    # ========== 本地系统 ==========
    
    # CPU 使用率
    cpu=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)
    [ -z "$cpu" ] && cpu=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.0f", usage}')
    
    # 内存使用
    mem=$(free -h | awk 'NR==2{printf "%s/%s", $3, $2}')
    
    # 根分区使用
    disk=$(df -h / | awk 'NR==2{print $3"/"$2}')
    
    # HOME 分区使用
    home=$(df -h /home | awk 'NR==2{print $3"/"$2}')
    
    echo "LOCAL | CPU ${cpu}% | MEM ${mem} | / ${disk} | HOME ${home}"
fi
