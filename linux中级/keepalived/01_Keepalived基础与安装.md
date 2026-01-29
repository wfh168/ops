# Keepalived 基础与安装

## 什么是 Keepalived？

**Keepalived** 是一个基于 VRRP 协议的高可用解决方案，主要用于实现服务器的故障转移和负载均衡。

### Keepalived 的作用

✅ **高可用（HA）**：主服务器故障时自动切换到备服务器  
✅ **虚拟 IP（VIP）**：提供统一的访问入口  
✅ **健康检查**：自动检测服务状态  
✅ **故障转移**：自动切换，无需人工干预  
✅ **负载均衡**：配合 LVS 实现负载均衡  

### 应用场景

1. **Web 服务器高可用**：Nginx、Apache 高可用
2. **数据库高可用**：MySQL、Redis 高可用
3. **负载均衡器高可用**：LVS、HAProxy 高可用
4. **网关高可用**：防火墙、路由器高可用
5. **任何需要高可用的服务**

---

## VRRP 协议

### 什么是 VRRP？

**VRRP（Virtual Router Redundancy Protocol，虚拟路由冗余协议）** 是一种容错协议，通过多台路由器组成一个虚拟路由器，提供高可用性。

### VRRP 工作原理

```
┌─────────────────────────────────────────┐
│          虚拟 IP（VIP）                  │
│          192.168.1.100                  │
└────────────┬────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐      ┌─────▼───┐
│ MASTER │      │ BACKUP  │
│ 主服务器│      │ 备服务器 │
│ 优先级100│     │ 优先级90 │
│192.168.1.10│  │192.168.1.11│
└────────┘      └─────────┘
```

### VRRP 角色

| 角色 | 说明 | 特点 |
|------|------|------|
| **MASTER** | 主服务器 | 拥有 VIP，提供服务 |
| **BACKUP** | 备服务器 | 待命状态，监控主服务器 |
| **FAULT** | 故障状态 | 服务器故障 |

### VRRP 通信

- **协议**：VRRP 使用 IP 协议号 112
- **组播地址**：224.0.0.18
- **通告间隔**：默认 1 秒
- **优先级**：0-255，数值越大优先级越高

---

## Keepalived 架构

### 核心组件

```
┌─────────────────────────────────────┐
│         Keepalived                  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  VRRP Stack                  │  │
│  │  (虚拟路由冗余协议栈)         │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Checkers                    │  │
│  │  (健康检查)                   │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  IPVS Wrapper                │  │
│  │  (LVS 负载均衡)               │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 工作流程

1. **启动**：Keepalived 启动，读取配置文件
2. **选举**：根据优先级选举 MASTER
3. **通告**：MASTER 定期发送 VRRP 通告
4. **监听**：BACKUP 监听 MASTER 的通告
5. **检查**：执行健康检查脚本
6. **故障转移**：MASTER 故障时，BACKUP 接管 VIP

---

## 安装 Keepalived

### CentOS/RHEL

```bash
# 安装 Keepalived
yum install -y keepalived

# 查看版本
keepalived -v

# 输出示例
Keepalived v1.3.5 (03/19,2017)
```

### Ubuntu/Debian

```bash
# 安装 Keepalived
apt update
apt install -y keepalived

# 查看版本
keepalived -v
```

### 编译安装（可选）

```bash
# 安装依赖
yum install -y gcc openssl-devel libnl3-devel

# 下载源码
wget https://www.keepalived.org/software/keepalived-2.2.7.tar.gz
tar -zxvf keepalived-2.2.7.tar.gz
cd keepalived-2.2.7

# 编译安装
./configure --prefix=/usr/local/keepalived
make && make install

# 配置系统服务
cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
cp /usr/local/keepalived/sbin/keepalived /usr/sbin/
```

---

## 配置文件

### 主配置文件：/etc/keepalived/keepalived.conf

Keepalived 的主配置文件，包含全局配置、VRRP 配置和健康检查配置。

**基本结构**：

```
global_defs {
    # 全局配置
}

vrrp_script {
    # 健康检查脚本
}

vrrp_instance {
    # VRRP 实例配置
}
```

---

## 基本配置示例

### MASTER 配置

```bash
# /etc/keepalived/keepalived.conf (主服务器)

global_defs {
    router_id LVS_MASTER    # 路由器标识
}

vrrp_instance VI_1 {
    state MASTER            # 角色（MASTER/BACKUP）
    interface eth0          # 网络接口
    virtual_router_id 51    # 虚拟路由器 ID（主备必须相同）
    priority 100            # 优先级（主服务器高于备服务器）
    advert_int 1            # 通告间隔（秒）
    
    authentication {
        auth_type PASS      # 认证类型
        auth_pass 1111      # 认证密码（主备必须相同）
    }
    
    virtual_ipaddress {
        192.168.1.100       # 虚拟 IP（VIP）
    }
}
```

### BACKUP 配置

```bash
# /etc/keepalived/keepalived.conf (备服务器)

global_defs {
    router_id LVS_BACKUP    # 路由器标识
}

vrrp_instance VI_1 {
    state BACKUP            # 角色（BACKUP）
    interface eth0          # 网络接口
    virtual_router_id 51    # 虚拟路由器 ID（主备必须相同）
    priority 90             # 优先级（低于主服务器）
    advert_int 1            # 通告间隔（秒）
    
    authentication {
        auth_type PASS      # 认证类型
        auth_pass 1111      # 认证密码（主备必须相同）
    }
    
    virtual_ipaddress {
        192.168.1.100       # 虚拟 IP（VIP）
    }
}
```

---

## 启动和管理

### 启动 Keepalived

```bash
# 启动服务
systemctl start keepalived

# 设置开机自启
systemctl enable keepalived

# 查看状态
systemctl status keepalived

# 重启服务
systemctl restart keepalived

# 停止服务
systemctl stop keepalived
```

### 查看日志

```bash
# 查看系统日志
tail -f /var/log/messages

# 查看 Keepalived 日志
journalctl -u keepalived -f

# 查看最近的日志
journalctl -u keepalived -n 50
```

### 查看 VIP

```bash
# 查看 IP 地址
ip addr show eth0

# 输出示例（MASTER）
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.1.10/24 brd 192.168.1.255 scope global eth0
    inet 192.168.1.100/32 scope global eth0  # VIP
```

---

## 测试高可用

### 1. 查看当前状态

```bash
# 主服务器
ip addr show eth0 | grep 192.168.1.100
# 应该能看到 VIP

# 备服务器
ip addr show eth0 | grep 192.168.1.100
# 应该看不到 VIP
```

### 2. 测试故障转移

```bash
# 在主服务器上停止 Keepalived
systemctl stop keepalived

# 在备服务器上查看 VIP
ip addr show eth0 | grep 192.168.1.100
# 应该能看到 VIP（已接管）

# 查看日志
tail -f /var/log/messages
# 应该看到 "Entering MASTER STATE" 的日志
```

### 3. 测试故障恢复

```bash
# 在主服务器上启动 Keepalived
systemctl start keepalived

# 查看 VIP
ip addr show eth0 | grep 192.168.1.100
# VIP 应该回到主服务器

# 在备服务器上查看
ip addr show eth0 | grep 192.168.1.100
# VIP 应该消失
```

---

## 配置防火墙

### firewalld

```bash
# 允许 VRRP 协议
firewall-cmd --permanent --add-rich-rule='rule protocol value="vrrp" accept'

# 允许组播地址
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" destination address="224.0.0.18" accept'

# 重载防火墙
firewall-cmd --reload
```

### iptables

```bash
# 允许 VRRP 协议
iptables -A INPUT -p vrrp -j ACCEPT

# 允许组播地址
iptables -A INPUT -d 224.0.0.18 -j ACCEPT

# 保存规则
service iptables save
```

---

## 实战练习

### 练习 1：搭建基本高可用环境

**环境准备**：
- 主服务器：192.168.1.10
- 备服务器：192.168.1.11
- 虚拟 IP：192.168.1.100

**主服务器配置**：

```bash
# 1. 安装 Keepalived
yum install -y keepalived

# 2. 配置 Keepalived
cat > /etc/keepalived/keepalived.conf << 'EOF'
global_defs {
    router_id LVS_MASTER
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    
    virtual_ipaddress {
        192.168.1.100
    }
}
EOF

# 3. 启动服务
systemctl start keepalived
systemctl enable keepalived

# 4. 查看 VIP
ip addr show eth0 | grep 192.168.1.100
```

**备服务器配置**：

```bash
# 1. 安装 Keepalived
yum install -y keepalived

# 2. 配置 Keepalived
cat > /etc/keepalived/keepalived.conf << 'EOF'
global_defs {
    router_id LVS_BACKUP
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    advert_int 1
    
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    
    virtual_ipaddress {
        192.168.1.100
    }
}
EOF

# 3. 启动服务
systemctl start keepalived
systemctl enable keepalived

# 4. 查看状态（应该没有 VIP）
ip addr show eth0 | grep 192.168.1.100
```

### 练习 2：测试故障转移

```bash
# 1. 在客户端持续 ping VIP
ping 192.168.1.100

# 2. 在主服务器上停止 Keepalived
systemctl stop keepalived

# 3. 观察 ping 结果（应该有短暂中断，然后恢复）

# 4. 在备服务器上查看 VIP
ip addr show eth0 | grep 192.168.1.100

# 5. 在主服务器上启动 Keepalived
systemctl start keepalived

# 6. 观察 VIP 是否回到主服务器
```

---

## 常见问题

### 1. VIP 没有绑定

**原因**：
- 配置文件错误
- 网络接口名称错误
- 防火墙阻止 VRRP

**解决**：
```bash
# 检查配置文件
keepalived -t -f /etc/keepalived/keepalived.conf

# 查看日志
tail -f /var/log/messages

# 检查网络接口
ip addr show

# 检查防火墙
firewall-cmd --list-all
```

### 2. 主备都有 VIP（脑裂）

**原因**：
- 主备之间网络不通
- 防火墙阻止 VRRP 通信
- virtual_router_id 不一致

**解决**：
```bash
# 测试网络连通性
ping 192.168.1.11

# 检查 VRRP 通信
tcpdump -i eth0 vrrp

# 检查配置
grep virtual_router_id /etc/keepalived/keepalived.conf
```

### 3. 故障转移不生效

**原因**：
- 优先级配置错误
- 认证密码不一致
- 服务未启动

**解决**：
```bash
# 检查优先级
grep priority /etc/keepalived/keepalived.conf

# 检查认证密码
grep auth_pass /etc/keepalived/keepalived.conf

# 检查服务状态
systemctl status keepalived
```

---

## 小结

本节学习了：

✅ Keepalived 的概念和作用  
✅ VRRP 协议原理  
✅ Keepalived 架构  
✅ 安装和基本配置  
✅ 启动和管理  
✅ 测试高可用  
✅ 常见问题排查  

下一节将学习 Keepalived 的高级配置和健康检查。

---

## 扩展阅读

- [Keepalived 官方文档](https://www.keepalived.org/documentation.html)
- [VRRP 协议详解](https://tools.ietf.org/html/rfc3768)
- [Linux 高可用架构](https://www.linux-ha.org/)
