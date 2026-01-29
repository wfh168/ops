# NFS 服务端配置

## NFS 配置文件

### 主配置文件：/etc/exports

`/etc/exports` 是 NFS 的主配置文件，用于定义哪些目录可以被哪些客户端访问。

**基本语法**：

```
共享目录  客户端(选项)  客户端(选项)
```

**示例**：

```bash
/data/share  192.168.1.100(rw,sync)  192.168.1.101(ro)
/var/www     192.168.1.0/24(rw,sync,no_root_squash)
/backup      *(ro,sync,all_squash)
```

---

## 客户端指定方式

### 1. 单个主机

```bash
# 指定 IP 地址
/data/share  192.168.1.100(rw,sync)

# 指定主机名
/data/share  client1.example.com(rw,sync)
```

### 2. 网段

```bash
# CIDR 格式
/data/share  192.168.1.0/24(rw,sync)

# 子网掩码格式
/data/share  192.168.1.0/255.255.255.0(rw,sync)
```

### 3. 通配符

```bash
# 所有主机
/data/share  *(ro,sync)

# 域名通配符
/data/share  *.example.com(rw,sync)
```

### 4. 多个客户端

```bash
# 空格分隔
/data/share  192.168.1.100(rw) 192.168.1.101(ro) 192.168.1.102(rw)
```

---

## NFS 共享选项

### 权限选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `ro` | 只读 | - |
| `rw` | 读写 | - |
| `no_root_squash` | 不压缩 root 用户权限 | - |
| `root_squash` | 压缩 root 用户为 nobody | 默认 |
| `all_squash` | 压缩所有用户为 nobody | - |
| `anonuid=UID` | 指定匿名用户的 UID | 65534 |
| `anongid=GID` | 指定匿名用户的 GID | 65534 |

### 同步选项

| 选项 | 说明 | 推荐 |
|------|------|------|
| `sync` | 同步写入磁盘 | ✅ 推荐 |
| `async` | 异步写入（先写缓存） | ⚠️ 性能好但不安全 |

### 其他选项

| 选项 | 说明 |
|------|------|
| `subtree_check` | 检查子目录权限 |
| `no_subtree_check` | 不检查子目录权限（推荐） |
| `secure` | 限制客户端端口 < 1024 |
| `insecure` | 允许客户端端口 > 1024 |
| `wdelay` | 延迟写入（提高性能） |
| `no_wdelay` | 立即写入 |

---

## 配置示例

### 示例 1：基本共享（只读）

```bash
# 共享 /data/public 目录给所有客户端，只读
/data/public  *(ro,sync,no_subtree_check)
```

### 示例 2：读写共享（指定网段）

```bash
# 共享 /data/share 给 192.168.1.0/24 网段，读写权限
/data/share  192.168.1.0/24(rw,sync,no_subtree_check)
```

### 示例 3：不压缩 root 权限

```bash
# 允许客户端 root 用户保持 root 权限
/data/backup  192.168.1.100(rw,sync,no_root_squash,no_subtree_check)
```

### 示例 4：压缩所有用户

```bash
# 所有用户都映射为 nobody
/data/upload  192.168.1.0/24(rw,sync,all_squash,anonuid=1000,anongid=1000)
```

### 示例 5：多个客户端不同权限

```bash
# 192.168.1.100 读写，其他只读
/data/share  192.168.1.100(rw,sync) 192.168.1.0/24(ro,sync)
```

### 示例 6：Web 服务器集群共享

```bash
# 多台 Web 服务器共享静态资源
/var/www/html  192.168.1.10(rw,sync,no_root_squash) \
               192.168.1.11(rw,sync,no_root_squash) \
               192.168.1.12(rw,sync,no_root_squash)
```

---

## 配置步骤

### 1. 创建共享目录

```bash
# 创建目录
mkdir -p /data/share

# 设置权限
chmod 755 /data/share

# 设置所有者（可选）
chown nobody:nobody /data/share
```

### 2. 编辑配置文件

```bash
# 编辑 /etc/exports
vim /etc/exports

# 添加共享配置
/data/share  192.168.1.0/24(rw,sync,no_subtree_check)
```

### 3. 使配置生效

```bash
# 方法 1：重新加载配置（推荐）
exportfs -arv

# 方法 2：重启 NFS 服务
systemctl restart nfs-server

# 方法 3：仅重新导出
exportfs -r
```

### 4. 查看共享列表

```bash
# 查看当前共享
exportfs -v

# 查看可挂载的共享
showmount -e localhost
```

---

## exportfs 命令详解

### 常用选项

```bash
# -a：导出或取消所有目录
# -r：重新导出所有目录
# -u：取消导出
# -v：显示详细信息

# 导出所有共享
exportfs -arv

# 取消所有共享
exportfs -auv

# 重新导出
exportfs -r

# 查看当前共享
exportfs -v

# 导出指定目录
exportfs -o rw,sync 192.168.1.100:/data/share

# 取消指定共享
exportfs -u 192.168.1.100:/data/share
```

---

## showmount 命令

### 查看共享信息

```bash
# 查看服务端共享列表
showmount -e 192.168.1.10

# 输出示例
Export list for 192.168.1.10:
/data/share  192.168.1.0/24
/data/backup 192.168.1.100

# 查看已挂载的客户端
showmount -a 192.168.1.10

# 查看客户端挂载的目录
showmount -d 192.168.1.10
```

---

## 权限管理

### root_squash vs no_root_squash

#### root_squash（默认）

```bash
# 客户端 root 用户被映射为 nobody
/data/share  192.168.1.0/24(rw,sync,root_squash)
```

**效果**：
- 客户端 root 用户 → 服务端 nobody 用户
- 安全性高，防止客户端 root 破坏服务端文件

#### no_root_squash

```bash
# 客户端 root 用户保持 root 权限
/data/share  192.168.1.0/24(rw,sync,no_root_squash)
```

**效果**：
- 客户端 root 用户 → 服务端 root 用户
- 方便管理，但安全性低

### all_squash

```bash
# 所有用户都映射为 nobody
/data/upload  192.168.1.0/24(rw,sync,all_squash,anonuid=1000,anongid=1000)
```

**效果**：
- 所有客户端用户 → 服务端指定用户（UID=1000）
- 适合上传目录，统一权限管理

---

## 实战案例

### 案例 1：Web 服务器静态资源共享

**需求**：3 台 Web 服务器共享静态资源目录

**服务端配置**：

```bash
# 1. 创建共享目录
mkdir -p /data/www/static
chown www:www /data/www/static
chmod 755 /data/www/static

# 2. 配置 NFS
vim /etc/exports
/data/www/static  192.168.1.10(rw,sync,no_root_squash) \
                  192.168.1.11(rw,sync,no_root_squash) \
                  192.168.1.12(rw,sync,no_root_squash)

# 3. 使配置生效
exportfs -arv

# 4. 验证
showmount -e localhost
```

### 案例 2：备份服务器

**需求**：多台服务器将备份文件写入 NFS 共享目录

**服务端配置**：

```bash
# 1. 创建备份目录
mkdir -p /data/backup
chmod 777 /data/backup

# 2. 配置 NFS（所有用户映射为 backup 用户）
useradd -u 2000 backup
vim /etc/exports
/data/backup  192.168.1.0/24(rw,sync,all_squash,anonuid=2000,anongid=2000)

# 3. 使配置生效
exportfs -arv
```

### 案例 3：开发环境代码共享

**需求**：开发团队共享代码目录

**服务端配置**：

```bash
# 1. 创建代码目录
mkdir -p /data/code
chown developer:developer /data/code
chmod 775 /data/code

# 2. 配置 NFS
vim /etc/exports
/data/code  192.168.1.0/24(rw,sync,no_root_squash,no_subtree_check)

# 3. 使配置生效
exportfs -arv
```

---

## 安全配置

### 1. 限制客户端

```bash
# 只允许特定 IP 访问
/data/share  192.168.1.100(rw,sync) 192.168.1.101(rw,sync)

# 不要使用 * 通配符
# 错误示例：/data/share  *(rw,sync)
```

### 2. 使用 root_squash

```bash
# 默认启用 root_squash
/data/share  192.168.1.0/24(rw,sync,root_squash)
```

### 3. 只读共享

```bash
# 对不需要写入的目录使用只读
/data/public  192.168.1.0/24(ro,sync)
```

### 4. 使用防火墙

```bash
# 只允许特定 IP 访问 NFS 端口
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="nfs" accept'
firewall-cmd --reload
```

---

## 常见问题

### 1. 配置修改后不生效

**解决**：
```bash
# 重新加载配置
exportfs -arv

# 或重启服务
systemctl restart nfs-server
```

### 2. 权限拒绝

**原因**：
- 服务端目录权限不足
- NFS 配置权限不足
- SELinux 阻止

**解决**：
```bash
# 检查目录权限
ls -ld /data/share

# 修改权限
chmod 755 /data/share

# 检查 SELinux
getenforce

# 临时关闭 SELinux
setenforce 0
```

### 3. 无法查看共享列表

**解决**：
```bash
# 检查 rpcbind 服务
systemctl status rpcbind

# 检查 NFS 服务
systemctl status nfs-server

# 查看日志
journalctl -u nfs-server -f
```

---

## 实战练习

### 练习 1：配置基本共享

配置 NFS 共享目录，允许指定网段读写访问。

```bash
# 1. 创建目录
mkdir -p /data/share
chmod 755 /data/share

# 2. 配置共享
echo "/data/share  192.168.1.0/24(rw,sync,no_subtree_check)" >> /etc/exports

# 3. 使配置生效
exportfs -arv

# 4. 验证
showmount -e localhost
```

### 练习 2：配置多权限共享

为不同客户端配置不同权限。

```bash
# 编辑配置
vim /etc/exports
/data/share  192.168.1.100(rw,sync,no_root_squash) \
             192.168.1.101(ro,sync) \
             192.168.1.0/24(ro,sync)

# 使配置生效
exportfs -arv
```

### 练习 3：配置用户映射

配置 all_squash，将所有用户映射为指定用户。

```bash
# 创建用户
useradd -u 3000 nfsuser

# 配置共享
vim /etc/exports
/data/upload  192.168.1.0/24(rw,sync,all_squash,anonuid=3000,anongid=3000)

# 使配置生效
exportfs -arv

# 设置目录所有者
chown nfsuser:nfsuser /data/upload
```

---

## 小结

本节学习了：

✅ NFS 配置文件 /etc/exports 的语法  
✅ 客户端指定方式（IP、网段、通配符）  
✅ NFS 共享选项（权限、同步、用户映射）  
✅ exportfs 和 showmount 命令的使用  
✅ 权限管理（root_squash、all_squash）  
✅ 实战案例和安全配置  

下一节将学习 NFS 客户端的配置和挂载。
