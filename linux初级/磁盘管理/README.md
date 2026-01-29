# 磁盘管理学习指南

## 学习路线

```
01_磁盘基础概念.md    ──▶  理解磁盘类型、接口、命名
        │
        ▼
02_分区管理.md        ──▶  掌握 fdisk/gdisk/parted
        │
        ▼
03_文件系统管理.md    ──▶  掌握格式化、挂载、扩展
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_磁盘基础概念.md | 磁盘类型、接口、命名规则 | 0.5 天 |
| 02_分区管理.md | fdisk、gdisk、parted 分区 | 1 天 |
| 03_文件系统管理.md | 格式化、挂载、扩展 | 1 天 |

## 核心知识点

### 磁盘基础
- HDD vs SSD vs NVMe
- SATA、SAS、NVMe 接口
- /dev/sda、/dev/nvme0n1 命名
- MBR vs GPT 分区表

### 分区工具
- fdisk（MBR，小于2TB）
- gdisk（GPT，大于2TB）
- parted（通用）

### 文件系统
- ext4（通用）
- xfs（高性能）
- swap（交换分区）

### 挂载管理
- mount/umount 命令
- /etc/fstab 配置
- UUID 方式挂载

## 常用命令速查

### 查看磁盘

```bash
lsblk                         # 列出块设备
fdisk -l                      # 查看分区表
df -h                         # 查看磁盘使用
du -sh /var                   # 查看目录大小
blkid                         # 查看 UUID
```

### 分区管理

```bash
fdisk /dev/sdb                # MBR 分区
gdisk /dev/sdb                # GPT 分区
parted /dev/sdb               # 通用分区工具
partprobe /dev/sdb            # 刷新分区表
```

### 文件系统

```bash
mkfs.ext4 /dev/sdb1           # 格式化 ext4
mkfs.xfs /dev/sdb1            # 格式化 xfs
mount /dev/sdb1 /mnt          # 挂载
umount /mnt                   # 卸载
resize2fs /dev/sdb1           # 扩展 ext4
xfs_growfs /mnt               # 扩展 xfs
```

### 交换分区

```bash
mkswap /dev/sdb2              # 创建 swap
swapon /dev/sdb2              # 启用 swap
swapoff /dev/sdb2             # 关闭 swap
swapon -s                     # 查看 swap
```

## 实战场景

### 场景1：添加新数据盘

```bash
# 1. 分区
fdisk /dev/sdb
# n -> p -> 1 -> 回车 -> 回车 -> w

# 2. 格式化
mkfs.ext4 /dev/sdb1

# 3. 挂载
mkdir /data
mount /dev/sdb1 /data

# 4. 开机自动挂载
echo "UUID=$(blkid -s UUID -o value /dev/sdb1) /data ext4 defaults,noatime 0 2" >> /etc/fstab
```

### 场景2：扩展磁盘

```bash
# ext4
umount /dev/sdb1
resize2fs /dev/sdb1
mount /dev/sdb1 /data

# xfs（必须挂载状态）
xfs_growfs /data
```

### 场景3：创建 swap

```bash
# 使用分区
mkswap /dev/sdb2
swapon /dev/sdb2
echo "/dev/sdb2 none swap defaults 0 0" >> /etc/fstab

# 使用文件
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab
```

## 最佳实践

### 1. 使用 UUID 挂载

```bash
# 推荐
UUID=xxx-xxx /data ext4 defaults 0 2

# 不推荐
/dev/sdb1 /data ext4 defaults 0 2
```

### 2. 合理规划分区

```bash
# 服务器推荐分区
/boot    1GB
swap     4-8GB
/        50GB
/var     50GB
/data    剩余空间
```

### 3. 使用 noatime 选项

```bash
# 减少磁盘写入
mount -o defaults,noatime /dev/sdb1 /data
```

### 4. 定期检查磁盘

```bash
# 查看磁盘使用
df -h

# 查看 inode 使用
df -i

# 检查磁盘健康
smartctl -H /dev/sda
```

### 5. 备份重要数据

```bash
# 定期备份
rsync -av /data/ /backup/

# 备份分区表
sfdisk -d /dev/sdb > /backup/sdb_partition.txt
```

## 常见问题

### 1. 分区后看不到

```bash
# 刷新分区表
partprobe /dev/sdb

# 查看内核是否识别
cat /proc/partitions
```

### 2. 无法卸载

```bash
# 查看占用
lsof /mnt
fuser -m /mnt

# 杀死进程
fuser -k /mnt
```

### 3. 文件系统损坏

```bash
# 卸载并检查
umount /dev/sdb1
fsck -y /dev/sdb1
```

### 4. 磁盘空间不足

```bash
# 查找大文件
find / -type f -size +100M

# 查找大目录
du -sh /* | sort -h

# 清理日志
find /var/log -name "*.log" -mtime +7 -delete
```

## 面试常考

1. MBR 和 GPT 的区别？
2. ext4 和 xfs 的区别？
3. 如何扩展文件系统？
4. 如何配置开机自动挂载？
5. swap 分区的作用？

## 下一步

完成磁盘管理学习后，进入「网络基础」模块，学习 Linux 网络配置和管理。
