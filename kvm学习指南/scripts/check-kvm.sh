#!/bin/bash

# KVM 环境检查脚本

echo "========================================="
echo "       KVM 环境检查脚本"
echo "========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查 CPU 虚拟化支持
echo "1. 检查 CPU 虚拟化支持"
echo "-----------------------------------"
virt_count=$(egrep -c '(vmx|svm)' /proc/cpuinfo 2>/dev/null)
if [ $virt_count -gt 0 ]; then
    echo -e "   ${GREEN}✅ CPU 支持虚拟化${NC} ($virt_count 核心)"
    virt_type=$(lscpu | grep -i virtualization | awk '{print $2}' 2>/dev/null)
    if [ -n "$virt_type" ]; then
        echo "   虚拟化类型: $virt_type"
    fi
else
    echo -e "   ${RED}❌ CPU 不支持虚拟化${NC}"
    echo "   请在 BIOS 中启用 VT-x/AMD-V"
fi
echo ""

# 2. 检查 KVM 模块
echo "2. 检查 KVM 模块"
echo "-----------------------------------"
if lsmod | grep -q kvm; then
    echo -e "   ${GREEN}✅ KVM 模块已加载${NC}"
    lsmod | grep kvm | while read line; do
        echo "   $line"
    done
else
    echo -e "   ${RED}❌ KVM 模块未加载${NC}"
    echo "   尝试加载模块:"
    if grep -q "vmx" /proc/cpuinfo; then
        echo "   sudo modprobe kvm_intel"
    elif grep -q "svm" /proc/cpuinfo; then
        echo "   sudo modprobe kvm_amd"
    fi
fi
echo ""

# 3. 检查 libvirt 服务
echo "3. 检查 libvirt 服务"
echo "-----------------------------------"
if systemctl is-active --quiet libvirtd 2>/dev/null; then
    echo -e "   ${GREEN}✅ libvirt 服务运行中${NC}"
    systemctl status libvirtd --no-pager -l | grep "Active:" | sed 's/^/   /'
elif systemctl is-active --quiet virtqemud 2>/dev/null; then
    echo -e "   ${GREEN}✅ virtqemud 服务运行中${NC} (新版本)"
    systemctl status virtqemud --no-pager -l | grep "Active:" | sed 's/^/   /'
else
    echo -e "   ${RED}❌ libvirt 服务未运行${NC}"
    echo "   启动服务: sudo systemctl start libvirtd"
fi
echo ""

# 4. 检查命令行工具
echo "4. 检查命令行工具"
echo "-----------------------------------"
tools=("virsh" "qemu-system-x86_64" "virt-install" "virt-manager" "virt-viewer")
for cmd in "${tools[@]}"; do
    if command -v $cmd &> /dev/null; then
        version=$($cmd --version 2>&1 | head -1)
        echo -e "   ${GREEN}✅ $cmd${NC}"
        echo "      $version"
    else
        echo -e "   ${RED}❌ $cmd 未安装${NC}"
    fi
done
echo ""

# 5. 检查网络
echo "5. 检查虚拟网络"
echo "-----------------------------------"
if command -v virsh &> /dev/null; then
    if virsh net-list --all 2>/dev/null | grep -q default; then
        state=$(virsh net-list --all 2>/dev/null | grep default | awk '{print $2}')
        if [ "$state" = "active" ] || [ "$state" = "活动" ]; then
            echo -e "   ${GREEN}✅ 默认网络已启动${NC}"
            virsh net-info default 2>/dev/null | sed 's/^/   /'
        else
            echo -e "   ${YELLOW}⚠️  默认网络未启动${NC}"
            echo "   启动网络: virsh net-start default"
        fi
    else
        echo -e "   ${RED}❌ 默认网络不存在${NC}"
        echo "   创建网络: virsh net-define /usr/share/libvirt/networks/default.xml"
    fi
    
    # 检查网桥
    if ip addr show virbr0 &> /dev/null; then
        echo -e "   ${GREEN}✅ 虚拟网桥 virbr0 存在${NC}"
        ip addr show virbr0 | grep "inet " | awk '{print "   IP: " $2}'
    fi
else
    echo -e "   ${YELLOW}⚠️  virsh 未安装，跳过网络检查${NC}"
fi
echo ""

# 6. 检查存储池
echo "6. 检查存储池"
echo "-----------------------------------"
if command -v virsh &> /dev/null; then
    if virsh pool-list --all 2>/dev/null | grep -q default; then
        state=$(virsh pool-list --all 2>/dev/null | grep default | awk '{print $2}')
        if [ "$state" = "active" ] || [ "$state" = "活动" ]; then
            echo -e "   ${GREEN}✅ 默认存储池已启动${NC}"
            virsh pool-info default 2>/dev/null | sed 's/^/   /'
        else
            echo -e "   ${YELLOW}⚠️  默认存储池未启动${NC}"
            echo "   启动存储池: virsh pool-start default"
        fi
    else
        echo -e "   ${RED}❌ 默认存储池不存在${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  virsh 未安装，跳过存储检查${NC}"
fi
echo ""

# 7. 检查用户权限
echo "7. 检查用户权限"
echo "-----------------------------------"
current_user=$(whoami)
echo "   当前用户: $current_user"

if groups | grep -q libvirt; then
    echo -e "   ${GREEN}✅ 用户在 libvirt 组中${NC}"
else
    echo -e "   ${YELLOW}⚠️  用户不在 libvirt 组中${NC}"
    echo "   添加用户: sudo usermod -aG libvirt $current_user"
    echo "   然后重新登录"
fi

if groups | grep -q kvm; then
    echo -e "   ${GREEN}✅ 用户在 kvm 组中${NC}"
else
    echo -e "   ${YELLOW}⚠️  用户不在 kvm 组中${NC}"
    echo "   添加用户: sudo usermod -aG kvm $current_user"
fi

echo "   当前用户组: $(groups)"
echo ""

# 8. 检查系统资源
echo "8. 检查系统资源"
echo "-----------------------------------"
cpu_count=$(nproc)
total_mem=$(free -h | awk 'NR==2{print $2}')
avail_mem=$(free -h | awk 'NR==2{print $7}')
disk_avail=$(df -h / | awk 'NR==2{print $4}')

echo "   CPU 核心数: $cpu_count"
echo "   总内存: $total_mem"
echo "   可用内存: $avail_mem"
echo "   根分区可用空间: $disk_avail"

# 资源建议
mem_gb=$(free -g | awk 'NR==2{print $2}')
if [ $mem_gb -lt 4 ]; then
    echo -e "   ${YELLOW}⚠️  内存较少，建议至少 4GB${NC}"
elif [ $mem_gb -lt 8 ]; then
    echo -e "   ${GREEN}✅ 内存足够基本使用${NC}"
else
    echo -e "   ${GREEN}✅ 内存充足${NC}"
fi
echo ""

# 9. 检查现有虚拟机
echo "9. 检查现有虚拟机"
echo "-----------------------------------"
if command -v virsh &> /dev/null; then
    vm_count=$(virsh list --all 2>/dev/null | grep -v "^---" | grep -v "^ Id" | grep -v "^$" | wc -l)
    if [ $vm_count -gt 0 ]; then
        echo "   已创建的虚拟机数量: $vm_count"
        virsh list --all 2>/dev/null | sed 's/^/   /'
    else
        echo "   还没有创建虚拟机"
    fi
else
    echo -e "   ${YELLOW}⚠️  virsh 未安装，跳过虚拟机检查${NC}"
fi
echo ""

# 10. 总结
echo "========================================="
echo "       检查总结"
echo "========================================="

# 计算通过的检查项
passed=0
total=0

# CPU 虚拟化
total=$((total + 1))
[ $virt_count -gt 0 ] && passed=$((passed + 1))

# KVM 模块
total=$((total + 1))
lsmod | grep -q kvm && passed=$((passed + 1))

# libvirt 服务
total=$((total + 1))
(systemctl is-active --quiet libvirtd 2>/dev/null || systemctl is-active --quiet virtqemud 2>/dev/null) && passed=$((passed + 1))

# virsh 命令
total=$((total + 1))
command -v virsh &> /dev/null && passed=$((passed + 1))

# 默认网络
total=$((total + 1))
if command -v virsh &> /dev/null; then
    virsh net-list 2>/dev/null | grep -q "default.*active" && passed=$((passed + 1))
fi

echo ""
echo "检查通过: $passed/$total"
echo ""

if [ $passed -eq $total ]; then
    echo -e "${GREEN}✅ 环境配置完整，可以开始使用 KVM！${NC}"
    echo ""
    echo "下一步:"
    echo "  1. 创建第一个虚拟机: virt-install ..."
    echo "  2. 使用图形界面: virt-manager"
    echo "  3. 查看文档: kvm学习指南/03_创建第一个虚拟机.md"
elif [ $passed -ge 3 ]; then
    echo -e "${YELLOW}⚠️  环境基本可用，但有些配置需要完善${NC}"
    echo ""
    echo "建议:"
    echo "  1. 检查上面标记为 ⚠️  或 ❌ 的项目"
    echo "  2. 按照提示进行修复"
    echo "  3. 重新运行此脚本验证"
else
    echo -e "${RED}❌ 环境配置不完整，需要安装和配置${NC}"
    echo ""
    echo "请按照以下步骤操作:"
    echo "  1. 查看文档: kvm学习指南/02_环境检查和安装.md"
    echo "  2. 安装必要的软件包"
    echo "  3. 配置服务和权限"
    echo "  4. 重新运行此脚本"
fi

echo ""
echo "========================================="
