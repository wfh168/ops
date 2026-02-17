#!/bin/bash

# 自动添加 tmux 自动启动到 shell 配置

echo "=== Tmux 自动启动配置 ==="
echo ""

# 检测使用的 shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    echo "❌ 无法检测 shell 类型"
    exit 1
fi

echo "检测到 shell: $SHELL_NAME"
echo "配置文件: $SHELL_RC"
echo ""

# 检查是否已经配置
if grep -q "tmux attach.*default" "$SHELL_RC" 2>/dev/null; then
    echo "✅ 已经配置了 tmux 自动启动"
    echo ""
    echo "当前配置："
    grep -A 3 "tmux attach.*default" "$SHELL_RC"
    exit 0
fi

# 添加配置
echo "正在添加 tmux 自动启动配置..."
echo ""

cat >> "$SHELL_RC" << 'EOF'

# ============================================
# Tmux 自动启动配置
# ============================================
# 打开终端时自动启动或连接到 tmux 会话
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    # 尝试连接到 default 会话，如果不存在则创建
    tmux attach -t default || tmux new -s default
fi
EOF

echo "✅ 配置已添加到 $SHELL_RC"
echo ""
echo "=== 配置内容 ==="
tail -10 "$SHELL_RC"
echo ""
echo "=== 使用说明 ==="
echo ""
echo "1. 重新加载配置："
echo "   source $SHELL_RC"
echo ""
echo "2. 或者关闭并重新打开终端"
echo ""
echo "3. 下次打开终端时会自动进入 tmux"
echo ""
echo "4. 如果不想自动启动，可以设置环境变量："
echo "   export TMUX_AUTO_START=0"
echo ""
echo "=== 测试 ==="
echo "现在可以测试一下："
echo "   1. 在当前 tmux 会话中保存: Ctrl+a Ctrl+s"
echo "   2. 退出 tmux: exit"
echo "   3. 重新打开终端，应该会自动进入 tmux 并恢复会话"
echo ""
