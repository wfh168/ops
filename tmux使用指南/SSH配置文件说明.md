# SSH 配置文件与 Tmux 状态栏显示

## 📋 你的 SSH 配置

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
    Port 22
    IdentityFile ~/.ssh/id_rsa
```

## 🎯 期望的显示效果

当你 SSH 连接到服务器后，状态栏应该显示：

```
[Session名] @ wfh1688:22 (10.0.0.139) | ...
[Session名] @ cicd:22 (10.0.0.166) | ...
```

## ⚠️ 重要说明

### 问题：服务器端无法读取客户端的 SSH 配置

当你 SSH 到服务器后：
- ❌ 服务器**无法访问**你本地的 `~/.ssh/config` 文件
- ❌ 服务器**不知道**你使用的主机别名（如 `wfh1688`）
- ✅ 服务器只知道自己的主机名（如 `wfh-B550i-GAMING`）

### 解决方案

有两种方式显示 SSH 信息：

#### 方案 1：显示服务器实际信息（推荐）

显示服务器的真实主机名、IP 和端口：

```
@ wfh-B550i-GAMING:22 (10.0.0.139)
```

#### 方案 2：在窗口名称中使用别名

手动设置窗口名称为 SSH 别名：

```bash
# SSH 连接后
ssh wfh1688
tmux

# 重命名窗口
Ctrl+a ,
# 输入：wfh1688

# 状态栏显示：
# [Session] wfh1688 @ wfh-B550i-GAMING:22 (10.0.0.139)
```

## 🚀 推荐配置

### 使用简单版脚本（显示主机名、端口、IP）

```bash
# 1. 复制脚本
cp tmux使用指南/scripts/ssh-info-simple.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/ssh-info-simple.sh

# 2. 修改 ~/.tmux.conf
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info-simple.sh) "

# 3. 重新加载
tmux source ~/.tmux.conf
```

### 显示效果

```
[servers] @ wfh1688:22 (10.0.0.139) | CPU 10% | ...
```

其中：
- `servers` = 会话名
- `wfh1688` = 服务器主机名
- `22` = SSH 端口
- `10.0.0.139` = 服务器 IP

## 🔧 测试步骤

### 1. SSH 连接到服务器

```bash
# 从本地连接
ssh wfh1688
```

### 2. 检查环境变量

```bash
# 在服务器上运行
echo "SSH_CONNECTION: $SSH_CONNECTION"
echo "SSH_CLIENT: $SSH_CLIENT"

# 应该显示类似：
# SSH_CONNECTION: 10.0.0.2 54321 10.0.0.139 22
# SSH_CLIENT: 10.0.0.2 54321 22
```

### 3. 测试脚本

```bash
# 在服务器上运行
bash ~/.tmux/scripts/ssh-info-simple.sh

# 应该输出：
# @ wfh1688:22 (10.0.0.139)
```

### 4. 启动 tmux

```bash
tmux

# 查看状态栏左侧，应该显示 SSH 信息
```

## 💡 高级用法：结合窗口名称

### 创建启动脚本

创建 `~/bin/ssh-tmux`：

```bash
#!/bin/bash

# SSH 连接并自动设置 tmux 窗口名称

if [ -z "$1" ]; then
    echo "Usage: ssh-tmux <host>"
    exit 1
fi

HOST=$1

# SSH 连接
ssh $HOST -t "
    # 创建或附加到会话
    if tmux has-session -t ssh 2>/dev/null; then
        tmux new-window -t ssh -n '$HOST'
        tmux attach -t ssh
    else
        tmux new-session -s ssh -n '$HOST'
    fi
"
```

使用：

```bash
chmod +x ~/bin/ssh-tmux

# 连接到 wfh1688
~/bin/ssh-tmux wfh1688

# tmux 窗口会自动命名为 "wfh1688"
```

## 📊 不同脚本的显示效果

### ssh-info-simple.sh（推荐）

```
@ wfh1688:22 (10.0.0.139)
```

显示：主机名 + 端口 + IP

### ssh-info-detailed.sh

```
@ wfh1688:22 (10.0.0.139)  # 标准端口（灰色）
@ cicd:2222 (10.0.0.166)   # 非标准端口（黄色）
```

非标准端口会用颜色警告。

### ssh-info-from-config.sh

```
@ wfh1688:22 (10.0.0.139)
```

尝试从配置文件读取，但在服务器端效果与 simple 版本相同。

## 🎨 完整的状态栏配置

### 配置文件

```bash
# ~/.tmux.conf

# 状态栏左侧：会话名 + SSH 信息
set -g status-left-length 80
set -g status-left " #[bold,fg=#89b4fa]#S #[fg=#7f849c]#(~/.tmux/scripts/ssh-info-simple.sh) "

# 状态栏右侧：Git 分支 + 系统信息
set -g status-right-length 200
set -g status-right "#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /') #[fg=#fab387]│ CPU #{cpu_percentage} #[fg=#fab387]│ #[fg=#89b4fa]%H:%M "
```

### 显示效果

```
[servers] @ wfh1688:22 (10.0.0.139)  main | CPU 10% | 15:30
```

## 🔍 调试命令

### 在服务器上运行

```bash
# 1. 检查是否为 SSH 连接
echo $SSH_CONNECTION

# 2. 测试脚本
bash ~/.tmux/scripts/ssh-info-simple.sh

# 3. 查看 tmux 配置
tmux show-options -g status-left

# 4. 重新加载配置
tmux source ~/.tmux.conf
```

## 💡 实用技巧

### 技巧 1：自动设置窗口名称

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
# 如果在 tmux 中且是 SSH 连接，设置窗口名称
if [ -n "$TMUX" ] && [ -n "$SSH_CONNECTION" ]; then
    # 从 SSH_CONNECTION 获取服务器 IP
    server_ip=$(echo $SSH_CONNECTION | awk '{print $3}')
    
    # 根据 IP 设置窗口名称
    case $server_ip in
        10.0.0.139)
            tmux rename-window "wfh1688"
            ;;
        10.0.0.166)
            tmux rename-window "cicd"
            ;;
    esac
fi
```

### 技巧 2：使用 SSH 配置的 LocalCommand

在 `~/.ssh/config` 中添加：

```bash
Host wfh1688
    HostName 10.0.0.139
    User root
    Port 22
    IdentityFile ~/.ssh/id_rsa
    # 连接后自动设置 tmux 窗口名称
    RemoteCommand tmux rename-window wfh1688 2>/dev/null; bash -l

Host cicd
    HostName 10.0.0.166
    User root
    Port 22
    IdentityFile ~/.ssh/id_rsa
    RemoteCommand tmux rename-window cicd 2>/dev/null; bash -l
```

### 技巧 3：创建别名

在 `~/.bashrc` 中：

```bash
# SSH 并自动命名 tmux 窗口
alias ssh-wfh='ssh wfh1688 -t "tmux new-window -n wfh1688 || tmux rename-window wfh1688; bash -l"'
alias ssh-cicd='ssh cicd -t "tmux new-window -n cicd || tmux rename-window cicd; bash -l"'
```

## 📚 总结

1. **服务器端脚本**只能显示服务器的实际信息（主机名、IP、端口）
2. **SSH 别名**（如 `wfh1688`）只存在于客户端配置中
3. **推荐方案**：
   - 使用 `ssh-info-simple.sh` 显示服务器信息
   - 手动或自动设置 tmux 窗口名称为 SSH 别名
   - 结合使用，获得最佳效果

---

**现在试试 `ssh-info-simple.sh` 脚本，应该可以显示主机名、端口和 IP 了！** 🎉
