#!/bin/bash

# Tmux 会话快速恢复脚本

echo "=== Tmux 会话恢复检查 ==="
echo ""

# 1. 检查 tmux 是否安装
if ! command -v tmux &> /dev/null; then
    echo "❌ tmux 未安装"
    exit 1
fi
echo "✅ tmux 已安装: $(tmux -V)"

# 2. 检查插件是否安装
echo ""
echo "检查插件安装状态："
if [ -d ~/.tmux/plugins/tmux-resurrect ]; then
    echo "✅ tmux-resurrect 已安装"
else
    echo "❌ tmux-resurrect 未安装"
    echo "   请在 tmux 中按 Ctrl+a I 安装插件"
fi

if [ -d ~/.tmux/plugins/tmux-continuum ]; then
    echo "✅ tmux-continuum 已安装"
else
    echo "❌ tmux-continuum 未安装"
    echo "   请在 tmux 中按 Ctrl+a I 安装插件"
fi

# 3. 检查保存目录
echo ""
echo "检查保存目录："
if [ -d ~/.tmux/resurrect ]; then
    echo "✅ 保存目录存在: ~/.tmux/resurrect"
    
    # 检查是否有保存文件
    if [ -L ~/.tmux/resurrect/last ]; then
        echo "✅ 找到保存文件"
        echo "   最后保存时间: $(ls -lh ~/.tmux/resurrect/last | awk '{print $6, $7, $8}')"
        
        # 显示保存的会话数量
        session_count=$(grep -c "^session" ~/.tmux/resurrect/last 2>/dev/null || echo "0")
        echo "   保存的会话数: $session_count"
    else
        echo "⚠️  没有找到保存文件"
        echo "   这是第一次使用，需要先保存会话"
    fi
else
    echo "⚠️  保存目录不存在"
    echo "   这是第一次使用，启动 tmux 后会自动创建"
fi

# 4. 检查 tmux 是否运行
echo ""
echo "检查 tmux 运行状态："
if tmux list-sessions &> /dev/null; then
    echo "✅ tmux 正在运行"
    echo ""
    echo "当前会话列表："
    tmux list-sessions
else
    echo "⚠️  tmux 未运行"
fi

# 5. 提供操作建议
echo ""
echo "=== 操作建议 ==="
echo ""

if [ ! -d ~/.tmux/resurrect ] || [ ! -L ~/.tmux/resurrect/last ]; then
    echo "📝 首次使用步骤："
    echo "   1. 启动 tmux: tmux"
    echo "   2. 创建会话和窗口"
    echo "   3. 手动保存: Ctrl+a Ctrl+s"
    echo "   4. 之后会每 5 分钟自动保存"
    echo ""
    echo "📝 重启后恢复："
    echo "   1. 启动 tmux: tmux"
    echo "   2. 会自动恢复（或按 Ctrl+a Ctrl+r 手动恢复）"
else
    if ! tmux list-sessions &> /dev/null; then
        echo "📝 恢复会话："
        echo "   1. 启动 tmux: tmux"
        echo "   2. 会自动恢复上次的会话"
        echo "   3. 如果没有自动恢复，按: Ctrl+a Ctrl+r"
    else
        echo "✅ tmux 正在运行，会话已恢复或正在运行中"
        echo ""
        echo "📝 保存当前会话："
        echo "   在 tmux 中按: Ctrl+a Ctrl+s"
    fi
fi

echo ""
echo "=== 自动启动选项 ==="
echo ""
echo "如果想要系统重启后自动启动 tmux，可以选择："
echo ""
echo "方案 1: 添加到 shell 启动脚本（推荐）"
echo "   在 ~/.bashrc 或 ~/.zshrc 中添加："
echo "   if command -v tmux &> /dev/null && [ -z \"\$TMUX\" ]; then"
echo "       tmux attach -t default || tmux new -s default"
echo "   fi"
echo ""
echo "方案 2: 使用 systemd 服务"
echo "   详见: tmux使用指南/会话持久化完整方案.md"
echo ""

echo "=== 更多帮助 ==="
echo "详细文档: tmux使用指南/会话持久化完整方案.md"
echo ""
