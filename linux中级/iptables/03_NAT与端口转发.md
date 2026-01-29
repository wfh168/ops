# NAT 与端口转发

## 什么是 NAT？

**NAT（Network Address Translation，网络地址转换）** 是一种将私有 IP 地址转换为公网 IP 地址的技术，使内网主机可以访问外网。

### NAT 的类型

1. **SNAT（Source NAT）**：源地址转换，内网访问外网
2. **DNAT（Destination NAT）**：目标地址转换，外网访问内网
3. **MASQUERADE**：动态 SNAT，适用于动态 IP

---

## SNAT（源地址转换）

### 应用场景

内网主机通过网关访问外网，需要将内网 IP 转换为公网 IP。

```
内网主机 → 网关（SNAT）→ 外网
192.168.1.10 → 1.2.3.4 → 互联网
```

### 基本配置

#### 1. 开启 IP 转发

```bash
# 临时开启
echo 1 > /proc/sys/net/ipv4/ip_forward

# 永久开启
vim /etc/sysctl.conf
net.ipv4.ip_forward = 1

# 使配置生效
sysctl -p
```

#### 2. 配置 SNAT 规则

```bash
# 基本 SNAT（固定公网 IP）
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j SNAT --to-source 1.2.3.4

# 参数说明：
# -t nat：使用 nat 表
# -A POSTROUTING：在 POSTROUTING 链添加规则
# -s 192.168.1.0/24：源地址为内网网段
# -o eth0：出站接口为 eth0
# -j SNAT：动作为 SNAT
# --to-source 1.2.3.4：转换为公网 IP
```

### MASQUERADE（动态 SNAT）

适用于公网 IP 动态变化的场景（如 ADSL、DHCP）。

```bash
# 使用 MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# MASQUERADE 会自动获取出站接口的 IP 地址
```

### 完整示例：内网共享上网

```bash
#!/bin/bash
# 内网共享上网配置

# 1. 开启 IP 转发
echo 1 > /proc/sys/net/ipv4/ip_forward

# 2. 清空 nat 表规则
iptables -t nat -F

# 3. 配置 SNAT（假设 eth0 是外网接口）
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# 4. 允许转发
iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# 5. 保存规则
service iptables save

echo "内网共享上网配置完成！"
echo "内网主机网关设置为本机 IP：$(ip addr show eth1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"
```

---

## DNAT（目标地址转换）

### 应用场景

外网访问内网服务，需要将公网 IP 和端口转发到内网服务器。

```
外网 → 网关（DNAT）→ 内网服务器
互联网 → 1.2.3.4:80 → 192.168.1.10:80
```

### 基本配置

```bash
# 端口转发（外网 80 端口转发到内网 192.168.1.10:80）
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.10:80

# 允许转发
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 80 -j ACCEPT

# 参数说明：
# -t nat：使用 nat 表
# -A PREROUTING：在 PREROUTING 链添加规则
# -d 1.2.3.4：目标地址为公网 IP
# -p tcp --dport 80：协议为 TCP，端口为 80
# -j DNAT：动作为 DNAT
# --to-destination 192.168.1.10:80：转发到内网服务器
```

### 端口映射

将公网端口映射到内网不同端口：

```bash
# 公网 8080 端口映射到内网 80 端口
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.10:80

# 允许转发
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 80 -j ACCEPT
```

---

## 端口转发实战

### 案例 1：Web 服务器端口转发

**场景**：公网 IP 1.2.3.4，内网 Web 服务器 192.168.1.10

```bash
#!/bin/bash
# Web 服务器端口转发

# 1. 开启 IP 转发
echo 1 > /proc/sys/net/ipv4/ip_forward

# 2. 配置 DNAT（HTTP）
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.10:80

# 3. 配置 DNAT（HTTPS）
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 443 -j DNAT --to-destination 192.168.1.10:443

# 4. 允许转发
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# 5. 配置 SNAT（可选，用于内网服务器访问外网）
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# 6. 保存规则
service iptables save

echo "Web 服务器端口转发配置完成！"
```

### 案例 2：SSH 端口转发

**场景**：公网 2222 端口转发到内网 SSH（22 端口）

```bash
# 配置 DNAT
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 2222 -j DNAT --to-destination 192.168.1.10:22

# 允许转发
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 22 -j ACCEPT

# 测试
ssh -p 2222 root@1.2.3.4
```

### 案例 3：数据库端口转发

**场景**：公网 3306 端口转发到内网 MySQL

```bash
# 配置 DNAT
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 3306 -j DNAT --to-destination 192.168.1.20:3306

# 允许转发（只允许特定 IP）
iptables -A FORWARD -s 1.2.3.100 -d 192.168.1.20 -p tcp --dport 3306 -j ACCEPT

# 测试
mysql -h 1.2.3.4 -u root -p
```

### 案例 4：多服务器负载均衡

**场景**：公网 80 端口轮询转发到多台内网服务器

```bash
# 安装 iptables 扩展模块
yum install -y iptables-services

# 配置轮询转发
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 80 -m statistic --mode nth --every 3 --packet 0 -j DNAT --to-destination 192.168.1.10:80
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 80 -m statistic --mode nth --every 2 --packet 0 -j DNAT --to-destination 192.168.1.11:80
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.12:80

# 允许转发
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 192.168.1.11 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 192.168.1.12 -p tcp --dport 80 -j ACCEPT
```

---

## 本机端口转发（REDIRECT）

### 应用场景

将本机某个端口的流量重定向到另一个端口。

```bash
# 将 80 端口重定向到 8080 端口
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080

# 或使用 OUTPUT 链（本机发起的连接）
iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8080
```

### 透明代理

```bash
# 将所有 HTTP 流量重定向到 Squid 代理（3128 端口）
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 3128

# 排除代理服务器自己
iptables -t nat -A PREROUTING -s 192.168.1.100 -p tcp --dport 80 -j RETURN
```

---

## 完整 NAT 网关配置

### 场景说明

- 网关服务器：双网卡
  - eth0：外网接口（1.2.3.4）
  - eth1：内网接口（192.168.1.1）
- 内网网段：192.168.1.0/24
- 功能：
  - 内网共享上网（SNAT）
  - 端口转发（DNAT）

### 配置脚本

```bash
#!/bin/bash
# NAT 网关完整配置脚本

# 定义变量
WAN_IF="eth0"           # 外网接口
LAN_IF="eth1"           # 内网接口
WAN_IP="1.2.3.4"        # 外网 IP
LAN_NET="192.168.1.0/24" # 内网网段

# 1. 开启 IP 转发
echo "开启 IP 转发..."
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/^#*net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
sysctl -p

# 2. 清空规则
echo "清空现有规则..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# 3. 设置默认策略
echo "设置默认策略..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 4. 允许本地回环
iptables -A INPUT -i lo -j ACCEPT

# 5. 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# 6. 允许内网访问网关
iptables -A INPUT -i $LAN_IF -s $LAN_NET -j ACCEPT

# 7. 允许 SSH（只允许内网）
iptables -A INPUT -i $LAN_IF -p tcp --dport 22 -j ACCEPT

# 8. 配置 SNAT（内网共享上网）
echo "配置 SNAT..."
iptables -t nat -A POSTROUTING -s $LAN_NET -o $WAN_IF -j MASQUERADE

# 9. 允许内网转发
iptables -A FORWARD -s $LAN_NET -o $WAN_IF -j ACCEPT

# 10. 配置 DNAT（端口转发）
echo "配置端口转发..."

# Web 服务器（192.168.1.10）
iptables -t nat -A PREROUTING -d $WAN_IP -p tcp --dport 80 -j DNAT --to-destination 192.168.1.10:80
iptables -t nat -A PREROUTING -d $WAN_IP -p tcp --dport 443 -j DNAT --to-destination 192.168.1.10:443
iptables -A FORWARD -d 192.168.1.10 -p tcp -m multiport --dports 80,443 -j ACCEPT

# SSH 服务器（192.168.1.20，映射到 2222 端口）
iptables -t nat -A PREROUTING -d $WAN_IP -p tcp --dport 2222 -j DNAT --to-destination 192.168.1.20:22
iptables -A FORWARD -d 192.168.1.20 -p tcp --dport 22 -j ACCEPT

# 11. 防护规则
echo "配置防护规则..."

# 防止 SYN 洪水攻击
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# 防止 ping 洪水攻击
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# 防止 IP 欺骗
iptables -A INPUT -i $WAN_IF -s 192.168.0.0/16 -j DROP
iptables -A INPUT -i $WAN_IF -s 10.0.0.0/8 -j DROP
iptables -A INPUT -i $WAN_IF -s 172.16.0.0/12 -j DROP

# 12. 保存规则
echo "保存规则..."
service iptables save

# 13. 显示规则
echo "当前规则："
echo "========== filter 表 =========="
iptables -L -n -v
echo "========== nat 表 =========="
iptables -t nat -L -n -v

echo "NAT 网关配置完成！"
echo "内网主机请设置："
echo "  网关：$(ip addr show $LAN_IF | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"
echo "  DNS：8.8.8.8"
```

---

## 查看 NAT 规则

### 查看 nat 表规则

```bash
# 查看所有 nat 规则
iptables -t nat -L -n -v

# 查看 PREROUTING 链（DNAT）
iptables -t nat -L PREROUTING -n -v

# 查看 POSTROUTING 链（SNAT）
iptables -t nat -L POSTROUTING -n -v

# 查看连接跟踪
cat /proc/net/nf_conntrack
```

### 查看转发规则

```bash
# 查看 FORWARD 链
iptables -L FORWARD -n -v

# 查看转发统计
iptables -L FORWARD -n -v -x
```

---

## 故障排查

### 1. 内网无法上网

**检查**：
```bash
# 检查 IP 转发是否开启
cat /proc/sys/net/ipv4/ip_forward
# 应该输出 1

# 检查 SNAT 规则
iptables -t nat -L POSTROUTING -n -v

# 检查 FORWARD 规则
iptables -L FORWARD -n -v

# 测试网关连通性
ping -c 3 8.8.8.8
```

**解决**：
```bash
# 开启 IP 转发
echo 1 > /proc/sys/net/ipv4/ip_forward

# 添加 SNAT 规则
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# 允许转发
iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT
```

### 2. 端口转发不生效

**检查**：
```bash
# 检查 DNAT 规则
iptables -t nat -L PREROUTING -n -v

# 检查 FORWARD 规则
iptables -L FORWARD -n -v

# 测试端口
telnet 1.2.3.4 80
```

**解决**：
```bash
# 添加 DNAT 规则
iptables -t nat -A PREROUTING -d 1.2.3.4 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.10:80

# 允许转发
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 80 -j ACCEPT
```

### 3. 连接跟踪表满

**现象**：`nf_conntrack: table full, dropping packet`

**解决**：
```bash
# 增加连接跟踪表大小
echo 262144 > /proc/sys/net/netfilter/nf_conntrack_max

# 永久生效
vim /etc/sysctl.conf
net.netfilter.nf_conntrack_max = 262144
sysctl -p
```

---

## 实战练习

### 练习 1：配置内网共享上网

```bash
# 1. 开启 IP 转发
echo 1 > /proc/sys/net/ipv4/ip_forward

# 2. 配置 SNAT
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# 3. 允许转发
iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# 4. 在内网主机测试
# 设置网关为本机 IP
# ping 8.8.8.8
```

### 练习 2：配置端口转发

```bash
# 1. 配置 DNAT（80 端口转发到内网）
iptables -t nat -A PREROUTING -d 公网IP -p tcp --dport 80 -j DNAT --to-destination 192.168.1.10:80

# 2. 允许转发
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 80 -j ACCEPT

# 3. 测试
curl http://公网IP
```

### 练习 3：配置本机端口重定向

```bash
# 1. 将 80 端口重定向到 8080
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080

# 2. 启动服务监听 8080 端口
python3 -m http.server 8080

# 3. 测试
curl http://localhost:80
```

---

## 小结

本节学习了：

✅ NAT 的概念和类型（SNAT、DNAT、MASQUERADE）  
✅ SNAT 配置（内网共享上网）  
✅ DNAT 配置（端口转发）  
✅ 本机端口重定向（REDIRECT）  
✅ 完整 NAT 网关配置  
✅ 故障排查技巧  

至此，iptables 防火墙的学习全部完成！

---

## 扩展阅读

- [NAT 详解](https://www.netfilter.org/documentation/HOWTO/NAT-HOWTO.html)
- [iptables NAT 配置](https://wiki.archlinux.org/title/Iptables#Network_Address_Translation)
- [Linux 路由和转发](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
