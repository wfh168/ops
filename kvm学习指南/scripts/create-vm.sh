#!/bin/bash

# KVM 虚拟机快速创建脚本
# 用法: ./create-vm.sh [选项]

# 默认参数
VM_NAME=""
VM_MEMORY=2048
VM_VCPUS=2
VM_DISK_SIZE=20
ISO_PATH=""
OS_VARIANT="centos7.0"
NETWORK="default"
GRAPHICS="vnc"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    cat << EOF
KVM 虚拟机快速创建脚本

用法:
    $0 -n <虚拟机名> -i <ISO路径> [选项]

必需参数:
    -n, --name NAME          虚拟机名称
    -i, --iso PATH           ISO 镜像路径

可选参数:
    -m, --memory SIZE        内存大小 (MB，默认: 2048)
    -c, --vcpus NUM          CPU 核心数 (默认: 2)
    -d, --disk SIZE          磁盘大小 (GB，默认: 20)
    -o, --os-variant TYPE    操作系统类型 (默认: centos7.0)
    -net, --network NAME     网络名称 (默认: default)
    -g, --graphics TYPE      图形类型 (vnc/spice，默认: vnc)
    -h, --help               显示此帮助信息

示例:
    # 创建基本虚拟机
    $0 -n centos7-web -i /path/to/centos7.iso

    # 创建自定义配置虚拟机
    $0 -n ubuntu-server -i /path/to/ubuntu.iso -m 4096 -c 4 -d 50 -o ubuntu22.04

    # 查看支持的操作系统类型
    osinfo-query os

EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            VM_NAME="$2"
            shift 2
            ;;
        -m|--memory)
            VM_MEMORY="$2"
            shift 2
            ;;
        -c|--vcpus)
            VM_VCPUS="$2"
            shift 2
            ;;
        -d|--disk)
            VM_DISK_SIZE="$2"
            shift 2
            ;;
        -i|--iso)
            ISO_PATH="$2"
            shift 2
            ;;
        -o|--os-variant)
            OS_VARIANT="$2"
            shift 2
            ;;
        -net|--network)
            NETWORK="$2"
            shift 2
            ;;
        -g|--graphics)
            GRAPHICS="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知参数 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查必需参数
if [ -z "$VM_NAME" ]; then
    echo -e "${RED}错误: 必须指定虚拟机名称 (-n)${NC}"
    show_help
    exit 1
fi

if [ -z "$ISO_PATH" ]; then
    echo -e "${RED}错误: 必须指定 ISO 镜像路径 (-i)${NC}"
    show_help
    exit 1
fi

# 检查 ISO 文件是否存在
if [ ! -f "$ISO_PATH" ]; then
    echo -e "${RED}错误: ISO 文件不存在: $ISO_PATH${NC}"
    exit 1
fi

# 检查虚拟机是否已存在
if virsh list --all --name | grep -q "^${VM_NAME}$"; then
    echo -e "${RED}错误: 虚拟机 '$VM_NAME' 已存在${NC}"
    exit 1
fi

# 显示配置信息
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}       创建 KVM 虚拟机${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "虚拟机配置:"
echo "  名称: $VM_NAME"
echo "  内存: ${VM_MEMORY}MB"
echo "  CPU: ${VM_VCPUS} 核"
echo "  磁盘: ${VM_DISK_SIZE}GB"
echo "  ISO: $ISO_PATH"
echo "  操作系统: $OS_VARIANT"
echo "  网络: $NETWORK"
echo "  图形: $GRAPHICS"
echo ""

# 确认创建
read -p "确认创建虚拟机? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消创建"
    exit 0
fi

# 创建虚拟机
echo ""
echo -e "${YELLOW}正在创建虚拟机...${NC}"
echo ""

virt-install \
  --name "$VM_NAME" \
  --memory "$VM_MEMORY" \
  --vcpus "$VM_VCPUS" \
  --disk size="$VM_DISK_SIZE",format=qcow2 \
  --cdrom "$ISO_PATH" \
  --os-variant "$OS_VARIANT" \
  --network network="$NETWORK",model=virtio \
  --graphics "$GRAPHICS",listen=0.0.0.0 \
  --console pty,target_type=serial \
  --noautoconsole

# 检查创建结果
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}       虚拟机创建成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "虚拟机信息:"
    virsh dominfo "$VM_NAME"
    echo ""
    echo "下一步操作:"
    echo "  1. 连接到虚拟机安装系统:"
    echo "     virt-viewer $VM_NAME"
    echo ""
    echo "  2. 查看虚拟机状态:"
    echo "     virsh list --all"
    echo ""
    echo "  3. 启动虚拟机:"
    echo "     virsh start $VM_NAME"
    echo ""
    echo "  4. 查看 VNC 端口:"
    echo "     virsh vncdisplay $VM_NAME"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}       虚拟机创建失败！${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "请检查错误信息并重试"
    exit 1
fi
