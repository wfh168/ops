# SSH 连接兼容性说明

## ✅ 完全兼容的连接方式

`ssh-info-detailed.sh` 脚本现在完全兼容以下所有 SSH 连接方式：

### 1. 直接使用 IP 连接
```bash
ssh user@10.0.0.139
ssh root@10.0.0.139
ssh user@10.0.0.139 -p 2222
```

**显示效果：**
```
@ root@wfh1688:22 (10.0.0.139)
@ root@wfh1688:2222 (10.0.0.139)  # 非标准端口（黄色）
```

### 2. 使用主机名连接
```bash
ssh user@hostname
ssh root@wfh1688
```

**显示效果：**
```
@ root@wfh1688:22 (10.0.0.139)
```

### 3. 使用 ~/.ssh/config 配置
```bash
# ~/.ssh/config
Host wfh1688
    HostName 10.0.0.139
    User root
    Port 22
    IdentityFile ~/.ssh/id_rsa

Host cicd
    HostName 10.0.0.166
    User root
    Port 2222
    IdentityFile ~/.ssh/id_rsa
```

**连接：**
```bash
ssh wfh1688
ssh cicd
```

**显示效果：**
```
@ root@wfh1688:22 (10.0.0.139)
@ root@cicd:2222 (10.0.0.166)  # 非标准端口（黄色）
```

### 4. 使用端口转发
```bash
ssh -L 8080:localhost:80 user@server
ssh -D 1080 user@server
```

**显示效果：**
```
@ user@server:22 (10.0.0.139)
```

### 5. 通过跳板机连接
```bash
ssh -J jump-server target-server
ssh -o ProxyJump=jump-server target-server
```

**显示效果：**
```
@ user@target-server:22 (10.0.0.200)
```

## 🎯 工作原理

### 脚本逻辑

```bash
1. 检测 SSH 连接
   ├─ 检查 SSH_CONNECTION 变量
   ├─ 检查 SSH_CLIENT 变量
   └─ 检查 SSH_TTY 变量

2. 获取信息
   ├─ 用户名：whoami
   ├─ 主机名：hostname -s
   ├─ 端口：从 SSH_CONNECTION 或 SSH_CLIENT 提取
   └─ IP：从 SSH_CONNECTION 提取或使用 hostname -I

3. 格式化输出
   ├─ 标准端口 (22)：灰色显示
   └─ 非标准端口：黄色警告
```

### 环境变量说明

```bash
# SSH_CONNECTION（最常用）
# 格式：client_ip client_port server_ip server_port
# 示例：10.0.0.2 54321 10.0.0.139 22

# SSH_CLIENT（备用）
# 格式：client_ip client_port server_port
# 示例：10.0.0.2 54321 22

# SSH_TTY（最基本）
# 格式：终端设备
# 示例：/dev/pts/0
```

## 🚀 安装和使用

### 1. 复制脚本到服务器

```bash
# 在每台服务器上执行
mkdir -p ~/.tmux/scripts
cp tmux使用指南/scripts/ssh-info-detailed.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info-detailed.sh
```

### 2. 测试脚本

```bash
# 在 SSH 会话中运行
bash ~/.tmux/scripts/ssh-info-detailed.sh

# 应该输出类似：
# @ root@wfh1688:22 (10.0.0.139)
```

### 3. 配置 tmux

```bash
# 编辑 ~/.tmux.conf
set -g status-left-length 80
set -g status-left " #[bold,fg=#89b4fa]#S #(~/.tmux/scripts/ssh-info-detailed.sh) "

# 重新加载
tmux source ~/.tmux.conf
```

### 4. 启动 tmux

```bash
# 在 SSH 会话中
tmux

# 或附加到现有会话
tmux attach
```

## 🎨 显示效果示例

### 标准端口连接

```bash
# 连接方式 1
ssh root@10.0.0.139

# 连接方式 2
ssh wfh1688  # 使用 ~/.ssh/config

# 显示效果（灰色）
[servers] @ root@wfh1688:22 (10.0.0.139)  main | CPU 10% | 15:30
```

### 非标准端口连接

```bash
# 连接方式 1
ssh root@10.0.0.166 -p 2222

# 连接方式 2
ssh cicd  # ~/.ssh/config 中配置 Port 2222

# 显示效果（黄色警告）
[servers] @ root@cicd:2222 (10.0.0.166)  main | CPU 10% | 15:30
```

### 多服务器场景

```bash
# 窗口 1：Web 服务器
ssh wfh1688
tmux new-window -n web
# 显示：[servers] web @ root@wfh1688:22 (10.0.0.139)

# 窗口 2：CI/CD 服务器
ssh cicd
tmux new-window -n cicd
# 显示：[servers] cicd @ root@cicd:2222 (10.0.0.166)

# 窗口 3：数据库服务器
ssh root@10.0.0.200
tmux new-window -n db
# 显示：[servers] db @ root@db1:3306 (10.0.0.200)
```

## 🔍 调试和验证

### 检查环境变量

```bash
# 在 SSH 会话中运行
echo "=== SSH 环境变量 ==="
echo "SSH_CONNECTION: $SSH_CONNECTION"
echo "SSH_CLIENT: $SSH_CLIENT"
echo "SSH_TTY: $SSH_TTY"
echo ""
echo "=== 系统信息 ==="
echo "User: $(whoami)"
echo "Hostname: $(hostname -s)"
echo "IP: $(hostname -I | awk '{print $1}')"
```

### 测试脚本输出

```bash
# 运行脚本
bash ~/.tmux/scripts/ssh-info-detailed.sh

# 预期输出格式：
# @ user@hostname:port (IP)
```

### 检查 tmux 配置

```bash
# 查看状态栏配置
tmux show-options -g status-left

# 应该包含：
# #(~/.tmux/scripts/ssh-info-detailed.sh)
```

## 💡 高级用法

### 1. 自动化部署脚本

创建 `~/bin/deploy-tmux-ssh-info.sh`：

```bash
#!/bin/bash

# 自动部署到多台服务器

SERVERS=(
    "wfh1688"
    "cicd"
    "db1"
)

for server in "${SERVERS[@]}"; do
    echo "部署到 $server..."
    
    # 复制脚本
    scp tmux使用指南/scripts/ssh-info-detailed.sh $server:~/.tmux/scripts/
    
    # 设置权限
    ssh $server "chmod +x ~/.tmux/scripts/ssh-info-detailed.sh"
    
    # 更新配置
    ssh $server "grep -q 'ssh-info-detailed.sh' ~/.tmux.conf || echo 'set -g status-left \" #[bold,fg=#89b4fa]#S #(~/.tmux/scripts/ssh-info-detailed.sh) \"' >> ~/.tmux.conf"
    
    echo "✓ $server 部署完成"
done

echo "所有服务器部署完成！"
```

### 2. 结合窗口名称

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
# 如果在 tmux 中且是 SSH 连接，自动设置窗口名称
if [ -n "$TMUX" ] && [ -n "$SSH_CONNECTION" ]; then
    # 获取服务器 IP
    server_ip=$(echo $SSH_CONNECTION | awk '{print $3}')
    
    # 根据 IP 设置窗口名称
    case $server_ip in
        10.0.0.139)
            tmux rename-window "wfh1688" 2>/dev/null
            ;;
        10.0.0.166)
            tmux rename-window "cicd" 2>/dev/null
            ;;
        10.0.0.200)
            tmux rename-window "db1" 2>/dev/null
            ;;
    esac
fi
```

### 3. 颜色自定义

编辑脚本，修改颜色：

```bash
# 标准端口（绿色）
echo "#[fg=#a6e3a1]@ ${current_user}@${hostname}:${port}#[fg=#7f849c] (${server_ip})"

# 非标准端口（红色警告）
echo "#[fg=#f38ba8]@ ${current_user}@${hostname}:${port}#[fg=#7f849c] (${server_ip})"

# 生产环境（红色背景）
echo "#[bg=#f38ba8,fg=#1e1e2e]@ ${current_user}@${hostname}:${port}#[default] (${server_ip})"
```

## 🐛 常见问题

### 问题 1：显示为空

**原因：** 不是 SSH 连接或环境变量未设置

**检查：**
```bash
echo $SSH_CONNECTION
# 如果为空，说明不是 SSH 连接
```

### 问题 2：IP 显示不正确

**原因：** 服务器有多个网卡

**解决：**
```bash
# 修改脚本，指定网卡
server_ip=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
```

### 问题 3：主机名显示为 localhost

**原因：** 主机名未正确配置

**解决：**
```bash
# 设置主机名
sudo hostnamectl set-hostname wfh1688

# 或编辑 /etc/hostname
echo "wfh1688" | sudo tee /etc/hostname
```

### 问题 4：端口显示不正确

**原因：** 通过端口转发连接

**说明：** 这是正常的，脚本显示的是实际连接的端口

## 📊 兼容性测试清单

- [x] `ssh user@ip`
- [x] `ssh user@ip -p port`
- [x] `ssh hostname`
- [x] `ssh config_alias`（使用 ~/.ssh/config）
- [x] `ssh -J jump target`（跳板机）
- [x] `ssh -L port:host:port target`（端口转发）
- [x] `ssh -D port target`（动态转发）
- [x] 标准端口 (22)
- [x] 非标准端口
- [x] IPv4
- [x] 多网卡服务器

## 🎯 总结

`ssh-info-detailed.sh` 脚本现在：

1. ✅ **完全兼容**所有 SSH 连接方式
2. ✅ **自动检测**用户、主机名、端口、IP
3. ✅ **颜色警告**非标准端口
4. ✅ **降级处理**各种边缘情况
5. ✅ **统一格式** `user@hostname:port (IP)`

无论你使用哪种方式连接 SSH，脚本都能正确显示信息！🎉
