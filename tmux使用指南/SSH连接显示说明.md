# Tmux SSH 连接信息显示

## ✅ 已添加功能

在状态栏左侧显示 SSH 连接信息（主机名和端口号）。

## 🎨 显示效果

### 本地连接
```
[Session名] ...
```

### SSH 连接
```
[Session名] @ server1:22 ...
[Session名] @ web-server:2222 ...
```

## 📖 功能说明

### 显示规则

- ✅ **SSH 连接时**：显示 `@ 主机名:端口号`
- ✅ **本地连接时**：不显示任何内容
- ✅ **自动检测**：无需手动配置
- ✅ **灰色显示**：不抢眼，但易于识别

### 显示信息

- **主机名**：短主机名（不含域名）
- **端口号**：SSH 服务器监听的端口
- **格式**：`@ hostname:port`

## 🚀 安装步骤

### 1. 创建脚本目录

```bash
mkdir -p ~/.tmux/scripts
```

### 2. 复制脚本

```bash
# 复制 SSH 信息脚本
cp tmux使用指南/scripts/ssh-info.sh ~/.tmux/scripts/

# 添加执行权限
chmod +x ~/.tmux/scripts/ssh-info.sh
```

### 3. 应用配置

```bash
# 复制新配置
cp tmux使用指南/.tmux.conf ~/.tmux.conf

# 重新加载
tmux source ~/.tmux.conf
```

### 4. 测试效果

```bash
# 本地测试（不显示 SSH 信息）
tmux

# SSH 连接测试
ssh user@server
tmux

# 应该显示：[Session名] @ server:22 ...
```

## 🔧 自定义配置

### 1. 修改显示格式

编辑 `~/.tmux/scripts/ssh-info.sh`：

```bash
# 只显示主机名
echo "@ ${hostname}"

# 显示完整格式
echo "[SSH: ${hostname}:${server_port}]"

# 添加图标
echo " ${hostname}:${server_port}"

# 显示用户名和主机名
echo "@ ${USER}@${hostname}:${server_port}"
```

### 2. 修改颜色

在 `~/.tmux.conf` 中修改：

```bash
# 当前配置（灰色）
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info.sh) "

# 改为红色（醒目）
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#f38ba8]#(~/.tmux/scripts/ssh-info.sh) "

# 改为黄色
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#f9e2af]#(~/.tmux/scripts/ssh-info.sh) "

# 改为绿色
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#a6e3a1]#(~/.tmux/scripts/ssh-info.sh) "
```

### 3. 显示更多信息

编辑 `~/.tmux/scripts/ssh-info.sh`：

```bash
#!/bin/bash

if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    hostname=$(hostname -s)
    
    # 显示客户端 IP
    echo "@ ${hostname}:${server_port} from ${client_ip}"
    
    # 或显示服务器 IP
    echo "@ ${hostname}:${server_port} (${server_ip})"
    
    # 或显示用户名
    echo "@ ${USER}@${hostname}:${server_port}"
else
    echo ""
fi
```

### 4. 添加 SSH 状态指示器

```bash
#!/bin/bash

if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    hostname=$(hostname -s)
    
    # 添加 SSH 图标
    echo " @ ${hostname}:${server_port}"
    
    # 或使用其他图标
    echo "🔒 ${hostname}:${server_port}"
    echo "🌐 ${hostname}:${server_port}"
else
    echo ""
fi
```

## 📊 不同场景的配置

### 场景 1：极简版（只显示主机名）

```bash
#!/bin/bash
if [ -n "$SSH_CONNECTION" ]; then
    echo "@ $(hostname -s)"
fi
```

### 场景 2：标准版（主机名 + 端口）

```bash
#!/bin/bash
if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    echo "@ $(hostname -s):${server_port}"
fi
```

### 场景 3：详细版（用户 + 主机 + 端口）

```bash
#!/bin/bash
if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    echo "@ ${USER}@$(hostname -s):${server_port}"
fi
```

### 场景 4：完整版（包含客户端信息）

```bash
#!/bin/bash
if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    hostname=$(hostname -s)
    echo "@ ${hostname}:${server_port} ← ${client_ip}"
fi
```

## 🎨 状态栏布局示例

### 本地连接
```
[work] | CPU 10% | MEM 8G/16G | 15:30
```

### SSH 连接（标准端口）
```
[work] @ server1:22 | CPU 10% | MEM 8G/16G | 15:30
```

### SSH 连接（自定义端口）
```
[work] @ web-server:2222 | CPU 10% | MEM 8G/16G | 15:30
```

### 多服务器场景
```
窗口 1: [work] @ web1:22 ...
窗口 2: [work] @ web2:22 ...
窗口 3: [work] @ db1:3306 ...
```

## 🔍 高级功能

### 1. 根据端口显示不同颜色

编辑 `~/.tmux/scripts/ssh-info.sh`：

```bash
#!/bin/bash

if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    hostname=$(hostname -s)
    
    # 根据端口选择颜色
    if [ "$server_port" = "22" ]; then
        # 标准端口（绿色）
        echo "#[fg=#a6e3a1]@ ${hostname}:${server_port}#[default]"
    else
        # 非标准端口（黄色警告）
        echo "#[fg=#f9e2af]@ ${hostname}:${server_port}#[default]"
    fi
else
    echo ""
fi
```

### 2. 显示 SSH 会话时长

```bash
#!/bin/bash

if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    hostname=$(hostname -s)
    
    # 获取 SSH 进程启动时间
    ssh_pid=$(ps -o ppid= -p $$ | tr -d ' ')
    uptime=$(ps -o etime= -p $ssh_pid | tr -d ' ')
    
    echo "@ ${hostname}:${server_port} [${uptime}]"
else
    echo ""
fi
```

### 3. 显示网络延迟

```bash
#!/bin/bash

if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    hostname=$(hostname -s)
    
    # 测试到客户端的延迟（需要客户端允许 ping）
    ping_time=$(ping -c 1 -W 1 $client_ip 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
    
    if [ -n "$ping_time" ]; then
        echo "@ ${hostname}:${server_port} (${ping_time}ms)"
    else
        echo "@ ${hostname}:${server_port}"
    fi
else
    echo ""
fi
```

### 4. 显示服务器角色

创建配置文件 `~/.tmux/server-roles.conf`：

```bash
# 服务器角色配置
web1.example.com=WEB
web2.example.com=WEB
db1.example.com=DB
cache1.example.com=CACHE
```

修改脚本：

```bash
#!/bin/bash

if [ -n "$SSH_CONNECTION" ]; then
    read client_ip client_port server_ip server_port <<< "$SSH_CONNECTION"
    hostname=$(hostname -s)
    full_hostname=$(hostname -f)
    
    # 读取服务器角色
    role=$(grep "^${full_hostname}=" ~/.tmux/server-roles.conf 2>/dev/null | cut -d'=' -f2)
    
    if [ -n "$role" ]; then
        echo "@ ${hostname}:${server_port} [${role}]"
    else
        echo "@ ${hostname}:${server_port}"
    fi
else
    echo ""
fi
```

## 🐛 故障排查

### 问题 1：脚本不执行

**检查：**
```bash
# 测试脚本
~/.tmux/scripts/ssh-info.sh

# 检查权限
ls -l ~/.tmux/scripts/ssh-info.sh
```

**解决：**
```bash
# 添加执行权限
chmod +x ~/.tmux/scripts/ssh-info.sh
```

### 问题 2：显示为空

**检查：**
```bash
# 检查 SSH_CONNECTION 变量
echo $SSH_CONNECTION

# 应该显示类似：192.168.1.100 54321 192.168.1.1 22
```

**解决：**
```bash
# 如果为空，说明不是 SSH 连接
# 或者 SSH 配置有问题
```

### 问题 3：显示位置不对

**检查：**
```bash
# 检查状态栏左侧长度
tmux show-options -g status-left-length
```

**解决：**
```bash
# 增加长度
set -g status-left-length 60
```

### 问题 4：更新不及时

**原因：** 状态栏刷新间隔太长

**解决：**
```bash
# 减少刷新间隔
set -g status-interval 2
```

## 💡 使用技巧

### 1. 快速识别服务器

在多个 SSH 会话间切换时，状态栏会清楚显示当前连接的服务器和端口。

### 2. 结合窗口名称

```bash
# 重命名窗口为服务器用途
Ctrl+a ,
# 输入：web-server

# 现在状态栏显示：
# [Session] web-server @ web1:22 ...
```

### 3. 多服务器管理

```bash
# 窗口 1：Web 服务器
ssh web1.example.com
tmux
# 显示：@ web1:22

# 窗口 2：数据库服务器
Ctrl+a c
ssh db1.example.com
# 显示：@ db1:3306

# 切换窗口时，清楚知道当前在哪台服务器
```

### 4. 嵌套 SSH

```bash
# 本地 → 跳板机 → 目标服务器
ssh jump.example.com
tmux
# 显示：@ jump:22

# 在跳板机上再 SSH
ssh target.internal
# 显示：@ target:22
```

## 🎨 颜色参考

```bash
# Catppuccin 配色
#[fg=#7f849c]  # 灰色（默认，不抢眼）
#[fg=#a6e3a1]  # 绿色（安全/正常）
#[fg=#f9e2af]  # 黄色（警告/非标准端口）
#[fg=#f38ba8]  # 红色（重要/生产环境）
#[fg=#89b4fa]  # 蓝色（信息）
#[fg=#fab387]  # 橙色
```

## 📚 相关文档

- [高级用法指南.md](./高级用法指南.md) - 更多脚本化技巧
- [Git分支显示说明.md](./Git分支显示说明.md) - 状态栏自定义
- [常用命令.md](./常用命令.md) - 状态栏配置命令

## 🎯 完整配置示例

### 状态栏左侧（包含 SSH 信息）

```bash
set -g status-left-length 60
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info.sh) "
```

### 状态栏右侧（包含 Git 分支）

```bash
set -g status-right-length 200
set -g status-right "#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /') #[fg=#fab387]│ CPU #{cpu_percentage} #[fg=#fab387]│ #[fg=#89b4fa]%H:%M "
```

### 完整效果

```
[work] @ web1:22  main | CPU 10% | MEM 8G/16G | 15:30
```

---

**现在你的 Tmux 可以显示 SSH 连接信息了！** 🎉


---

## 🔧 从 sshd_config 读取端口配置

### 更新说明

脚本已更新为从 `/etc/ssh/sshd_config` 读取服务器配置的端口，而不是从连接信息获取。

### 工作原理

```bash
# 1. 检查是否为 SSH 连接
if [ -n "$SSH_CONNECTION" ]; then

# 2. 尝试读取 sshd_config
if [ -r /etc/ssh/sshd_config ]; then
    # 读取 Port 配置
    port=$(grep -E "^Port " /etc/ssh/sshd_config | head -1 | awk '{print $2}')
    
    # 如果没有配置，使用默认端口 22
    [ -z "$port" ] && port=22
fi
```

### 优势

- ✅ 显示服务器实际配置的端口
- ✅ 即使通过端口转发连接，也显示正确的端口
- ✅ 更准确反映服务器配置

### 权限要求

脚本需要读取 `/etc/ssh/sshd_config` 的权限：

```bash
# 检查权限
ls -l /etc/ssh/sshd_config

# 通常显示：
# -rw-r--r-- 1 root root 3289 Feb  9 10:00 /etc/ssh/sshd_config

# 普通用户可以读取（r--）
```

如果无法读取配置文件，脚本会自动降级使用 `SSH_CONNECTION` 变量。

## 📝 三个版本的脚本

### 版本 1：基础版（默认）

**文件：** `~/.tmux/scripts/ssh-info.sh`

**功能：**
- 从 `sshd_config` 读取端口
- 显示主机名和端口
- 简洁明了

**使用：**
```bash
cp tmux使用指南/scripts/ssh-info.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info.sh
```

### 版本 2：高级版

**文件：** `~/.tmux/scripts/ssh-info-advanced.sh`

**功能：**
- 读取端口配置
- 显示安全配置（密钥登录、root 禁用）
- 添加安全图标

**显示效果：**
```
@ server1:22 🔑 🛡️
```
- 🔑 = 只允许密钥登录
- 🛡️ = 禁止 root 登录

**使用：**
```bash
cp tmux使用指南/scripts/ssh-info-advanced.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info-advanced.sh

# 在 ~/.tmux.conf 中修改
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info-advanced.sh) "
```

### 版本 3：详细版（带颜色警告）

**文件：** `~/.tmux/scripts/ssh-info-detailed.sh`

**功能：**
- 读取端口配置
- 非标准端口用黄色显示
- 标准端口用灰色显示

**显示效果：**
```
@ server1:22        # 标准端口（灰色）
@ server2:2222      # 非标准端口（黄色）
```

**使用：**
```bash
cp tmux使用指南/scripts/ssh-info-detailed.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info-detailed.sh

# 在 ~/.tmux.conf 中修改
set -g status-left " #[bold,fg=#89b4fa]#S #(~/.tmux/scripts/ssh-info-detailed.sh) "
```

## 🎨 sshd_config 配置示例

### 标准配置

```bash
# /etc/ssh/sshd_config

# 端口配置
Port 22

# 安全配置
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

脚本会读取这些配置并显示相应信息。

### 多端口配置

```bash
# /etc/ssh/sshd_config

# 监听多个端口
Port 22
Port 2222
```

脚本会读取第一个端口（22）。

### 自定义端口

```bash
# /etc/ssh/sshd_config

# 自定义端口
Port 2222
```

脚本会显示：`@ hostname:2222`

## 🔍 调试和测试

### 测试脚本

```bash
# 手动运行脚本
~/.tmux/scripts/ssh-info.sh

# 应该输出类似：
# @ server1:22
```

### 检查 sshd_config

```bash
# 查看端口配置
grep "^Port " /etc/ssh/sshd_config

# 查看所有 SSH 配置
cat /etc/ssh/sshd_config | grep -v "^#" | grep -v "^$"
```

### 检查实际监听端口

```bash
# 查看 SSH 服务监听的端口
sudo ss -tlnp | grep sshd
# 或
sudo netstat -tlnp | grep sshd

# 应该显示类似：
# tcp   0   0 0.0.0.0:22   0.0.0.0:*   LISTEN   1234/sshd
```

### 对比配置端口和实际端口

```bash
# 配置的端口
grep "^Port " /etc/ssh/sshd_config

# 实际监听的端口
sudo ss -tlnp | grep sshd | awk '{print $4}' | cut -d: -f2
```

## 🛠️ 完整安装步骤

### 1. 创建脚本目录

```bash
mkdir -p ~/.tmux/scripts
```

### 2. 选择并复制脚本

**基础版（推荐）：**
```bash
cp tmux使用指南/scripts/ssh-info.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info.sh
```

**高级版（显示安全配置）：**
```bash
cp tmux使用指南/scripts/ssh-info-advanced.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info-advanced.sh
```

**详细版（颜色警告）：**
```bash
cp tmux使用指南/scripts/ssh-info-detailed.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info-detailed.sh
```

### 3. 更新配置

编辑 `~/.tmux.conf`：

```bash
# 基础版
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info.sh) "

# 高级版
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info-advanced.sh) "

# 详细版
set -g status-left " #[bold,fg=#89b4fa]#S #(~/.tmux/scripts/ssh-info-detailed.sh) "
```

### 4. 重新加载配置

```bash
tmux source ~/.tmux.conf
```

### 5. 测试

```bash
# SSH 到服务器
ssh user@server

# 启动 tmux
tmux

# 查看状态栏，应该显示：
# [Session名] @ server:22 ...
```

## 💡 实用场景

### 场景 1：端口转发

```bash
# 通过跳板机连接（端口转发）
ssh -L 2222:target:22 jump-server

# 然后连接
ssh -p 2222 localhost

# 状态栏会显示目标服务器配置的端口（22），而不是转发端口（2222）
```

### 场景 2：多端口服务器

```bash
# 服务器配置了多个端口
# /etc/ssh/sshd_config:
# Port 22
# Port 2222

# 无论从哪个端口连接，都显示配置的第一个端口（22）
```

### 场景 3：安全审计

使用高级版脚本，可以快速识别服务器的安全配置：

```bash
@ web1:22 🔑 🛡️    # 安全：密钥登录 + 禁止 root
@ web2:22          # 警告：可能允许密码登录
@ db1:3306 🔑      # 密钥登录，但允许 root
```

## 🎯 推荐配置

### 运维人员（推荐高级版）

```bash
# 显示端口 + 安全配置
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info-advanced.sh) "
```

### 开发人员（推荐基础版）

```bash
# 只显示主机名和端口
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info.sh) "
```

### 安全审计（推荐详细版）

```bash
# 非标准端口用颜色警告
set -g status-left " #[bold,fg=#89b4fa]#S #(~/.tmux/scripts/ssh-info-detailed.sh) "
```

---

**现在脚本会从 `/etc/ssh/sshd_config` 读取端口配置了！** 🎉
