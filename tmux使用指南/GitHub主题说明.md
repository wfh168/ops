# Tmux GitHub Light 主题说明

## 主题配色

配置文件已更新为 GitHub Light 浅色主题，与你的 Alacritty GitHub Light 配色完全匹配。

### 颜色方案（来自 Alacritty 配置）

| 元素 | 颜色代码 | Alacritty 对应 |
|------|---------|---------------|
| 状态栏背景 | `#f6f8fa` | 浅灰色背景 |
| 状态栏前景 | `#24292e` | primary.foreground（黑色文字） |
| 会话名背景 | `#0366d6` | normal.blue（蓝色） |
| 会话名文字 | `#ffffff` | primary.background（白色） |
| 窗格边框 | `#d1d5da` | bright.white（浅灰） |
| 活动窗格边框 | `#0366d6` | normal.blue（蓝色） |
| 当前窗口背景 | `#c8e1ff` | selection.background（浅蓝） |
| 当前窗口文字 | `#0366d6` | normal.blue（蓝色） |
| 普通窗口 | `#6a737d` | normal.white（灰色） |
| Git 分支 | `#28a745` | normal.green（绿色） |
| 分隔符 | `#d1d5da` | bright.white（浅灰） |
| 消息提示 | `#28a745` | normal.green（绿色） |
| 警告消息 | `#dbab09` | normal.yellow（黄色） |

## 视觉效果

### 状态栏布局

```
┌────────────────────────────────────────────────────────────────┐
│ 会话名  窗口1  窗口2*  窗口3    分支 │ 系统信息 │ 时间      │
└────────────────────────────────────────────────────────────────┘
```

### 配色示例

- **状态栏背景**：浅灰色（`#f6f8fa`）
- **会话名**：白色文字，蓝色背景（`#ffffff` on `#0366d6`）
- **当前窗口**：蓝色加粗，浅蓝背景（`#0366d6` on `#c8e1ff`）
- **其他窗口**：灰色（`#6a737d`）
- **Git 分支**：绿色（`#28a745`）
- **系统信息**：黑色（`#24292e`）
- **时间**：蓝色（`#0366d6`）
- **分隔符**：浅灰色（`#d1d5da`）

## 应用配置

### 1. 重载配置

在 tmux 中按 `Ctrl+a` 然后按 `r`，或者运行：

```bash
tmux source-file ~/.tmux.conf
```

### 2. 重启 tmux

如果重载后效果不明显，可以完全重启 tmux：

```bash
# 退出所有 tmux 会话
tmux kill-server

# 重新启动
tmux
```

## 主题特点

这个主题完全匹配你的 Alacritty GitHub Light 配色：

- ✅ 浅色背景，护眼舒适
- ✅ 与 GitHub 网站浅色主题一致
- ✅ 蓝色作为主要强调色
- ✅ 清晰的视觉层次
- ✅ 与终端主题完美协调

## 颜色映射表

| Tmux 元素 | 使用的颜色 | Alacritty 来源 |
|----------|-----------|---------------|
| 状态栏背景 | `#f6f8fa` | 自定义浅灰 |
| 主文字 | `#24292e` | `primary.foreground` |
| 蓝色强调 | `#0366d6` | `normal.blue` |
| 绿色（Git） | `#28a745` | `normal.green` |
| 黄色（警告） | `#dbab09` | `normal.yellow` |
| 灰色（次要） | `#6a737d` | `normal.white` |
| 浅灰（边框） | `#d1d5da` | `bright.white` |
| 选中背景 | `#c8e1ff` | `selection.background` |

## 切换到深色主题

如果需要切换回深色主题，可以使用以下配置：

### GitHub Dark 主题

```bash
# 状态栏颜色
set -g status-style "bg=#24292e,fg=#e1e4e8"
set -g pane-border-style "fg=#444d56"
set -g pane-active-border-style "fg=#0366d6"
set -g window-status-current-format " #[bold,fg=#0366d6,bg=#1c2128]#I:#W* "
```

## 自定义调整

### 调整状态栏背景亮度

```bash
# 更亮的背景
set -g status-style "bg=#ffffff,fg=#24292e"

# 稍暗的背景
set -g status-style "bg=#e1e4e8,fg=#24292e"
```

### 调整蓝色强调色

```bash
# 使用深蓝色
set -g window-status-current-format " #[bold,fg=#005cc5,bg=#c8e1ff]#I:#W* "

# 使用亮蓝色
set -g window-status-current-format " #[bold,fg=#0366d6,bg=#c8e1ff]#I:#W* "
```

## 兼容性

- ✅ 支持 256 色终端
- ✅ 支持 True Color（RGB）
- ✅ 兼容 tmux 2.9+
- ✅ 完美匹配 Alacritty GitHub Light 主题
- ✅ 在 SSH 连接中正常显示

## 故障排除

### 颜色显示不正确

1. 确认终端支持 True Color：
```bash
echo $TERM
# 应该显示 xterm-256color 或 tmux-256color
```

2. 确认 Alacritty 配置正确：
```bash
# 检查 Alacritty 配置文件
cat ~/.config/alacritty/alacritty.toml | grep -A 5 "colors.primary"
```

### 背景太亮或太暗

可以微调状态栏背景色：

```bash
# 在 .tmux.conf 中调整
set -g status-style "bg=#f0f0f0,fg=#24292e"  # 稍暗
set -g status-style "bg=#fafbfc,fg=#24292e"  # 稍亮
```

## 更新日志

- 2026-02-14：更新为 GitHub Light 浅色主题
- 完全匹配 Alacritty GitHub Light 配色方案
- 浅色背景，蓝色强调色
- 保持所有功能不变，仅更新视觉样式
