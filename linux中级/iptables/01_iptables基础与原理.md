# iptables 基础与原理

## 什么是 iptables？

**iptables** 是 Linux 系统中的防火墙工具，用于配置 Linux 内核的 netfilter 防火墙规则，控制进出服务器的网络流量。

### iptables 的作用

✅ **包过滤**：根据规则允许或拒绝数据包  
✅ **网络地址转换（NAT）**：实现内网访问外网  
✅ **端口转发**：将流量转发到其他端口或服务器  
✅ **流量控制**：限制流量速率  
✅ **安全防护**：防止恶意攻击  

### 应用场景

1. **服务器安全**：只开放必要的端口
2. **网络隔离**：限制不同网段的访问
3. **负载均衡**：配合其他工具实现负载均衡
4. **端口映射**：内网服务映射到外网
5. **防止攻击**：防止 DDoS、端口扫描等

---

## iptables vs firewalld

### 版本对比

| 特性 | iptables | firewalld |
|------|----------|-----------|
| 系统 | CentOS 6 及更早 | CentOS 7/8 |
| 配置方式 | 命令行规则 | 区域和服务 |
| 动态更新 | 需要重启 | 支持动态更新 |
| 易用性 | 较复杂 | 较简单 |
| 灵活性 | 非常灵活 | 相对简单 |

### 选择建议

- **CentOS 6**：使用 iptables
- **CentOS 7/8**：可以使用 firewalld 或 iptables
- **需要精细控制**：使用 iptables
- **快速配置**：使用 firewalld

**本教程重点讲解 iptables**，因为它更底层、更灵活。

---

## netfilter 架构

### 什么是 netfilter？

**netfilter** 是 Linux 内核中的网络数据包处理框架，iptables 是配置 netfilter 的用户空间工具。

```
┌─────────────────────────────────────────┐
│          用户空间（User Space）          │
│                                         │
│            iptables 命令                │
│                 ↓                       │
└─────────────────┼───────────────────────┘
                  │
┌─────────────────┼───────────────────────┐
│          内核空间（Kernel Space）        │
│                 ↓                       │
│            netfilter                    │
│         (数据包过滤框架)                 │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  表（Tables）                     │  │
│  │  ├─ filter（过滤）                │  │
│  │  ├─ nat（地址转换）               │  │
│  │  ├─ mangle（修改）                │  │
│  │  └─ raw（原始）                   │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  链（Chains）                     │  │
│  │  ├─ INPUT（入站）                 │  │
│  │  ├─ OUTPUT（出站）                │  │
│  │  ├─ FORWARD（转发）               │  │
│  │  ├─ PREROUTING（路由前）          │  │
│  │  └─ POSTROUTING（路由后）         │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## 四表五链

### 四表（Tables）

iptables 有 4 个表，每个表有不同的功能：

| 表名 | 功能 | 常用场景 |
|------|------|----------|
| **filter** | 数据包过滤 | 允许/拒绝访问（最常用） |
| **nat** | 网络地址转换 | 端口转发、IP 伪装 |
| **mangle** | 修改数据包 | 修改 TTL、TOS 等 |
| **raw** | 状态跟踪 | 连接跟踪（较少使用） |

**默认表**：如果不指定表，默认使用 **filter** 表。

### 五链（Chains）

链是规则的集合，数据包会按顺序匹配链中的规则：

| 链名 | 作用 | 数据包方向 |
|------|------|-----------|
| **INPUT** | 处理入站数据包 | 外部 → 本机 |
| **OUTPUT** | 处理出站数据包 | 本机 → 外部 |
| **FORWARD** | 处理转发数据包 | 外部 → 本机 → 外部 |
| **PREROUTING** | 路由前处理 | 数据包到达时 |
| **POSTROUTING** | 路由后处理 | 数据包离开时 |

### 表和链的关系

不同的表包含不同的链：

```
filter 表：
  ├─ INPUT
  ├─ FORWARD
  └─ OUTPUT

nat 表：
  ├─ PREROUTING
  ├─ OUTPUT
  └─ POSTROUTING

mangle 表：
  ├─ PREROUTING
  ├─ INPUT
  ├─ FORWARD
  ├─ OUTPUT
  └─ POSTROUTING

raw 表：
  ├─ PREROUTING
  └─ OUTPUT
```

---

## 数据包流向

### 入站数据包（访问本机服务）

```
外部 → PREROUTING → INPUT → 本机进程
```

**示例**：外部访问本机的 Web 服务（80 端口）

### 出站数据包（本机访问外部）

```
本机进程 → OUTPUT → POSTROUTING → 外部
```

**示例**：本机访问外部网站

### 转发数据包（本机作为路由器）

```
外部 → PREROUTING → FORWARD → POSTROUTING → 外部
```

**示例**：内网通过本机访问外网（NAT）

### 完整流程图

```
                    ┌──────────────┐
                    │  网络接口    │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  PREROUTING  │ (nat, mangle, raw)
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  路由判断    │
                    └──┬────────┬──┘
                       │        │
            本机目标   │        │  转发目标
                       │        │
                ┌──────▼──┐  ┌──▼────────┐
                │  INPUT  │  │  FORWARD  │ (filter, mangle)
                └────┬────┘  └────┬──────┘
                     │            │
              ┌──────▼──────┐     │
              │  本机进程   │     │
              └──────┬──────┘     │
                     │            │
                ┌────▼────┐       │
                │ OUTPUT  │       │ (filter, nat, mangle, raw)
                └────┬────┘       │
                     │            │
                     └────┬───────┘
                          │
                   ┌──────▼───────┐
                   │ POSTROUTING  │ (nat, mangle)
                   └──────┬───────┘
                          │
                   ┌──────▼───────┐
                   │  网络接口    │
                   └──────────────┘
```

---

## 规则匹配原则

### 1. 自上而下匹配

规则按照添加顺序从上到下匹配，**第一条匹配的规则生效**。

```bash
# 规则 1：允许 192.168.1.100
iptables -A INPUT -s 192.168.1.100 -j ACCEPT

# 规则 2：拒绝所有
iptables -A INPUT -j DROP

# 结果：192.168.1.100 可以访问，其他 IP 被拒绝
```

### 2. 匹配即停止

一旦匹配到规则，就不再继续匹配后面的规则。

### 3. 默认策略

如果所有规则都不匹配，则执行默认策略（ACCEPT 或 DROP）。

```bash
# 查看默认策略
iptables -L -n | head -3

# 输出示例
Chain INPUT (policy ACCEPT)
Chain FORWARD (policy ACCEPT)
Chain OUTPUT (policy ACCEPT)
```

---

## 规则动作（Target）

### 常用动作

| 动作 | 说明 | 使用场景 |
|------|------|----------|
| **ACCEPT** | 允许数据包通过 | 允许访问 |
| **DROP** | 丢弃数据包（不回应） | 拒绝访问（隐蔽） |
| **REJECT** | 拒绝数据包（回应错误） | 拒绝访问（明确） |
| **LOG** | 记录日志 | 调试和监控 |
| **SNAT** | 源地址转换 | 内网访问外网 |
| **DNAT** | 目标地址转换 | 端口转发 |
| **MASQUERADE** | 动态源地址转换 | 动态 IP 的 NAT |
| **REDIRECT** | 端口重定向 | 透明代理 |

### DROP vs REJECT

```bash
# DROP：丢弃数据包，不回应（客户端会超时）
iptables -A INPUT -p tcp --dport 22 -j DROP

# REJECT：拒绝数据包，回应错误（客户端立即收到拒绝）
iptables -A INPUT -p tcp --dport 22 -j REJECT
```

**建议**：
- 对外服务使用 **DROP**（更安全，不暴露信息）
- 内部服务使用 **REJECT**（更友好，快速反馈）

---

## 安装 iptables

### CentOS 7/8（默认使用 firewalld）

```bash
# 停止并禁用 firewalld
systemctl stop firewalld
systemctl disable firewalld

# 安装 iptables 服务
yum install -y iptables-services

# 启动 iptables
systemctl start iptables
systemctl enable iptables

# 查看状态
systemctl status iptables
```

### CentOS 6

```bash
# 启动 iptables
service iptables start
chkconfig iptables on

# 查看状态
service iptables status
```

### Ubuntu/Debian

```bash
# 安装 iptables（通常已预装）
apt update
apt install -y iptables

# 安装持久化工具
apt install -y iptables-persistent

# 保存规则
netfilter-persistent save
```

---

## 基本命令

### 查看规则

```bash
# 查看所有规则
iptables -L

# 查看规则（显示行号）
iptables -L -n --line-numbers

# 查看规则（详细信息）
iptables -L -n -v

# 查看 nat 表规则
iptables -t nat -L -n

# 查看规则（精简格式）
iptables -S
```

### 清空规则

```bash
# 清空所有规则
iptables -F

# 清空指定链的规则
iptables -F INPUT

# 清空 nat 表规则
iptables -t nat -F

# 删除自定义链
iptables -X

# 重置计数器
iptables -Z
```

### 设置默认策略

```bash
# 设置 INPUT 链默认策略为 DROP
iptables -P INPUT DROP

# 设置 FORWARD 链默认策略为 DROP
iptables -P FORWARD DROP

# 设置 OUTPUT 链默认策略为 ACCEPT
iptables -P OUTPUT ACCEPT
```

---

## 规则操作

### 添加规则

```bash
# -A：在链的末尾添加规则
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# -I：在链的开头插入规则
iptables -I INPUT -p tcp --dport 80 -j ACCEPT

# -I：在指定位置插入规则
iptables -I INPUT 3 -p tcp --dport 80 -j ACCEPT
```

### 删除规则

```bash
# 按行号删除
iptables -D INPUT 3

# 按规则内容删除
iptables -D INPUT -p tcp --dport 80 -j ACCEPT

# 删除所有规则
iptables -F
```

### 替换规则

```bash
# 替换指定行的规则
iptables -R INPUT 3 -p tcp --dport 8080 -j ACCEPT
```

---

## 保存和恢复规则

### CentOS 7/8

```bash
# 保存规则
service iptables save

# 或
iptables-save > /etc/sysconfig/iptables

# 恢复规则
iptables-restore < /etc/sysconfig/iptables
```

### CentOS 6

```bash
# 保存规则
service iptables save

# 重启后自动加载
service iptables restart
```

### Ubuntu/Debian

```bash
# 保存规则
iptables-save > /etc/iptables/rules.v4

# 或使用 iptables-persistent
netfilter-persistent save

# 恢复规则
iptables-restore < /etc/iptables/rules.v4
```

---

## 实战练习

### 练习 1：查看当前规则

```bash
# 查看所有规则
iptables -L -n -v

# 查看 INPUT 链规则
iptables -L INPUT -n -v

# 查看规则（带行号）
iptables -L -n --line-numbers
```

### 练习 2：清空规则

```bash
# 清空所有规则
iptables -F

# 设置默认策略为 ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 验证
iptables -L -n
```

### 练习 3：添加简单规则

```bash
# 允许本地回环
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许 SSH（22 端口）
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许 HTTP（80 端口）
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 拒绝其他所有入站流量
iptables -A INPUT -j DROP

# 查看规则
iptables -L INPUT -n -v
```

### 练习 4：保存规则

```bash
# CentOS
service iptables save

# Ubuntu
iptables-save > /etc/iptables/rules.v4

# 验证
cat /etc/sysconfig/iptables  # CentOS
cat /etc/iptables/rules.v4   # Ubuntu
```

---

## 常见问题

### 1. 规则不生效

**原因**：
- firewalld 和 iptables 冲突
- 规则顺序错误
- 规则未保存

**解决**：
```bash
# 停止 firewalld
systemctl stop firewalld
systemctl disable firewalld

# 检查规则顺序
iptables -L -n --line-numbers

# 保存规则
service iptables save
```

### 2. SSH 连接断开

**原因**：设置了 DROP 策略但没有允许 SSH

**解决**：
```bash
# 先允许 SSH，再设置 DROP 策略
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP
```

### 3. 规则重启后丢失

**原因**：规则未保存

**解决**：
```bash
# 保存规则
service iptables save

# 设置开机自启
systemctl enable iptables
```

---

## 小结

本节学习了：

✅ iptables 的概念和作用  
✅ netfilter 架构  
✅ 四表五链的概念  
✅ 数据包流向  
✅ 规则匹配原则  
✅ 基本命令和操作  
✅ 规则的保存和恢复  

下一节将学习 iptables 的规则编写和实战应用。

---

## 扩展阅读

- [iptables 官方文档](https://netfilter.org/documentation/)
- [netfilter 架构详解](https://www.netfilter.org/documentation/HOWTO/netfilter-hacking-HOWTO.html)
- [iptables 教程](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html)
