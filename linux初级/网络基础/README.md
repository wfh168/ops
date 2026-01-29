# 网络基础学习指南

## 学习路线

```
01_网络基础概念.md    ──▶  OSI模型、IP、TCP/UDP
        │
        ▼
02_网络配置.md        ──▶  IP配置、网卡管理
        │
        ▼
03_网络诊断工具.md    ──▶  ping、traceroute、netstat
```

## 核心知识点

### 网络模型
- OSI 七层模型
- TCP/IP 四层模型

### IP 地址
- IPv4 地址分类
- 子网掩码
- CIDR 表示法
- 私有 IP 地址

### 协议
- TCP（可靠）
- UDP（快速）
- ICMP（诊断）
- ARP（地址解析）

### 网络设备
- 网卡（NIC）
- 交换机（Switch）
- 路由器（Router）
- 网关（Gateway）

## 常用命令速查

### 查看网络配置

```bash
ip addr                       # 查看 IP 地址
ip link                       # 查看网卡状态
ip route                      # 查看路由表
ifconfig                      # 传统命令
```

### 网络诊断

```bash
ping www.baidu.com            # 测试连通性
traceroute www.baidu.com      # 追踪路由
nslookup www.baidu.com        # DNS 查询
dig www.baidu.com             # DNS 详细查询
telnet 192.168.1.1 80         # 测试端口
```

### 网络连接

```bash
netstat -tunlp                # 查看监听端口
ss -tunlp                     # 更快的 netstat
lsof -i :80                   # 查看端口占用
```

### 网络配置

```bash
# 临时配置
ip addr add 192.168.1.100/24 dev eth0
ip route add default via 192.168.1.1

# 永久配置
vim /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl restart network
```

## 实战场景

### 场景1：配置静态 IP

```bash
# 编辑网卡配置
vim /etc/sysconfig/network-scripts/ifcfg-eth0

BOOTPROTO=static
IPADDR=192.168.1.100
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=8.8.8.8

# 重启网络
systemctl restart network
```

### 场景2：网络故障排查

```bash
# 1. 检查网卡状态
ip link show

# 2. 检查 IP 配置
ip addr

# 3. 测试网关
ping 192.168.1.1

# 4. 测试外网
ping 8.8.8.8

# 5. 测试 DNS
ping www.baidu.com
```

### 场景3：查看网络连接

```bash
# 查看所有连接
netstat -an

# 查看监听端口
netstat -tunlp

# 统计连接状态
netstat -an | awk '/^tcp/ {state[$NF]++} END{for(s in state) print s, state[s]}'
```

## 网络配置文件

### CentOS 7/8

```bash
# 网卡配置
/etc/sysconfig/network-scripts/ifcfg-eth0

# DNS 配置
/etc/resolv.conf

# 主机名
/etc/hostname

# hosts 文件
/etc/hosts
```

## 最佳实践

### 1. 使用静态 IP

```bash
# 服务器建议使用静态 IP
# 避免 DHCP 导致 IP 变化
```

### 2. 配置多个 DNS

```bash
# 配置主备 DNS
DNS1=8.8.8.8
DNS2=114.114.114.114
```

### 3. 网络安全

```bash
# 禁用不必要的网络服务
# 配置防火墙
# 使用 SSH 密钥认证
```

## 常见问题

### 1. 网络不通

```bash
# 检查网卡状态
ip link show

# 检查 IP 配置
ip addr

# 检查路由
ip route

# 检查 DNS
cat /etc/resolv.conf
```

### 2. DNS 解析失败

```bash
# 测试 DNS
nslookup www.baidu.com

# 修改 DNS
vim /etc/resolv.conf
nameserver 8.8.8.8
```

### 3. 端口被占用

```bash
# 查看端口占用
lsof -i :80
netstat -tunlp | grep :80

# 杀死进程
kill -9 PID
```

## 面试常考

1. OSI 七层模型是什么？
2. TCP 和 UDP 的区别？
3. TCP 三次握手过程？
4. 如何配置静态 IP？
5. 如何排查网络故障？

## 下一步

完成网络基础学习后，你已经掌握了 Linux 初级的所有核心知识！

现在可以：
1. 复习巩固初级知识
2. 开始学习 Linux 中级内容
3. 实践项目，搭建真实环境

加油！💪
