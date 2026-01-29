# Linux 系统优化学习指南

## 学习路线

```
01_系统初始化优化.md    ──▶  系统安装后的基础优化
        │
        ▼
02_性能监控与调优.md    ──▶  监控系统性能并调优
        │
        ▼
03_安全加固.md          ──▶  提高系统安全性
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_系统初始化优化.md | SELinux、防火墙、YUM源、SSH | 0.5 天 |
| 02_性能监控与调优.md | CPU、内存、磁盘、网络监控 | 1 天 |
| 03_安全加固.md | 账号、SSH、防火墙、日志安全 | 1 天 |

## 优化三大方向

### 1. 系统初始化
- 关闭 SELinux
- 配置防火墙
- 配置 YUM 源
- 时间同步
- SSH 优化
- 资源限制

### 2. 性能优化
- CPU 监控与调优
- 内存监控与调优
- 磁盘 I/O 优化
- 网络优化

### 3. 安全加固
- 账号安全
- SSH 安全
- 防火墙配置
- 文件系统安全
- 日志审计

---

## 系统初始化速查

### 关闭 SELinux

```bash
# 临时关闭
setenforce 0

# 永久关闭
vim /etc/selinux/config
# SELINUX=disabled
```

### 关闭防火墙

```bash
systemctl stop firewalld
systemctl disable firewalld
```

### 配置 YUM 源

```bash
# 备份
cd /etc/yum.repos.d/
mkdir backup
mv *.repo backup/

# 配置阿里云源
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum install -y epel-release
yum makecache
```

### 时间同步

```bash
yum install -y chrony
systemctl start chronyd
systemctl enable chronyd
timedatectl set-timezone Asia/Shanghai
```

### SSH 优化

```bash
vim /etc/ssh/sshd_config
# Port 2222
# PermitRootLogin no
# PasswordAuthentication no

systemctl restart sshd
```

---

## 性能监控速查

### CPU 监控

```bash
top                           # 实时监控
htop                          # 更友好的 top
uptime                        # 系统负载
mpstat -P ALL 1               # 多核 CPU
ps aux --sort=-%cpu | head    # CPU 占用最高的进程
```

### 内存监控

```bash
free -h                       # 内存使用
vmstat 1                      # 虚拟内存统计
ps aux --sort=-%mem | head    # 内存占用最高的进程
```

### 磁盘监控

```bash
df -h                         # 磁盘使用
du -sh /*                     # 目录大小
iostat -x 1                   # I/O 统计
iotop                         # I/O 进程监控
```

### 网络监控

```bash
netstat -tunlp                # 网络连接
ss -tunlp                     # 更快的 netstat
iftop                         # 实时流量
nload                         # 网络流量
```

---

## 安全加固速查

### 账号安全

```bash
# 锁定账号
usermod -L username

# 密码策略
vim /etc/login.defs
# PASS_MAX_DAYS 90
# PASS_MIN_DAYS 7
# PASS_MIN_LEN 8

# 密码复杂度
vim /etc/security/pwquality.conf
# minlen = 8
# lcredit = -1
# ucredit = -1
# dcredit = -1
```

### SSH 安全

```bash
vim /etc/ssh/sshd_config
# Port 2222
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes

systemctl restart sshd
```

### 防火墙

```bash
# firewalld
systemctl start firewalld
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --reload

# iptables
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
service iptables save
```

### 日志审计

```bash
# 查看登录失败
grep "Failed password" /var/log/secure

# 查看 sudo 使用
grep "sudo" /var/log/secure

# 查看登录记录
last
lastb
```

---

## 优化脚本模板

### 系统初始化脚本

```bash
#!/bin/bash

# 关闭 SELinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 配置 YUM 源
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum install -y epel-release
yum makecache

# 时间同步
yum install -y chrony
systemctl start chronyd
systemctl enable chronyd
timedatectl set-timezone Asia/Shanghai

# 安装常用工具
yum install -y vim wget curl net-tools lsof telnet tree htop

# 优化文件描述符
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

# 优化内核参数
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
fs.file-max = 655350
EOF
sysctl -p

echo "系统优化完成，建议重启"
```

---

## 性能调优参数

### CPU 调优

```bash
# 调整进程优先级
nice -n 10 command
renice -n 10 -p PID

# 绑定 CPU 核心
taskset -c 0,1 command
```

### 内存调优

```bash
# /etc/sysctl.conf
vm.swappiness = 10
vm.vfs_cache_pressure = 50
```

### 磁盘调优

```bash
# I/O 调度器
echo deadline > /sys/block/sda/queue/scheduler

# noatime 挂载
# /etc/fstab
/dev/sda1  /  ext4  defaults,noatime  0  0
```

### 网络调优

```bash
# /etc/sysctl.conf
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
```

---

## 安全检查清单

### 系统安全
- [ ] 关闭不必要的服务
- [ ] 最小化安装
- [ ] 定期更新补丁
- [ ] 配置防火墙

### 账号安全
- [ ] 禁用不必要的账号
- [ ] 设置密码策略
- [ ] 配置登录失败锁定
- [ ] 检查空密码账号

### SSH 安全
- [ ] 修改默认端口
- [ ] 禁用 root 登录
- [ ] 使用密钥认证
- [ ] 配置超时设置

### 文件安全
- [ ] 设置关键文件权限
- [ ] 检查 SUID/SGID 文件
- [ ] 配置文件完整性检查

### 日志审计
- [ ] 配置日志记录
- [ ] 配置日志轮转
- [ ] 定期检查日志

---

## 常用监控命令

| 监控对象 | 命令 | 说明 |
|---------|------|------|
| CPU | top, htop, mpstat | 实时监控 |
| 内存 | free, vmstat | 内存使用 |
| 磁盘 | df, du, iostat | 磁盘和 I/O |
| 网络 | netstat, ss, iftop | 网络连接和流量 |
| 进程 | ps, top, htop | 进程监控 |
| 综合 | dstat, sar | 综合监控 |

---

## 面试常考

1. 如何优化 Linux 系统性能？
2. 如何查看系统负载？
3. 如何加固 SSH 安全？
4. 如何配置防火墙？
5. 如何监控系统资源使用？

---

## 学习建议

1. **实践为主** - 在虚拟机中实际操作
2. **循序渐进** - 先初始化，再优化，最后加固
3. **理解原理** - 知道为什么要这样优化
4. **记录笔记** - 记录自己的优化经验
5. **定期检查** - 养成定期检查系统的习惯

---

## 总结

完成 Linux 系统优化学习后，你已经掌握了：
- 系统初始化配置
- 性能监控与调优
- 安全加固措施

这些是 Linux 运维的基础技能，为后续学习中级和高级内容打下了坚实的基础。

## 下一步

完成 Linux 初级所有模块后，可以进入 Linux 中级学习，包括：
- Nginx Web 服务器
- MySQL 数据库
- 自动化运维（Ansible）
- 容器技术（Docker）
- 集群技术（Kubernetes）
