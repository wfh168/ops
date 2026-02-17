# 本地 Tmux 显示 SSH 连接信息

## 🎯 正确的理解

你想在**本地电脑**的 tmux 状态栏显示你 SSH 连接到哪台服务器，而不是在服务器上显示。

## ✅ 解决方案

使用 `ssh-info-local.sh` 脚本，它会：
1. 检测当前窗格是否运行 SSH 命令
2. 从 SSH 命令或 `~/.ssh/config` 读取连接信息
3. 在本地 tmux 状态栏显示

## 🚀 安装步骤

### 1. 在本地电脑上创建脚本

```bash
# 在你的本地电脑上（不是服务器）
mkdir -p ~/.tmux/scripts

# 复制脚本
cp tmux使用指南/scripts/ssh-info-local.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info-local.sh
```

### 2. 更新本地 tmux 配置

```bash
# 复制新配置
cp tmux使用指南/.tmux.conf ~/.tmux.conf

# 重新加载
tmux source ~/.tmux.conf
```

### 3. 测试

```bash
# 在本地启动 tmux
tmux

# SSH 连接到服务器
ssh wfh1688

# 查看状态栏，应该显示：
# [servers] @ root@wfh1688:22 (10.0.0.139) | ...
```

## 🎨 显示效果

### 使用 ~/.ssh/config 别名

```bash
# 你的配置
Host wfh1688
    HostName 10.0.0.139
    User root
    Port 22

# 连接
ssh wfh1688

# 状态栏显示
[servers] @ root@wfh1688:22 (10.0.0.139) | CPU 10% | 15:30
```

### 直接使用 IP

```bash
# 连接
ssh root@10.0.0.139

# 状态栏显示
[servers] @ root@10.0.0.139:22 | CPU 10% | 15:30
```

### 自定义端口

```bash
# 连接
ssh root@10.0.0.166 -p 2222

# 状态栏显示（黄色警告）
[servers] @ root@10.0.0.166:2222 | CPU 10% | 15:30
```

## 📖 工作原理

### 脚本逻辑

```
1. 获取当前窗格的进程 ID
   ↓
2. 查看进程运行的命令
   ↓
3. 检查是否是 SSH 命令
   ↓
4. 解析 SSH 参数
   ├─ 如果是 user@host 格式 → 直接提取
   └─ 如果是 hostname 格式 → 从 ~/.ssh/config 读取
   ↓
5. 格式化输出到状态栏
```

### 支持的格式

| 连接方式 | 显示效果 |
|---------|---------|
| `ssh wfh1688` | `@ root@wfh1688:22 (10.0.0.139)` |
| `ssh root@10.0.0.139` | `@ root@10.0.0.139:22` |
| `ssh root@10.0.0.139 -p 2222` | `@ root@10.0.0.139:2222` |
| `ssh user@hostname` | `@ user@hostname:22` |

## 🔍 测试脚本

### 手动测试

```bash
# 在本地 tmux 中，SSH 连接后运行
~/.tmux/scripts/ssh-info-local.sh

# 应该输出类似：
# @ root@wfh1688:22 (10.0.0.139)
```

### 调试模式

```bash
# 查看当前窗格的命令
ps -o command= -p $(tmux display-message -p '#{pane_pid}')

# 应该显示类似：
# ssh wfh1688
# 或
# ssh root@10.0.0.139
```

## 💡 使用场景

### 场景 1：多服务器管理

```bash
# 本地 tmux
tmux new -s servers

# 窗口 1：Web 服务器
ssh wfh1688
# 状态栏：[servers] @ root@wfh1688:22 (10.0.0.139)

# 窗口 2：CI/CD 服务器
Ctrl+a c
ssh cicd
# 状态栏：[servers] @ root@cicd:22 (10.0.0.166)

# 窗口 3：数据库服务器
Ctrl+a c
ssh root@10.0.0.200
# 状态栏：[servers] @ root@10.0.0.200:22
```

### 场景 2：结合窗口名称

```bash
# SSH 连接后重命名窗口
ssh wfh1688
Ctrl+a ,
# 输入：web

# 状态栏显示：
# [servers] web @ root@wfh1688:22 (10.0.0.139)
```

### 场景 3：本地和远程混合

```bash
# 窗口 1：本地工作
# 状态栏：[work] 1:local

# 窗口 2：SSH 到服务器
Ctrl+a c
ssh wfh1688
# 状态栏：[work] 2:ssh @ root@wfh1688:22 (10.0.0.139)
```

## 🎨 完整配置示例

### ~/.ssh/config

```bash
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

Host db1
    HostName 10.0.0.200
    User mysql
    Port 3306
    IdentityFile ~/.ssh/id_rsa
```

### ~/.tmux.conf

```bash
# 状态栏左侧：会话名 + SSH 信息
set -g status-left-length 80
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info-local.sh) "

# 状态栏右侧：Git 分支 + 系统信息
set -g status-right-length 200
set -g status-right "#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /') #[fg=#fab387]│ CPU #{cpu_percentage} #[fg=#fab387]│ #[fg=#89b4fa]%H:%M "
```

## 🐛 故障排查

### 问题 1：状态栏不显示 SSH 信息

**检查：**
```bash
# 1. 脚本是否存在
ls -l ~/.tmux/scripts/ssh-info-local.sh

# 2. 脚本是否可执行
chmod +x ~/.tmux/scripts/ssh-info-local.sh

# 3. 手动运行脚本
~/.tmux/scripts/ssh-info-local.sh
```

### 问题 2：显示不正确

**检查：**
```bash
# 查看当前窗格的命令
ps -o command= -p $(tmux display-message -p '#{pane_pid}')

# 检查 ~/.ssh/config
cat ~/.ssh/config
```

### 问题 3：配置未生效

```bash
# 重新加载配置
tmux source ~/.tmux.conf

# 或重启 tmux
tmux kill-server
tmux
```

## 📊 对比：本地 vs 服务器端

| 方案 | 脚本位置 | 显示内容 | 适用场景 |
|------|---------|---------|---------|
| **本地方案** | 本地电脑 | SSH 连接信息 | 管理多台服务器 |
| 服务器方案 | 每台服务器 | 服务器自身信息 | 在服务器上工作 |

## 🎯 推荐配置

### 本地电脑（你的情况）

```bash
# 使用 ssh-info-local.sh
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info-local.sh) "
```

### 服务器（如果需要）

```bash
# 使用 ssh-info-detailed.sh
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info-detailed.sh) "
```

## ✅ 总结

现在脚本会：
1. ✅ 在**本地** tmux 运行
2. ✅ 从 `~/.ssh/config` 读取配置
3. ✅ 支持 `ssh user@ip` 格式
4. ✅ 支持 `ssh hostname` 格式
5. ✅ 显示 `user@host:port (IP)` 格式
6. ✅ 非标准端口用黄色警告

**在本地电脑上安装，不需要在服务器上做任何配置！** 🎉
