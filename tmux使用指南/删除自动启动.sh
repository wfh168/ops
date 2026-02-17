#!/bin/bash

# 删除 tmux 自动启动配置

echo "=== 删除 Tmux 自动启动配置 ==="
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

# 检查是否存在自动启动配置
if ! grep -q "tmux attach.*default" "$SHELL_RC" 2>/dev/null; then
    echo "✅ 没有找到 tmux 自动启动配置"
    echo "   配置文件是干净的"
    exit 0
fi

# 显示当前配置
echo "找到以下 tmux 自动启动配置："
echo "----------------------------------------"
grep -B 3 -A 3 "tmux attach.*default" "$SHELL_RC"
echo "----------------------------------------"
echo ""

# 备份配置文件
backup_file="${SHELL_RC}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$SHELL_RC" "$backup_file"
echo "✅ 已备份配置文件到: $backup_file"
echo ""

# 删除 tmux 自动启动配置
# 删除包含 "Tmux 自动启动" 注释块和相关代码
sed -i '/# ============================================/,/^fi$/d' "$SHELL_RC" 2>/dev/null || \
sed -i '/# Tmux 自动启动/,/^fi$/d' "$SHELL_RC" 2>/dev/null || \
sed -i '/tmux attach -t default/d' "$SHELL_RC"

echo "✅ 已删除 tmux 自动启动配置"
echo ""

# 验证删除
if grep -q "tmux attach.*default" "$SHELL_RC" 2>/dev/null; then
    echo "⚠️  警告：配置可能未完全删除"
    echo "   请手动检查: $SHELL_RC"
else
    echo "✅ 验证成功：配置已完全删除"
fi

echo ""
echo "=== 使用说明 ==="
echo ""
echo "1. 重新加载配置："
echo "   source $SHELL_RC"
echo ""
echo "2. 或者关闭并重新打开终端"
echo ""
echo "3. 下次打开终端时不会自动进入 tmux"
echo ""
echo "4. 需要使用 tmux 时手动启动："
echo "   tmux                    # 创建新会话"
echo "   tmux attach             # 连接到最后一个会话"
echo "   tmux attach -t default  # 连接到指定会话"
echo ""
echo "5. 如果需要恢复自动启动："
echo "   bash tmux使用指南/添加自动启动.sh"
echo ""
