# NFS 客户端挂载与优化

## 客户端安装

### CentOS/RHEL

```bash
# 安装 NFS 客户端工具
yum install -y nfs-utils

# 启动 rpcbind（通常已启动）
systemctl start rpcbind
systemctl enable rpcbind
```

### Ubuntu/Debian

```bash
# 安装 NFS 客户端
apt update
apt install -y nfs-common

# 启动 rpcbind
systemctl start rpcbind
systemctl enable rpcbind
```

---

## 查看可用共享

### showmount 命令

```bash
# 查看服务端共享列表
showmount -e 192.168.1.10

# 输出示例
Export list for 192.168.1.10:
/data/share  192.168.1.0/24
/data/backup 192.168.1.100
/var/www     *

# 查看所有挂载点
showmount -a 192.168.1.10

# 查看服务端导出的目录
showmount -d 192.168.1.10
```

---

## 手动挂载

### 基本挂载

```bash
# 创建挂载点
mkdir -p /mnt/nfs

# 挂载 NFS 共享
mount -t nfs 192.168.1.10:/data/share /mnt/nfs

# 查看挂载
df -h | grep nfs
mount | grep nfs
```

### 指定 NFS 版本

```bash
# 使用 NFSv3
mount -t nfs -o vers=3 192.168.1.10:/data/share /mnt/nfs

# 使用 NFSv4
mount -t nfs -o vers=4 192.168.1.10:/data/share /mnt/nfs

# 使用 NFSv4.1
mount -t nfs -o vers=4.1 192.168.1.10:/data/share /mnt/nfs
```

### 常用挂载选项

```bash
# 完整示例
mount -t nfs -o rw,soft,timeo=30,retrans=3,rsize=32768,wsize=32768 \
  192.168.1.10:/data/share /mnt/nfs
```

---

## 挂载选项详解

### 读写选项

| 选项 | 说明 | 默认 |
|------|------|------|
| `rw` | 读写模式 | 默认 |
| `ro` | 只读模式 | - |

### 超时和重试

| 选项 | 说明 | 默认值 | 推荐值 |
|------|------|--------|--------|
| `soft` | 超时后返回错误 | - | 推荐 |
| `hard` | 超时后一直重试 | 默认 | 不推荐 |
| `timeo=N` | 超时时间（0.1秒） | 600 | 30-100 |
| `retrans=N` | 重试次数 | 3 | 3-5 |

### 性能选项

| 选项 | 说明 | 默认值 | 推荐值 |
|------|------|--------|--------|
| `rsize=N` | 读取块大小（字节） | 1048576 | 32768-1048576 |
| `wsize=N` | 写入块大小（字节） | 1048576 | 32768-1048576 |
| `async` | 异步写入 | - | 性能优先 |
| `sync` | 同步写入 | 默认 | 安全优先 |

### 缓存选项

| 选项 | 说明 |
|------|------|
| `ac` | 启用属性缓存（默认） |
| `noac` | 禁用属性缓存 |
| `actimeo=N` | 属性缓存时间（秒） |
| `acregmin=N` | 文件属性最小缓存时间 |
| `acregmax=N` | 文件属性最大缓存时间 |
| `acdirmin=N` | 目录属性最小缓存时间 |
| `acdirmax=N` | 目录属性最大缓存时间 |

### 其他选项

| 选项 | 说明 |
|------|------|
| `bg` | 后台挂载（失败时不阻塞启动） |
| `fg` | 前台挂载（默认） |
| `intr` | 允许中断 NFS 调用 |
| `nointr` | 不允许中断（默认） |
| `tcp` | 使用 TCP 协议 |
| `udp` | 使用 UDP 协议 |
| `nolock` | 禁用文件锁 |
| `lock` | 启用文件锁（默认） |

---

## 自动挂载（/etc/fstab）

### 基本配置

编辑 `/etc/fstab`：

```bash
# 格式：
# 服务端:共享目录  挂载点  文件系统类型  选项  dump  fsck

# 示例 1：基本挂载
192.168.1.10:/data/share  /mnt/nfs  nfs  defaults  0  0

# 示例 2：指定选项
192.168.1.10:/data/share  /mnt/nfs  nfs  rw,soft,timeo=30  0  0

# 示例 3：NFSv4
192.168.1.10:/data/share  /mnt/nfs  nfs4  defaults  0  0
```

### 推荐配置

```bash
# 生产环境推荐配置
192.168.1.10:/data/share  /mnt/nfs  nfs  \
  rw,soft,bg,timeo=30,retrans=3,rsize=32768,wsize=32768,intr  0  0
```

### 测试配置

```bash
# 测试挂载（不实际挂载）
mount -a -f

# 挂载所有 fstab 中的文件系统
mount -a

# 查看挂载
df -h | grep nfs
```

---

## autofs 自动挂载

### 什么是 autofs？

autofs 是一个自动挂载服务，只在访问时才挂载，空闲时自动卸载，节省资源。

### 安装 autofs

```bash
# CentOS/RHEL
yum install -y autofs

# Ubuntu/Debian
apt install -y autofs

# 启动服务
systemctl start autofs
systemctl enable autofs
```

### 配置 autofs

#### 1. 编辑主配置文件

编辑 `/etc/auto.master`：

```bash
# 格式：挂载点目录  映射文件  选项

# 示例
/mnt/nfs  /etc/auto.nfs  --timeout=60
```

#### 2. 创建映射文件

创建 `/etc/auto.nfs`：

```bash
# 格式：子目录  选项  服务端:共享目录

# 示例 1：基本配置
share  -rw,soft,timeo=30  192.168.1.10:/data/share

# 示例 2：多个共享
share1  -rw,soft  192.168.1.10:/data/share1
share2  -ro,soft  192.168.1.10:/data/share2
backup  -rw,soft  192.168.1.10:/data/backup
```

#### 3. 重启 autofs

```bash
systemctl restart autofs
```

#### 4. 测试自动挂载

```bash
# 访问目录（自动挂载）
ls /mnt/nfs/share

# 查看挂载
df -h | grep nfs

# 等待超时后自动卸载（默认 60 秒）
```

### autofs 通配符配置

编辑 `/etc/auto.nfs`：

```bash
# 使用通配符，自动匹配所有子目录
*  -rw,soft,timeo=30  192.168.1.10:/data/&
```

访问示例：

```bash
# 访问 /mnt/nfs/share 自动挂载 192.168.1.10:/data/share
ls /mnt/nfs/share

# 访问 /mnt/nfs/backup 自动挂载 192.168.1.10:/data/backup
ls /mnt/nfs/backup
```

---

## 卸载 NFS

### 手动卸载

```bash
# 卸载 NFS
umount /mnt/nfs

# 强制卸载（如果设备忙）
umount -f /mnt/nfs

# 懒卸载（等待空闲后卸载）
umount -l /mnt/nfs
```

### 查看占用进程

```bash
# 查看哪些进程在使用挂载点
lsof /mnt/nfs
fuser -m /mnt/nfs

# 杀死占用进程
fuser -km /mnt/nfs
```

---

## 性能优化

### 1. 调整块大小

```bash
# 增大读写块大小（提高大文件传输性能）
mount -t nfs -o rsize=1048576,wsize=1048576 192.168.1.10:/data/share /mnt/nfs
```

**建议**：
- 千兆网络：rsize=32768, wsize=32768
- 万兆网络：rsize=1048576, wsize=1048576

### 2. 使用异步模式

```bash
# 异步写入（提高写入性能，但可能丢失数据）
mount -t nfs -o async 192.168.1.10:/data/share /mnt/nfs
```

**注意**：生产环境慎用，可能导致数据丢失。

### 3. 调整缓存时间

```bash
# 增加属性缓存时间（减少网络请求）
mount -t nfs -o actimeo=60 192.168.1.10:/data/share /mnt/nfs
```

### 4. 使用 TCP 协议

```bash
# 使用 TCP（更可靠，适合广域网）
mount -t nfs -o tcp 192.168.1.10:/data/share /mnt/nfs
```

### 5. 禁用文件锁

```bash
# 禁用文件锁（提高性能，但不支持并发写入）
mount -t nfs -o nolock 192.168.1.10:/data/share /mnt/nfs
```

### 6. 使用 NFSv4

```bash
# NFSv4 性能更好
mount -t nfs -o vers=4 192.168.1.10:/data/share /mnt/nfs
```

---

## 实战案例

### 案例 1：Web 服务器挂载静态资源

**需求**：Web 服务器挂载 NFS 共享的静态资源目录

```bash
# 1. 创建挂载点
mkdir -p /var/www/html/static

# 2. 手动挂载测试
mount -t nfs -o rw,soft,timeo=30,rsize=32768,wsize=32768 \
  192.168.1.10:/data/www/static /var/www/html/static

# 3. 测试访问
ls /var/www/html/static

# 4. 配置自动挂载
vim /etc/fstab
192.168.1.10:/data/www/static  /var/www/html/static  nfs  \
  rw,soft,bg,timeo=30,rsize=32768,wsize=32768  0  0

# 5. 测试 fstab
umount /var/www/html/static
mount -a
```

### 案例 2：备份服务器挂载备份目录

**需求**：备份服务器挂载 NFS 备份目录

```bash
# 1. 创建挂载点
mkdir -p /backup

# 2. 配置 fstab
vim /etc/fstab
192.168.1.10:/data/backup  /backup  nfs  \
  rw,soft,bg,timeo=30,retrans=3  0  0

# 3. 挂载
mount -a

# 4. 测试写入
echo "test" > /backup/test.txt
cat /backup/test.txt
```

### 案例 3：开发环境使用 autofs

**需求**：开发人员按需挂载代码目录

```bash
# 1. 安装 autofs
yum install -y autofs

# 2. 配置主文件
vim /etc/auto.master
/mnt/code  /etc/auto.code  --timeout=300

# 3. 配置映射文件
vim /etc/auto.code
project1  -rw,soft  192.168.1.10:/data/code/project1
project2  -rw,soft  192.168.1.10:/data/code/project2
project3  -rw,soft  192.168.1.10:/data/code/project3

# 4. 启动 autofs
systemctl restart autofs

# 5. 测试访问
ls /mnt/code/project1  # 自动挂载
ls /mnt/code/project2  # 自动挂载
```

---

## 监控和故障排查

### 查看 NFS 统计信息

```bash
# 查看 NFS 统计
nfsstat

# 查看客户端统计
nfsstat -c

# 查看服务端统计
nfsstat -s

# 查看挂载信息
nfsstat -m
```

### 查看挂载状态

```bash
# 查看所有挂载
mount | grep nfs

# 查看 NFS 挂载详情
df -h -t nfs

# 查看挂载选项
cat /proc/mounts | grep nfs
```

### 测试 NFS 连接

```bash
# 测试服务端连通性
ping 192.168.1.10

# 测试 NFS 端口
telnet 192.168.1.10 2049

# 查看服务端共享
showmount -e 192.168.1.10
```

### 查看日志

```bash
# 查看系统日志
tail -f /var/log/messages

# 查看 NFS 相关日志
journalctl -u nfs-client -f

# 查看挂载错误
dmesg | grep nfs
```

---

## 常见问题

### 1. 挂载超时

**现象**：`mount.nfs: Connection timed out`

**原因**：
- 服务端 NFS 服务未启动
- 防火墙阻止连接
- 网络不通

**解决**：
```bash
# 检查网络
ping 192.168.1.10

# 检查端口
telnet 192.168.1.10 2049

# 检查服务端共享
showmount -e 192.168.1.10

# 检查防火墙
firewall-cmd --list-all
```

### 2. 权限拒绝

**现象**：`Permission denied`

**原因**：
- 服务端配置权限不足
- 客户端 IP 不在允许列表
- 目录权限不足

**解决**：
```bash
# 检查服务端配置
cat /etc/exports

# 检查服务端目录权限
ls -ld /data/share

# 检查客户端 IP
ip addr
```

### 3. 卸载失败（设备忙）

**现象**：`device is busy`

**解决**：
```bash
# 查看占用进程
lsof /mnt/nfs
fuser -m /mnt/nfs

# 杀死进程
fuser -km /mnt/nfs

# 强制卸载
umount -f /mnt/nfs

# 懒卸载
umount -l /mnt/nfs
```

### 4. 性能慢

**解决**：
```bash
# 调整块大小
mount -o remount,rsize=1048576,wsize=1048576 /mnt/nfs

# 使用异步模式
mount -o remount,async /mnt/nfs

# 增加缓存时间
mount -o remount,actimeo=60 /mnt/nfs
```

---

## 实战练习

### 练习 1：手动挂载 NFS

```bash
# 1. 查看服务端共享
showmount -e 192.168.1.10

# 2. 创建挂载点
mkdir -p /mnt/nfs

# 3. 挂载
mount -t nfs 192.168.1.10:/data/share /mnt/nfs

# 4. 测试
ls /mnt/nfs
echo "test" > /mnt/nfs/test.txt

# 5. 卸载
umount /mnt/nfs
```

### 练习 2：配置自动挂载

```bash
# 1. 编辑 fstab
vim /etc/fstab
192.168.1.10:/data/share  /mnt/nfs  nfs  rw,soft,bg  0  0

# 2. 测试
mount -a
df -h | grep nfs

# 3. 重启测试
reboot
df -h | grep nfs
```

### 练习 3：配置 autofs

```bash
# 1. 安装 autofs
yum install -y autofs

# 2. 配置
vim /etc/auto.master
/mnt/auto  /etc/auto.nfs  --timeout=60

vim /etc/auto.nfs
share  -rw,soft  192.168.1.10:/data/share

# 3. 启动
systemctl restart autofs

# 4. 测试
ls /mnt/auto/share
```

---

## 小结

本节学习了：

✅ NFS 客户端的安装和配置  
✅ 手动挂载和自动挂载（fstab）  
✅ autofs 自动挂载服务  
✅ 挂载选项和性能优化  
✅ 监控和故障排查  
✅ 实战案例和常见问题  

至此，NFS 网络文件系统的学习全部完成！

---

## 扩展阅读

- [NFS 客户端优化指南](https://wiki.linux-nfs.org/wiki/index.php/NFS_Client)
- [autofs 官方文档](https://www.kernel.org/doc/html/latest/filesystems/autofs.html)
- [NFS 性能调优](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_file_systems/mounting-nfs-shares_managing-file-systems)
