#!/bin/bash
# 自动安装 Tmux 别名到 ~/.bashrc

ALIAS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tmux命令别名.sh"
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"

echo "==================== Tmux 别名安装 ===================="
echo ""

# 检测使用的 shell
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$BASHRC"
    SHELL_NAME="bash"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$ZSHRC"
    SHELL_NAME="zsh"
else
    echo "检测到的 shell: $SHELL"
    read -p "请输入配置文件路径 (默认: ~/.bashrc): " SHELL_RC
    SHELL_RC="${SHELL_RC:-$HOME/.bashrc}"
    SHELL_NAME="shell"
fi

echo "将安装到: $SHELL_RC"
echo ""

# 检查是否已经安装
if grep -q "tmux命令别名.sh" "$SHELL_RC" 2>/dev/null; then
    echo "⚠️  别名已经安装过了"
    read -p "是否重新安装? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消安装"
        exit 0
    fi
    
    # 删除旧的配置
    sed -i '/# Tmux 别名配置/,/# Tmux 别名配置结束/d' "$SHELL_RC"
fi

# 添加别名配置
cat >> "$SHELL_RC" << EOF

# Tmux 别名配置
if [ -f "$ALIAS_FILE" ]; then
    source "$ALIAS_FILE"
fi
# Tmux 别名配置结束
EOF

echo "✅ 别名已成功安装到 $SHELL_RC"
echo ""
echo "使配置生效:"
echo "  source $SHELL_RC"
echo ""
echo "或者重新打开终端"
echo ""
echo "输入 'thelp' 查看所有别名"
