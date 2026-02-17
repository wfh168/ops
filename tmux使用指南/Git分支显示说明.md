# Tmux 状态栏 Git 分支显示

## ✅ 已添加功能

在状态栏最左侧显示当前目录的 Git 分支（绿色显示）。

## 🎨 显示效果

```
[Session名]  main | CPU 10% | MEM 8G/16G | / 50G/100G | HOME 20G/50G | 2024-02-09 15:30
            ^^^^
         Git 分支
```

## 📖 功能说明

### 显示规则

- ✅ **在 Git 仓库中**：显示当前分支名（如 `main`、`develop`、`feature/login`）
- ✅ **不在 Git 仓库中**：不显示任何内容
- ✅ **自动更新**：切换目录时自动更新分支信息
- ✅ **颜色标识**：绿色显示，易于识别

### 显示位置

Git 分支显示在状态栏右侧的**最左边**，在 CPU 信息之前。

## 🚀 使用方法

### 1. 应用配置

```bash
# 复制新配置
cp tmux使用指南/.tmux.conf ~/.tmux.conf

# 重新加载配置
tmux source ~/.tmux.conf
```

### 2. 测试显示

```bash
# 进入一个 Git 仓库
cd ~/projects/my-project

# 查看状态栏，应该显示当前分支
# 例如：main 或 develop

# 切换分支
git checkout develop

# 状态栏会自动更新显示新分支
```

### 3. 切换窗格测试

```bash
# 分割窗格
Ctrl+a |

# 左边窗格：进入 Git 仓库
cd ~/projects/project-a

# 右边窗格：进入另一个 Git 仓库
Ctrl+a l
cd ~/projects/project-b

# 切换窗格时，状态栏会显示当前窗格所在目录的 Git 分支
```

## 🎨 自定义显示

### 1. 修改颜色

在 `~/.tmux.conf` 中修改：

```bash
# 当前配置（绿色）
#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /')

# 改为蓝色
#[fg=#89b4fa]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /')

# 改为黄色
#[fg=#f9e2af]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /')

# 改为红色
#[fg=#f38ba8]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /')
```

### 2. 添加 Git 图标

```bash
# 添加  图标
#[fg=#a6e3a1] #(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null)

# 添加 🌿 图标
#[fg=#a6e3a1]🌿#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null)
```

### 3. 显示更多 Git 信息

```bash
# 显示分支和状态（是否有未提交的更改）
#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null)#[fg=#f38ba8]#(cd #{pane_current_path}; git status --short 2>/dev/null | wc -l | sed 's/^0$//' | sed 's/^/ */')

# 显示分支和最后提交信息
#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null) #[fg=#7f849c]#(cd #{pane_current_path}; git log -1 --pretty=format:'%s' 2>/dev/null | cut -c1-20)
```

### 4. 简化版（只在 Git 仓库中显示）

```bash
# 最简版本
set -g status-right "#[fg=#a6e3a1]#(cd #{pane_current_path}; git branch --show-current 2>/dev/null) #[fg=#89b4fa]%H:%M"
```

## 🔧 高级配置

### 1. 显示 Git 状态指示器

创建脚本 `~/.tmux/scripts/git-status.sh`：

```bash
#!/bin/bash

cd "$1" 2>/dev/null || exit 0

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    exit 0
fi

# 获取分支名
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# 检查状态
if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    # 有未提交的更改（红色星号）
    echo " $branch*"
else
    # 干净的工作区（绿色对勾）
    echo " $branch✓"
fi
```

使用：
```bash
chmod +x ~/.tmux/scripts/git-status.sh

# 在 ~/.tmux.conf 中
set -g status-right "#[fg=#a6e3a1]#(~/.tmux/scripts/git-status.sh '#{pane_current_path}') ..."
```

### 2. 显示远程分支领先/落后信息

创建脚本 `~/.tmux/scripts/git-sync.sh`：

```bash
#!/bin/bash

cd "$1" 2>/dev/null || exit 0

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# 获取远程分支
upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)

if [[ -n "$upstream" ]]; then
    # 计算领先/落后的提交数
    ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
    behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
    
    sync=""
    [[ $ahead -gt 0 ]] && sync+="↑$ahead"
    [[ $behind -gt 0 ]] && sync+="↓$behind"
    
    echo " $branch $sync"
else
    echo " $branch"
fi
```

### 3. 完整的 Git 信息显示

```bash
# 在 ~/.tmux.conf 中
set -g status-right "\
#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /') \
#[fg=#f38ba8]#(cd #{pane_current_path}; [[ -n \$(git status --porcelain 2>/dev/null) ]] && echo '*') \
#[fg=#fab387]│ CPU #{cpu_percentage} \
#[fg=#fab387]│ #[fg=#89b4fa]%H:%M \
"
```

## 📊 不同场景的配置

### 场景 1：极简版（只显示分支）

```bash
set -g status-right "#[fg=#a6e3a1]#(cd #{pane_current_path}; git branch --show-current 2>/dev/null) #[fg=#89b4fa]%H:%M"
```

### 场景 2：标准版（分支 + 系统信息）

```bash
set -g status-right "#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /') #[fg=#fab387]│ CPU #{cpu_percentage} #[fg=#fab387]│ #[fg=#89b4fa]%H:%M"
```

### 场景 3：完整版（当前配置）

```bash
set -g status-right "#[fg=#a6e3a1]#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/ /') #[fg=#fab387]│ CPU #{cpu_percentage} #[fg=#fab387]│ MEM ... #[fg=#89b4fa]%H:%M"
```

### 场景 4：开发者版（分支 + 状态 + 同步信息）

```bash
set -g status-right "\
#[fg=#a6e3a1]#(~/.tmux/scripts/git-status.sh '#{pane_current_path}') \
#[fg=#89dceb]#(~/.tmux/scripts/git-sync.sh '#{pane_current_path}') \
#[fg=#fab387]│ #[fg=#89b4fa]%H:%M \
"
```

## 🐛 故障排查

### 问题 1：Git 分支不显示

**检查：**
```bash
# 测试命令是否工作
cd ~/your-git-repo
git rev-parse --abbrev-ref HEAD

# 应该输出分支名，如：main
```

**解决：**
```bash
# 确保在 Git 仓库中
git status

# 如果不是 Git 仓库，初始化
git init
```

### 问题 2：显示位置不对

**原因：** 状态栏长度不够

**解决：**
```bash
# 增加状态栏长度
set -g status-right-length 200
```

### 问题 3：更新不及时

**原因：** 状态栏刷新间隔太长

**解决：**
```bash
# 减少刷新间隔
set -g status-interval 2    # 2 秒刷新一次
```

### 问题 4：性能问题

**原因：** Git 命令执行太频繁

**解决：**
```bash
# 增加刷新间隔
set -g status-interval 5    # 5 秒刷新一次

# 或使用缓存脚本
```

## 💡 使用技巧

### 1. 快速识别当前分支

在多个项目间切换时，状态栏会自动显示当前窗格所在目录的 Git 分支，无需手动执行 `git branch`。

### 2. 结合窗口名称

```bash
# 重命名窗口为项目名
Ctrl+a ,
# 输入：project-a

# 现在状态栏显示：
# [Session] project-a  main | ...
```

### 3. 多项目开发

```bash
# 窗口 1：项目 A（main 分支）
cd ~/projects/project-a

# 窗口 2：项目 B（develop 分支）
Ctrl+a c
cd ~/projects/project-b

# 切换窗口时，状态栏自动显示对应的分支
```

## 🎨 颜色参考

```bash
# Catppuccin 配色
#[fg=#a6e3a1]  # 绿色（推荐用于 Git 分支）
#[fg=#89b4fa]  # 蓝色
#[fg=#f9e2af]  # 黄色
#[fg=#f38ba8]  # 红色
#[fg=#fab387]  # 橙色
#[fg=#89dceb]  # 青色
#[fg=#cba6f7]  # 紫色
#[fg=#7f849c]  # 灰色
```

## 📚 相关文档

- [高级用法指南.md](./高级用法指南.md) - 更多 Git 集成技巧
- [常用命令.md](./常用命令.md) - 状态栏配置命令
- [问题修复.md](./问题修复.md) - 配置问题排查

---

**现在你的 Tmux 状态栏可以显示 Git 分支了！** 🎉
