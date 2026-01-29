# NFS 基础与安装

## 什么是 NFS？

**NFS（Network File System，网络文件系统）** 是一种分布式文件系统协议，允许网络中的计算机通过网络共享文件和目录。

### NFS 的特点

✅ **透明访问**：客户端访问远程文件就像访问本地文件一样  
✅ **跨平台**：支持 Linux、Unix、macOS 等系统  
✅ **集中管理**：统一管理共享数据，便于备份和维护  
✅ **节省空间**：多台服务器共享同一份数据  
✅ **简单易用**：配置简单，使用方便  

### NFS 的应用场景

1. **Web 服务器集群**：多台 Web 服务器共享静态资源（图片、CSS、JS）
2. **数据备份**：集中存储备份数据
3. **开发环境**：多个开发者共享代码和资源
4. **日志收集**：多台服务器将日志写入共享目录
5. **容器存储**：为 Docker、Kubernetes 提供持久化存储

---

## NFS 工作原理

### NFS 架构

```
┌─────────────┐                    ┌─────────────┐
│  NFS 客户端  │                    │  NFS 服务端  │
│             │                    │             │
│  应用程序    │                    │  共享目录    │
│     ↓       │                    │     ↑       │
│  VFS 层     │                    │  NFS 服务   │
│     ↓       │                    │     ↑       │
│ NFS 客户端  │ ←─── 网络通信 ───→ │  NFS 服务端  │
│             │      RPC 协议      │             │
└─────────────┘                    └─────────────┘
```

### NFS 通信流程

1. **客户端发起请求**：应用程序访问挂载的 NFS 目录
2. **RPC 调用**：NFS 客户端通过 RPC 协议向服务端发送请求
3. **服务端处理**：NFS 服务端接收请求，访问本地文件系统
4. **返回结果**：服务端将结果通过 RPC 返回给客户端
5. **客户端响应**：客户端将结果返回给应用程序

### NFS 相关进程和端口

| 进程/服务 | 作用 | 端口 |
|----------|------|------|
| `nfs` | NFS 主服务 | 2049 |
| `rpcbind` | RPC 端口映射服务 | 111 |
| `rpc.mountd` | 挂载服务 | 动态 |
| `rpc.statd` | 状态监控 | 动态 |
| `rpc.lockd` | 文件锁服务 | 动态 |

---

## NFS 版本

### 版本对比

| 版本 | 特点 | 适用场景 |
|------|------|----------|
| NFSv3 | 无状态协议，性能好 | 传统 Linux 环境 |
| NFSv4 | 有状态协议，安全性高，支持 ACL | 现代企业环境 |
| NFSv4.1 | 支持并行访问，性能更好 | 高性能需求 |
| NFSv4.2 | 支持服务端复制，稀疏文件 | 云环境 |

### 推荐使用版本

- **生产环境**：NFSv4（安全性和功能更好）
- **兼容性要求**：NFSv3（兼容性最好）
- **高性能需求**：NFSv4.1

---

## 安装 NFS

### CentOS/RHEL 系统

#### 1. 安装 NFS 软件包

```bash
# 服务端安装
yum install -y nfs-utils rpcbind

# 客户端安装（通常已预装）
yum install -y nfs-utils
```

#### 2. 启动服务

```bash
# 启动 rpcbind（必须先启动）
systemctl start rpcbind
systemctl enable rpcbind

# 启动 NFS 服务
systemctl start nfs-server
systemctl enable nfs-server

# 查看服务状态
systemctl status nfs-server
```

#### 3. 查看 NFS 版本

```bash
# 查看支持的 NFS 版本
cat /proc/fs/nfsd/versions

# 输出示例
-2 +3 +4 +4.1 +4.2
```

### Ubuntu/Debian 系统

```bash
# 服务端安装
apt update
apt install -y nfs-kernel-server

# 客户端安装
apt install -y nfs-common

# 启动服务
systemctl start nfs-kernel-server
systemctl enable nfs-kernel-server
```

---

## 配置防火墙

### firewalld（CentOS 7/8）

```bash
# 开放 NFS 服务
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd

# 重载防火墙
firewall-cmd --reload

# 查看开放的服务
firewall-cmd --list-services
```

### iptables

```bash
# 开放必要端口
iptables -A INPUT -p tcp --dport 111 -j ACCEPT
iptables -A INPUT -p tcp --dport 2049 -j ACCEPT
iptables -A INPUT -p udp --dport 111 -j ACCEPT
iptables -A INPUT -p udp --dport 2049 -j ACCEPT

# 保存规则
service iptables save
```

### 固定 NFS 端口（推荐）

编辑 `/etc/sysconfig/nfs`：

```bash
# 固定 mountd 端口
MOUNTD_PORT=20048

# 固定 statd 端口
STATD_PORT=20049

# 固定 lockd 端口
LOCKD_TCPPORT=20050
LOCKD_UDPPORT=20050
```

重启服务：

```bash
systemctl restart nfs-server
```

开放固定端口：

```bash
firewall-cmd --permanent --add-port=20048/tcp
firewall-cmd --permanent --add-port=20049/tcp
firewall-cmd --permanent --add-port=20050/tcp
firewall-cmd --permanent --add-port=20050/udp
firewall-cmd --reload
```

---

## 验证安装

### 1. 检查服务状态

```bash
# 查看 rpcbind 状态
systemctl status rpcbind

# 查看 NFS 服务状态
systemctl status nfs-server

# 查看所有 NFS 相关进程
ps aux | grep nfs
```

### 2. 检查 RPC 服务

```bash
# 查看 RPC 注册的服务
rpcinfo -p localhost

# 输出示例
   program vers proto   port  service
    100000    4   tcp    111  portmapper
    100000    3   tcp    111  portmapper
    100005    1   udp  20048  mountd
    100005    1   tcp  20048  mountd
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
```

### 3. 检查 NFS 模块

```bash
# 查看 NFS 内核模块
lsmod | grep nfs

# 输出示例
nfsd                  348160  13
nfs                   286720  0
lockd                  94208  2 nfsd,nfs
```

---

## 常见问题

### 1. rpcbind 启动失败

**原因**：端口 111 被占用

**解决**：
```bash
# 查看端口占用
netstat -tunlp | grep 111

# 停止占用进程
kill -9 <PID>

# 重启 rpcbind
systemctl restart rpcbind
```

### 2. NFS 服务启动失败

**原因**：rpcbind 未启动

**解决**：
```bash
# 先启动 rpcbind
systemctl start rpcbind

# 再启动 NFS
systemctl start nfs-server
```

### 3. 防火墙阻止连接

**原因**：防火墙未开放 NFS 端口

**解决**：
```bash
# 临时关闭防火墙测试
systemctl stop firewalld

# 如果可以连接，说明是防火墙问题
# 按照上面的方法配置防火墙规则
```

---

## 实战练习

### 练习 1：安装 NFS 服务

在一台服务器上安装并启动 NFS 服务，验证服务状态。

```bash
# 1. 安装软件包
yum install -y nfs-utils rpcbind

# 2. 启动服务
systemctl start rpcbind nfs-server

# 3. 设置开机自启
systemctl enable rpcbind nfs-server

# 4. 验证服务
systemctl status nfs-server
rpcinfo -p localhost
```

### 练习 2：配置防火墙

配置防火墙，开放 NFS 所需端口。

```bash
# 1. 固定 NFS 端口
vim /etc/sysconfig/nfs
# 添加：
# MOUNTD_PORT=20048
# STATD_PORT=20049

# 2. 重启服务
systemctl restart nfs-server

# 3. 配置防火墙
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-port=20048/tcp
firewall-cmd --reload

# 4. 验证
firewall-cmd --list-all
```

### 练习 3：查看 NFS 信息

使用命令查看 NFS 相关信息。

```bash
# 查看 NFS 版本
cat /proc/fs/nfsd/versions

# 查看 RPC 服务
rpcinfo -p

# 查看 NFS 统计信息
nfsstat

# 查看 NFS 挂载信息
showmount -e localhost
```

---

## 小结

本节学习了：

✅ NFS 的概念和应用场景  
✅ NFS 的工作原理和架构  
✅ NFS 的版本和特点  
✅ 如何安装和启动 NFS 服务  
✅ 如何配置防火墙  
✅ 如何验证 NFS 安装  

下一节将学习如何配置 NFS 服务端和客户端，实现文件共享。

---

## 扩展阅读

- [NFS 官方文档](https://linux-nfs.org/)
- [Red Hat NFS 文档](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_file_systems/exporting-nfs-shares_managing-file-systems)
- [NFS 性能优化指南](https://wiki.linux-nfs.org/wiki/index.php/NFS_Performance)
