# KVM虚拟机迁移和备份指南

## 目录
1. [离线迁移（冷迁移）](#离线迁移)
2. [在线迁移（热迁移）](#在线迁移)
3. [使用virsh命令迁移](#使用virsh命令)
4. [使用virt-manager图形界面](#使用图形界面)
5. [自动化迁移脚本](#自动化脚本)

---

## 离线迁移（冷迁移）- 推荐新手使用

### 方法1：导出整个虚拟机（最简单）

#### 源主机操作：

```bash
# 1. 查看虚拟机列表
virsh list --all

# 2. 关闭虚拟机
virsh shutdown vm-name

# 3. 导出虚拟机配置（XML文件）
virsh dumpxml vm-name > /tmp/vm-name.xml

# 4. 查找虚拟机磁盘文件位置
virsh domblklist vm-name

# 5. 打包虚拟机（配置+磁盘）
tar -czf /tmp/vm-name-backup.tar.gz \
    /tmp/vm-name.xml \
    /var/lib/libvirt/images/vm-name.qcow2

# 6. 传输到目标主机
scp /tmp/vm-name-backup.tar.gz user@target-host:/tmp/
```

#### 目标主机操作：

```bash
# 1. 解压备份文件
cd /tmp
tar -xzf vm-name-backup.tar.gz

# 2. 复制磁盘文件到KVM存储目录
sudo cp var/lib/libvirt/images/vm-name.qcow2 /var/lib/libvirt/images/

# 3. 修改XML配置文件（如果路径不同）
vim tmp/vm-name.xml
# 检查并修改磁盘路径、网络配置等

# 4. 导入虚拟机定义
virsh define tmp/vm-name.xml

# 5. 启动虚拟机
virsh start vm-name

# 6. 验证虚拟机状态
virsh list
```

---

### 方法2：使用virt-clone（推荐）

#### 在源主机上：

```bash
# 1. 关闭虚拟机
virsh shutdown vm-name

# 2. 克隆虚拟机到临时位置
virt-clone \
    --original vm-name \
    --name vm-name-clone \
    --file /tmp/vm-name-clone.qcow2

# 3. 导出克隆的配置
virsh dumpxml vm-name-clone > /tmp/vm-name-clone.xml

# 4. 传输到目标主机
rsync -avz --progress \
    /tmp/vm-name-clone.qcow2 \
    /tmp/vm-name-clone.xml \
    user@target-host:/tmp/
```

#### 在目标主机上：

```bash
# 1. 移动磁盘文件
sudo mv /tmp/vm-name-clone.qcow2 /var/lib/libvirt/images/vm-name.qcow2

# 2. 编辑XML配置（修改名称和UUID）
vim /tmp/vm-name-clone.xml
# 修改 <name> 标签
# 删除或修改 <uuid> 标签（让系统自动生成）

# 3. 导入虚拟机
virsh define /tmp/vm-name-clone.xml

# 4. 启动虚拟机
virsh start vm-name
```

---

### 方法3：直接复制磁盘文件

#### 源主机操作：

```bash
# 1. 关闭虚拟机
virsh shutdown vm-name

# 2. 导出配置
virsh dumpxml vm-name > vm-name.xml

# 3. 查找磁盘文件
virsh domblklist vm-name

# 4. 使用rsync传输（支持断点续传）
rsync -avz --progress \
    /var/lib/libvirt/images/vm-name.qcow2 \
    user@target-host:/var/lib/libvirt/images/

# 5. 传输配置文件
scp vm-name.xml user@target-host:/tmp/
```

#### 目标主机操作：

```bash
# 1. 设置正确的权限
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/vm-name.qcow2
sudo chmod 644 /var/lib/libvirt/images/vm-name.qcow2

# 2. 导入虚拟机
virsh define /tmp/vm-name.xml

# 3. 启动虚拟机
virsh start vm-name
```

---

## 在线迁移（热迁移）- 不停机迁移

### 前提条件：
- 两台主机都运行KVM
- 共享存储（NFS、iSCSI等）或使用--copy-storage-all参数
- 网络连通
- 相同的CPU架构

### 使用virsh migrate命令：

```bash
# 方法1：使用共享存储的热迁移
virsh migrate --live --persistent \
    vm-name \
    qemu+ssh://target-host/system

# 方法2：不使用共享存储（复制磁盘）
virsh migrate --live --persistent \
    --copy-storage-all \
    vm-name \
    qemu+ssh://target-host/system

# 方法3：指定迁移参数
virsh migrate --live --persistent \
    --copy-storage-all \
    --verbose \
    --undefinesource \
    vm-name \
    qemu+ssh://user@target-host/system
```

### 热迁移参数说明：
- `--live`: 在线迁移，虚拟机不停机
- `--persistent`: 在目标主机上持久化虚拟机定义
- `--copy-storage-all`: 复制所有磁盘文件
- `--undefinesource`: 迁移成功后从源主机删除定义
- `--verbose`: 显示详细进度

---

## 使用virt-manager图形界面迁移

### 1. 打开virt-manager

```bash
virt-manager
```

### 2. 迁移步骤：
1. 右键点击虚拟机
2. 选择"Migrate"
3. 选择目标主机连接
4. 配置迁移选项
5. 点击"Migrate"开始迁移

---

## 批量备份脚本

### 创建自动化备份脚本：

```bash
#!/bin/bash
# KVM虚拟机批量备份脚本

# 配置变量
BACKUP_DIR="/backup/kvm"
DATE=$(date +%Y%m%d_%H%M%S)
VM_LIST=$(virsh list --all --name)

# 创建备份目录
mkdir -p $BACKUP_DIR/$DATE

# 备份函数
backup_vm() {
    local vm_name=$1
    local backup_path="$BACKUP_DIR/$DATE/$vm_name"
    
    echo "开始备份虚拟机: $vm_name"
    
    # 创建虚拟机备份目录
    mkdir -p $backup_path
    
    # 检查虚拟机状态
    vm_state=$(virsh domstate $vm_name)
    
    # 如果虚拟机正在运行，先关闭
    if [ "$vm_state" == "running" ]; then
        echo "关闭虚拟机: $vm_name"
        virsh shutdown $vm_name
        
        # 等待虚拟机关闭
        while [ "$(virsh domstate $vm_name)" == "running" ]; do
            sleep 2
        done
    fi
    
    # 导出配置文件
    virsh dumpxml $vm_name > $backup_path/$vm_name.xml
    
    # 获取磁盘文件列表
    disk_files=$(virsh domblklist $vm_name | grep -v "^-" | awk 'NR>1 {print $2}')
    
    # 备份磁盘文件
    for disk in $disk_files; do
        if [ -f "$disk" ]; then
            echo "备份磁盘: $disk"
            cp $disk $backup_path/
        fi
    done
    
    # 如果之前是运行状态，重新启动
    if [ "$vm_state" == "running" ]; then
        echo "重新启动虚拟机: $vm_name"
        virsh start $vm_name
    fi
    
    echo "虚拟机 $vm_name 备份完成"
    echo "---"
}

# 主程序
echo "=== KVM虚拟机备份开始 ==="
echo "备份时间: $DATE"
echo "备份目录: $BACKUP_DIR/$DATE"
echo ""

# 遍历所有虚拟机
for vm in $VM_LIST; do
    if [ ! -z "$vm" ]; then
        backup_vm $vm
    fi
done

# 压缩备份
echo "压缩备份文件..."
cd $BACKUP_DIR
tar -czf kvm-backup-$DATE.tar.gz $DATE/
rm -rf $DATE/

echo "=== 备份完成 ==="
echo "备份文件: $BACKUP_DIR/kvm-backup-$DATE.tar.gz"
```

### 使用备份脚本：

```bash
# 保存脚本
sudo vim /usr/local/bin/kvm-backup.sh

# 添加执行权限
sudo chmod +x /usr/local/bin/kvm-backup.sh

# 运行备份
sudo /usr/local/bin/kvm-backup.sh
```

---

## 恢复虚拟机脚本

```bash
#!/bin/bash
# KVM虚拟机恢复脚本

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <备份文件路径>"
    exit 1
fi

# 解压备份
TEMP_DIR="/tmp/kvm-restore-$$"
mkdir -p $TEMP_DIR
tar -xzf $BACKUP_FILE -C $TEMP_DIR

# 查找所有XML文件
for xml_file in $TEMP_DIR/*/*.xml; do
    vm_name=$(basename $xml_file .xml)
    vm_dir=$(dirname $xml_file)
    
    echo "恢复虚拟机: $vm_name"
    
    # 复制磁盘文件
    for disk in $vm_dir/*.qcow2 $vm_dir/*.img; do
        if [ -f "$disk" ]; then
            echo "复制磁盘: $disk"
            sudo cp $disk /var/lib/libvirt/images/
        fi
    done
    
    # 设置权限
    sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/*
    sudo chmod 644 /var/lib/libvirt/images/*
    
    # 导入虚拟机定义
    virsh define $xml_file
    
    echo "虚拟机 $vm_name 恢复完成"
done

# 清理临时文件
rm -rf $TEMP_DIR

echo "=== 恢复完成 ==="
```

---

## 快速迁移命令参考

### 单个虚拟机快速迁移：

```bash
# 1. 一键备份
VM_NAME="your-vm-name"
virsh shutdown $VM_NAME
virsh dumpxml $VM_NAME > /tmp/$VM_NAME.xml
DISK=$(virsh domblklist $VM_NAME | grep -v "^-" | awk 'NR>1 {print $2}')
tar -czf /tmp/$VM_NAME.tar.gz /tmp/$VM_NAME.xml $DISK

# 2. 传输到目标主机
scp /tmp/$VM_NAME.tar.gz user@target-host:/tmp/

# 3. 在目标主机上恢复
ssh user@target-host "
    cd /tmp
    tar -xzf $VM_NAME.tar.gz
    sudo cp var/lib/libvirt/images/*.qcow2 /var/lib/libvirt/images/
    sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/*.qcow2
    virsh define tmp/$VM_NAME.xml
    virsh start $VM_NAME
"
```

---

## 注意事项

### 1. 网络配置
迁移后可能需要调整网络配置：
```bash
# 查看网络配置
virsh net-list --all

# 如果网络名称不同，编辑XML
virsh edit vm-name
# 修改 <source network='xxx'/> 部分
```

### 2. 存储路径
确保目标主机的存储路径存在：
```bash
sudo mkdir -p /var/lib/libvirt/images
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images
```

### 3. UUID冲突
如果导入时提示UUID冲突：
```bash
# 编辑XML文件，删除UUID行
virsh edit vm-name
# 删除 <uuid>xxx</uuid> 行，系统会自动生成新的
```

### 4. 权限问题
确保文件权限正确：
```bash
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/*.qcow2
sudo chmod 644 /var/lib/libvirt/images/*.qcow2
```

---

## 性能优化建议

### 1. 使用压缩传输
```bash
# 使用pigz多线程压缩
tar -I pigz -cf vm-backup.tar.gz /path/to/vm

# 使用rsync增量传输
rsync -avz --progress --partial \
    /var/lib/libvirt/images/vm.qcow2 \
    user@target:/var/lib/libvirt/images/
```

### 2. 使用快照加速备份
```bash
# 创建快照
virsh snapshot-create-as vm-name snapshot1

# 备份快照
virsh snapshot-dumpxml vm-name snapshot1 > snapshot1.xml
```

### 3. 网络传输优化
```bash
# 使用nc (netcat) 直接传输
# 目标主机
nc -l 9999 | tar -xzf -

# 源主机
tar -czf - /var/lib/libvirt/images/vm.qcow2 | nc target-host 9999
```

---

## 故障排除

### 问题1：虚拟机无法启动
```bash
# 查看详细错误
virsh start vm-name --console

# 检查日志
sudo tail -f /var/log/libvirt/qemu/vm-name.log
```

### 问题2：网络不通
```bash
# 检查网络配置
virsh net-list --all
virsh net-info default

# 重启网络
virsh net-destroy default
virsh net-start default
```

### 问题3：磁盘文件损坏
```bash
# 检查磁盘文件
qemu-img check /var/lib/libvirt/images/vm.qcow2

# 修复磁盘
qemu-img check -r all /var/lib/libvirt/images/vm.qcow2
```

---

## 总结

推荐的迁移方案选择：

1. **测试环境/小型虚拟机**: 使用方法1（tar打包传输）
2. **生产环境/大型虚拟机**: 使用方法3（rsync增量传输）
3. **需要不停机**: 使用在线迁移（热迁移）
4. **批量迁移**: 使用自动化脚本

根据你的具体需求选择合适的方法！