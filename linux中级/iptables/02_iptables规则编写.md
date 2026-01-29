# iptables 规则编写

## 规则语法

### 基本语法

```bash
iptables [-t 表名] 命令 链名 [匹配条件] [-j 动作]
```

**参数说明**：
- `-t 表名`：指定表（filter、nat、mangle、raw），默认 filter
- `命令`：操作类型（-A、-I、-D、-R 等）
- `链名`：INPUT、OUTPUT、FORWARD 等
- `匹配条件`：协议、端口、IP 等
- `-j 动作`：ACCEPT、DROP、REJECT 等

---

## 匹配条件

### 1. 协议匹配

```bash
# 匹配 TCP 协议
iptables -A INPUT -p tcp -j ACCEPT

# 匹配 UDP 协议
iptables -A INPUT -p udp -j ACCEPT

# 匹配 ICMP 协议（ping）
iptables -A INPUT -p icmp -j ACCEPT

# 匹配所有协议
iptables -A INPUT -p all -j ACCEPT
```

### 2. 端口匹配

```bash
# 匹配目标端口
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 匹配源端口
iptables -A INPUT -p tcp --sport 1024 -j ACCEPT

# 匹配端口范围
iptables -A INPUT -p tcp --dport 8000:9000 -j ACCEPT

# 匹配多个端口
iptables -A INPUT -p tcp -m multiport --dports 80,443,8080 -j ACCEPT
```

### 3. IP 地址匹配

```bash
# 匹配源 IP
iptables -A INPUT -s 192.168.1.100 -j ACCEPT

# 匹配目标 IP
iptables -A INPUT -d 192.168.1.10 -j ACCEPT

# 匹配 IP 段
iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT

# 排除 IP
iptables -A INPUT ! -s 192.168.1.100 -j DROP
```

### 4. 网络接口匹配

```bash
# 匹配入站接口
iptables -A INPUT -i eth0 -j ACCEPT

# 匹配出站接口
iptables -A OUTPUT -o eth0 -j ACCEPT

# 匹配所有 eth 接口
iptables -A INPUT -i eth+ -j ACCEPT
```

### 5. MAC 地址匹配

```bash
# 匹配 MAC 地址
iptables -A INPUT -m mac --mac-source 00:11:22:33:44:55 -j ACCEPT
```

### 6. 状态匹配

```bash
# 匹配连接状态
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 状态说明：
# NEW：新连接
# ESTABLISHED：已建立的连接
# RELATED：相关连接（如 FTP 数据连接）
# INVALID：无效连接
```

### 7. 时间匹配

```bash
# 匹配时间段（工作时间）
iptables -A INPUT -m time --timestart 09:00 --timestop 18:00 -j ACCEPT

# 匹配星期几
iptables -A INPUT -m time --weekdays Mon,Tue,Wed,Thu,Fri -j ACCEPT

# 匹配日期范围
iptables -A INPUT -m time --datestart 2024-01-01 --datestop 2024-12-31 -j ACCEPT
```

### 8. 限速匹配

```bash
# 限制连接速率（每分钟 10 个连接）
iptables -A INPUT -p tcp --dport 80 -m limit --limit 10/minute -j ACCEPT

# 限制突发连接（允许突发 5 个）
iptables -A INPUT -p tcp --dport 80 -m limit --limit 10/minute --limit-burst 5 -j ACCEPT
```

### 9. 字符串匹配

```bash
# 匹配数据包中的字符串
iptables -A INPUT -m string --string "attack" --algo bm -j DROP

# 匹配 HTTP 请求中的字符串
iptables -A INPUT -p tcp --dport 80 -m string --string "GET /admin" --algo bm -j DROP
```

---

## 常用规则示例

### 1. 允许本地回环

```bash
# 允许 lo 接口（必须）
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
```

### 2. 允许已建立的连接

```bash
# 允许已建立和相关的连接（重要）
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### 3. 允许 SSH

```bash
# 允许所有 IP 访问 SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 只允许特定 IP 访问 SSH
iptables -A INPUT -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT

# 只允许特定网段访问 SSH
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 22 -j ACCEPT
```

### 4. 允许 Web 服务

```bash
# 允许 HTTP
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 允许 HTTPS
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 允许 HTTP 和 HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
```

### 5. 允许 ping

```bash
# 允许 ping（ICMP echo request）
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# 允许所有 ICMP
iptables -A INPUT -p icmp -j ACCEPT
```

### 6. 允许 DNS

```bash
# 允许 DNS 查询（UDP 53）
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# 允许 DNS（TCP 和 UDP）
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
```

### 7. 允许 FTP

```bash
# 允许 FTP 控制连接
iptables -A INPUT -p tcp --dport 21 -j ACCEPT

# 允许 FTP 数据连接（被动模式）
iptables -A INPUT -p tcp --dport 20 -j ACCEPT

# 允许 FTP 相关连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### 8. 允许 MySQL

```bash
# 允许本地访问 MySQL
iptables -A INPUT -p tcp -s 127.0.0.1 --dport 3306 -j ACCEPT

# 允许特定 IP 访问 MySQL
iptables -A INPUT -p tcp -s 192.168.1.100 --dport 3306 -j ACCEPT

# 允许特定网段访问 MySQL
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 3306 -j ACCEPT
```

---

## 防护规则

### 1. 防止 ping 洪水攻击

```bash
# 限制 ping 速率
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
```

### 2. 防止 SYN 洪水攻击

```bash
# 限制 SYN 包速率
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
```

### 3. 防止端口扫描

```bash
# 丢弃无效的数据包
iptables -A INPUT -m state --state INVALID -j DROP

# 限制新连接速率
iptables -A INPUT -p tcp -m state --state NEW -m limit --limit 10/minute -j ACCEPT
```

### 4. 防止 IP 欺骗

```bash
# 拒绝来自外网的内网 IP
iptables -A INPUT -i eth0 -s 192.168.0.0/16 -j DROP
iptables -A INPUT -i eth0 -s 10.0.0.0/8 -j DROP
iptables -A INPUT -i eth0 -s 172.16.0.0/12 -j DROP
```

### 5. 防止暴力破解 SSH

```bash
# 限制 SSH 连接速率（每分钟 3 次）
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 3 --name SSH -j DROP
```

---

## 完整防火墙脚本

### 基础防火墙脚本

```bash
#!/bin/bash
# 基础防火墙配置脚本

# 清空现有规则
iptables -F
iptables -X
iptables -Z

# 设置默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许本地回环
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许 SSH（修改为你的 SSH 端口）
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许 HTTP 和 HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# 允许 ping
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# 保存规则
service iptables save

echo "防火墙配置完成！"
```

### Web 服务器防火墙脚本

```bash
#!/bin/bash
# Web 服务器防火墙配置

# 清空规则
iptables -F
iptables -X
iptables -Z

# 设置默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许本地回环
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许 SSH（只允许特定 IP）
iptables -A INPUT -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT

# 允许 HTTP 和 HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 防止 SYN 洪水攻击
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# 防止 ping 洪水攻击
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# 防止端口扫描
iptables -A INPUT -m state --state INVALID -j DROP

# 记录被拒绝的连接
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

# 保存规则
service iptables save

echo "Web 服务器防火墙配置完成！"
```

### 数据库服务器防火墙脚本

```bash
#!/bin/bash
# 数据库服务器防火墙配置

# 清空规则
iptables -F
iptables -X
iptables -Z

# 设置默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许本地回环
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许 SSH（只允许管理员 IP）
iptables -A INPUT -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT

# 允许 MySQL（只允许应用服务器）
iptables -A INPUT -p tcp -s 192.168.1.10 --dport 3306 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.11 --dport 3306 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.12 --dport 3306 -j ACCEPT

# 防止暴力破解
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 3 --name SSH -j DROP

# 保存规则
service iptables save

echo "数据库服务器防火墙配置完成！"
```

---

## 规则优化

### 1. 规则顺序优化

```bash
# 错误示例（效率低）
iptables -A INPUT -j DROP
iptables -A INPUT -p tcp --dport 80 -j ACCEPT  # 永远不会匹配

# 正确示例（效率高）
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -j DROP
```

### 2. 使用自定义链

```bash
# 创建自定义链
iptables -N WEB_RULES

# 添加规则到自定义链
iptables -A WEB_RULES -p tcp --dport 80 -j ACCEPT
iptables -A WEB_RULES -p tcp --dport 443 -j ACCEPT

# 跳转到自定义链
iptables -A INPUT -j WEB_RULES
```

### 3. 合并规则

```bash
# 低效写法
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# 高效写法
iptables -A INPUT -p tcp -m multiport --dports 80,443,8080 -j ACCEPT
```

---

## 调试技巧

### 1. 记录日志

```bash
# 记录所有被拒绝的连接
iptables -A INPUT -j LOG --log-prefix "INPUT DROP: " --log-level 4

# 查看日志
tail -f /var/log/messages
```

### 2. 测试规则

```bash
# 使用 -n 选项模拟（不实际执行）
iptables -A INPUT -p tcp --dport 80 -j ACCEPT -n

# 查看规则匹配情况
iptables -L -n -v
```

### 3. 临时规则

```bash
# 添加临时规则（重启后失效）
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# 测试通过后再保存
service iptables save
```

---

## 实战练习

### 练习 1：配置基础防火墙

```bash
# 1. 清空规则
iptables -F

# 2. 设置默认策略
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT

# 3. 允许本地回环
iptables -A INPUT -i lo -j ACCEPT

# 4. 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 5. 允许 SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 6. 允许 HTTP
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 7. 查看规则
iptables -L -n -v

# 8. 保存规则
service iptables save
```

### 练习 2：限制 SSH 访问

```bash
# 只允许特定 IP 访问 SSH
iptables -A INPUT -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP

# 测试
ssh root@服务器IP  # 从允许的 IP 测试
```

### 练习 3：防止暴力破解

```bash
# 限制 SSH 连接速率
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 3 --name SSH -j DROP

# 测试（快速连接 3 次以上会被拒绝）
```

---

## 常见问题

### 1. 规则不生效

**检查**：
```bash
# 查看规则顺序
iptables -L -n --line-numbers

# 检查默认策略
iptables -L -n | head -3
```

### 2. SSH 连接断开

**原因**：设置了 DROP 策略但没有允许 SSH

**解决**：
```bash
# 先允许 SSH
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# 再设置策略
iptables -P INPUT DROP
```

### 3. 无法访问外网

**原因**：OUTPUT 策略设置为 DROP

**解决**：
```bash
# 设置 OUTPUT 为 ACCEPT
iptables -P OUTPUT ACCEPT
```

---

## 小结

本节学习了：

✅ iptables 规则语法  
✅ 各种匹配条件（协议、端口、IP、状态等）  
✅ 常用规则示例  
✅ 防护规则（防攻击）  
✅ 完整防火墙脚本  
✅ 规则优化和调试技巧  

下一节将学习 iptables 的 NAT 和端口转发。

---

## 扩展阅读

- [iptables 规则详解](https://www.netfilter.org/documentation/HOWTO/packet-filtering-HOWTO.html)
- [iptables 最佳实践](https://wiki.archlinux.org/title/Iptables)
- [Linux 防火墙安全指南](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/securing_networks/using-and-configuring-firewalls_securing-networks)
