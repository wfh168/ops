#!/bin/bash

# KVM 虚拟机管理脚本
# 提供虚拟机的常用管理操作

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示菜单
show_menu() {
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}       KVM 虚拟机管理工具${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "1. 列出所有虚拟机"
    echo "2. 启动虚拟机"
    echo "3. 关闭虚拟机"
    echo "4. 重启虚拟机"
    echo "5. 强制关闭虚拟机"
    echo "6. 查看虚拟机信息"
    echo "7. 连接到虚拟机控制台"
    echo "8. 克隆虚拟机"
    echo "9. 删除虚拟机"
    echo "10. 批量启动所有虚拟机"
    echo "11. 批量关闭所有虚拟机"
    echo "12. 虚拟机资源监控"
    echo "0. 退出"
    echo ""
    echo -n "请选择操作 [0-12]: "
}

# 列出所有虚拟机
list_vms() {
    echo -e "${GREEN}所有虚拟机列表:${NC}"
    echo "========================================"
    virsh list --all
    echo ""
    read -p "按回车键继续..."
}

# 启动虚拟机
start_vm() {
    echo -e "${GREEN}启动虚拟机${NC}"
    echo "========================================"
    virsh list --all
    echo ""
    read -p "请输入虚拟机名称: " vm_name
    
    if [ -z "$vm_name" ]; then
        echo -e "${RED}错误: 虚拟机名称不能为空${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo "正在启动虚拟机 $vm_name..."
    virsh start "$vm_name"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}虚拟机启动成功！${NC}"
    else
        echo -e "${RED}虚拟机启动失败！${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 关闭虚拟机
shutdown_vm() {
    echo -e "${GREEN}关闭虚拟机${NC}"
    echo "========================================"
    virsh list
    echo ""
    read -p "请输入虚拟机名称: " vm_name
    
    if [ -z "$vm_name" ]; then
        echo -e "${RED}错误: 虚拟机名称不能为空${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo "正在关闭虚拟机 $vm_name..."
    virsh shutdown "$vm_name"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}虚拟机关闭命令已发送！${NC}"
    else
        echo -e "${RED}虚拟机关闭失败！${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 重启虚拟机
reboot_vm() {
    echo -e "${GREEN}重启虚拟机${NC}"
    echo "========================================"
    virsh list
    echo ""
    read -p "请输入虚拟机名称: " vm_name
    
    if [ -z "$vm_name" ]; then
        echo -e "${RED}错误: 虚拟机名称不能为空${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo "正在重启虚拟机 $vm_name..."
    virsh reboot "$vm_name"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}虚拟机重启命令已发送！${NC}"
    else
        echo -e "${RED}虚拟机重启失败！${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 强制关闭虚拟机
destroy_vm() {
    echo -e "${YELLOW}强制关闭虚拟机${NC}"
    echo "========================================"
    virsh list
    echo ""
    read -p "请输入虚拟机名称: " vm_name
    
    if [ -z "$vm_name" ]; then
        echo -e "${RED}错误: 虚拟机名称不能为空${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    read -p "确认强制关闭虚拟机 $vm_name? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消操作"
        read -p "按回车键继续..."
        return
    fi
    
    echo "正在强制关闭虚拟机 $vm_name..."
    virsh destroy "$vm_name"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}虚拟机已强制关闭！${NC}"
    else
        echo -e "${RED}虚拟机强制关闭失败！${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 查看虚拟机信息
show_vm_info() {
    echo -e "${GREEN}查看虚拟机信息${NC}"
    echo "========================================"
    virsh list --all
    echo ""
    read -p "请输入虚拟机名称: " vm_name
    
    if [ -z "$vm_name" ]; then
        echo -e "${RED}错误: 虚拟机名称不能为空${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo ""
    echo -e "${BLUE}基本信息:${NC}"
    virsh dominfo "$vm_name"
    
    echo ""
    echo -e "${BLUE}磁盘信息:${NC}"
    virsh domblklist "$vm_name"
    
    echo ""
    echo -e "${BLUE}网卡信息:${NC}"
    virsh domiflist "$vm_name"
    
    echo ""
    echo -e "${BLUE}IP 地址:${NC}"
    virsh domifaddr "$vm_name"
    
    echo ""
    read -p "按回车键继续..."
}

# 连接到虚拟机控制台
connect_vm() {
    echo -e "${GREEN}连接到虚拟机控制台${NC}"
    echo "========================================"
    virsh list
    echo ""
    read -p "请输入虚拟机名称: " vm_name
    
    if [ -z "$vm_name" ]; then
        echo -e "${RED}错误: 虚拟机名称不能为空${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo "正在连接到虚拟机 $vm_name..."
    virt-viewer "$vm_name" &
    
    echo -e "${GREEN}已启动 virt-viewer${NC}"
    read -p "按回车键继续..."
}

# 克隆虚拟机
clone_vm() {
    echo -e "${GREEN}克隆虚拟机${NC}"
    echo "========================================"
    virsh list --all
    echo ""
    read -p "请输入源虚拟机名称: " source_vm
    read -p "请输入新虚拟机名称: " new_vm
    
    if [ -z "$source_vm" ] || [ -z "$new_vm" ]; then
        echo -e "${RED}错误: 虚拟机名称不能为空${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo "正在克隆虚拟机 $source_vm 到 $new_vm..."
    virt-clone --original "$source_vm" --name "$new_vm" --auto-clone
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}虚拟机克隆成功！${NC}"
    else
        echo -e "${RED}虚拟机克隆失败！${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 删除虚拟机
delete_vm() {
    echo -e "${RED}删除虚拟机${NC}"
    echo "========================================"
    virsh list --all
    echo ""
    read -p "请输入虚拟机名称: " vm_name
    
    if [ -z "$vm_name" ]; then
        echo -e "${RED}错误: 虚拟机名称不能为空${NC}"
        read -p "按回车键继续..."
        return
    fi
    
    echo -e "${YELLOW}警告: 此操作将删除虚拟机及其所有数据！${NC}"
    read -p "确认删除虚拟机 $vm_name? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消操作"
        read -p "按回车键继续..."
        return
    fi
    
    # 先关闭虚拟机
    virsh destroy "$vm_name" 2>/dev/null
    
    # 删除虚拟机
    echo "正在删除虚拟机 $vm_name..."
    virsh undefine "$vm_name" --remove-all-storage
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}虚拟机删除成功！${NC}"
    else
        echo -e "${RED}虚拟机删除失败！${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 批量启动所有虚拟机
start_all_vms() {
    echo -e "${GREEN}批量启动所有虚拟机${NC}"
    echo "========================================"
    
    for vm in $(virsh list --all --name); do
        state=$(virsh domstate "$vm" 2>/dev/null)
        if [ "$state" = "shut off" ]; then
            echo "启动虚拟机: $vm"
            virsh start "$vm"
        else
            echo "虚拟机 $vm 已在运行"
        fi
    done
    
    echo ""
    echo -e "${GREEN}所有虚拟机启动完成！${NC}"
    read -p "按回车键继续..."
}

# 批量关闭所有虚拟机
shutdown_all_vms() {
    echo -e "${YELLOW}批量关闭所有虚拟机${NC}"
    echo "========================================"
    
    read -p "确认关闭所有运行中的虚拟机? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消操作"
        read -p "按回车键继续..."
        return
    fi
    
    for vm in $(virsh list --name); do
        echo "关闭虚拟机: $vm"
        virsh shutdown "$vm"
    done
    
    echo ""
    echo "等待虚拟机关闭..."
    sleep 10
    
    # 强制关闭未关闭的虚拟机
    for vm in $(virsh list --name); do
        echo "强制关闭虚拟机: $vm"
        virsh destroy "$vm"
    done
    
    echo ""
    echo -e "${GREEN}所有虚拟机关闭完成！${NC}"
    read -p "按回车键继续..."
}

# 虚拟机资源监控
monitor_vms() {
    echo -e "${GREEN}虚拟机资源监控${NC}"
    echo "========================================"
    echo ""
    
    printf "%-20s %-15s %-10s %-15s\n" "虚拟机" "状态" "CPU时间" "内存"
    echo "----------------------------------------------------------------"
    
    for vm in $(virsh list --all --name); do
        state=$(virsh domstate "$vm" 2>/dev/null)
        
        if [ "$state" = "running" ]; then
            cpu=$(virsh domstats "$vm" --cpu-total 2>/dev/null | grep cpu.time | awk '{print $2}')
            mem=$(virsh dommemstat "$vm" 2>/dev/null | grep actual | awk '{print $2}')
            mem_mb=$((mem / 1024))
            
            printf "%-20s %-15s %-10s %-15s\n" \
                "$vm" "$state" "${cpu:-N/A}" "${mem_mb:-N/A}MB"
        else
            printf "%-20s %-15s %-10s %-15s\n" \
                "$vm" "$state" "N/A" "N/A"
        fi
    done
    
    echo ""
    read -p "按回车键继续..."
}

# 主循环
while true; do
    show_menu
    read choice
    
    case $choice in
        1) list_vms ;;
        2) start_vm ;;
        3) shutdown_vm ;;
        4) reboot_vm ;;
        5) destroy_vm ;;
        6) show_vm_info ;;
        7) connect_vm ;;
        8) clone_vm ;;
        9) delete_vm ;;
        10) start_all_vms ;;
        11) shutdown_all_vms ;;
        12) monitor_vms ;;
        0) 
            echo "退出程序"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择，请重试${NC}"
            sleep 2
            ;;
    esac
done
