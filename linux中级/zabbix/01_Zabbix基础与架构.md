# Zabbix 基础与架构

## 什么是 Zabbix？

**Zabbix** 是一个企业级的开源监控解决方案，用于监控网络、服务器、应用程序和服务的性能和可用性。

### Zabbix 的特点

✅ **开源免费**：完全开源，无需授权费用  
✅ **功能强大**：支持多种监控方式  
✅ **分布式监控**：支持大规模分布式监控  
✅ **灵活告警**：多种告警方式（邮件、短信、钉钉等）  
✅ **可视化**：丰富的图表和仪表盘  
✅ **自动发现**：自动发现网络设备和服务  
✅ **API 接口**：支持二次开发  

### 应用场景

1. **服务器监控**：CPU、内存、磁盘、网络等
2. **应用监控**：Web 服务、数据库、中间件等
3. **网络监控**：交换机、路由器、防火墙等
4. **业务监控**：自定义业务指标
5. **日志监控**：日志文件监控和分析

---

## Zabbix 架构

### 核心组件

```
┌─────────────────────────────────────────────┐
│              Zabbix 架构                     │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │      Zabbix Web (前端界面)            │  │
│  │      - 配置管理                       │  │
│  │      - 数据展示                       │  │
│  │      - 告警管理                       │  │
│  └────────────┬─────────────────────────┘  │
│               │                             │
│  ┌────────────▼─────────────────────────┐  │
│  │      Zabbix Server (核心服务)         │  │
│  │      - 数据采集                       │  │
│  │      - 数据处理                       │  │
│  │      - 告警触发                       │  │
│  └────────────┬─────────────────────────┘  │
│               │                             │
│  ┌────────────▼─────────────────────────┐  │
│  │      Database (数据库)                │  │
│  │      - MySQL / PostgreSQL             │  │
│  │      - 存储配置和监控数据              │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │      Zabbix Agent (客户端)            │  │
│  │      - 安装在被监控主机                │  │
│  │      - 采集本地数据                    │  │
│  │      - 主动/被动模式                   │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │      Zabbix Proxy (代理服务器)        │  │
│  │      - 分布式监控                      │  │
│  │      - 减轻 Server 压力                │  │
│  │      - 跨网段监控                      │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 组件说明

| 组件 | 作用 | 必需 |
|------|------|------|
| **Zabbix Server** | 核心服务，数据处理和告警 | ✅ 必需 |
| **Database** | 存储配置和监控数据 | ✅ 必需 |
| **Zabbix Web** | Web 界面，配置和展示 | ✅ 必需 |
| **Zabbix Agent** | 客户端，采集数据 | ⭐ 推荐 |
| **Zabbix Proxy** | 代理服务器，分布式监控 | ⚪ 可选 |

---

## 监控方式

### 1. Zabbix Agent 监控

**主动模式（Active）**：
- Agent 主动向 Server 请求监控项
- 适合大规模监控
- 减轻 Server 压力

**被动模式（Passive）**：
- Server 主动向 Agent 请求数据
- 配置简单
- 适合小规模监控

### 2. SNMP 监控

监控网络设备（交换机、路由器、打印机等）。

### 3. IPMI 监控

监控服务器硬件（温度、风扇、电源等）。

### 4. JMX 监控

监控 Java 应用程序。

### 5. 简单检查

- **ICMP Ping**：检查主机是否在线
- **TCP/UDP 端口**：检查端口是否开放
- **HTTP/HTTPS**：检查 Web 服务

### 6. 自定义脚本

通过自定义脚本采集数据。

---

## 版本选择

### Zabbix 版本

| 版本 | 发布时间 | 支持周期 | 推荐 |
|------|----------|----------|------|
| Zabbix 4.0 LTS | 2018 | 5 年 | ⚪ 旧版本 |
| Zabbix 5.0 LTS | 2020 | 5 年 | ✅ 推荐 |
| Zabbix 6.0 LTS | 2022 | 5 年 | ⭐ 最新 LTS |
| Zabbix 7.0 | 2024 | 1.5 年 | ⚠️ 非 LTS |

**建议**：生产环境使用 LTS 版本（5.0 或 6.0）。

---

## 系统要求

### 硬件要求

**小规模（< 100 台主机）**：
- CPU：2 核
- 内存：4GB
- 磁盘：50GB

**中等规模（100-500 台主机）**：
- CPU：4 核
- 内存：8GB
- 磁盘：100GB

**大规模（> 500 台主机）**：
- CPU：8 核以上
- 内存：16GB 以上
- 磁盘：200GB 以上（SSD 推荐）

### 软件要求

**操作系统**：
- CentOS 7/8
- Ubuntu 18.04/20.04
- Debian 9/10

**数据库**：
- MySQL 5.7/8.0
- MariaDB 10.3+
- PostgreSQL 12+

**Web 服务器**：
- Apache 2.4+
- Nginx 1.18+

**PHP**：
- PHP 7.2+（推荐 7.4）

---

## 安装准备

### 1. 系统初始化

```bash
# 关闭 SELinux
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# 关闭防火墙（或配置规则）
systemctl stop firewalld
systemctl disable firewalld

# 更新系统
yum update -y

# 安装基础工具
yum install -y wget vim net-tools
```

### 2. 配置主机名和 hosts

```bash
# 设置主机名
hostnamectl set-hostname zabbix-server

# 配置 hosts
cat >> /etc/hosts << EOF
192.168.1.10 zabbix-server
192.168.1.20 zabbix-agent1
192.168.1.21 zabbix-agent2
EOF
```

### 3. 时间同步

```bash
# 安装 NTP
yum install -y chrony

# 启动服务
systemctl start chronyd
systemctl enable chronyd

# 查看时间同步状态
chronyc sources -v
```

---

## 安装 Zabbix Server

### 方法 1：使用官方仓库（推荐）

#### CentOS 7

```bash
# 1. 安装 Zabbix 仓库
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm

# 2. 清理缓存
yum clean all

# 3. 安装 Zabbix Server 和 Agent
yum install -y zabbix-server-mysql zabbix-agent

# 4. 安装 Zabbix Web 前端
yum install -y centos-release-scl
yum install -y zabbix-web-mysql-scl zabbix-apache-conf-scl
```

#### CentOS 8

```bash
# 1. 安装 Zabbix 仓库
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm

# 2. 清理缓存
dnf clean all

# 3. 安装 Zabbix Server 和 Agent
dnf install -y zabbix-server-mysql zabbix-agent

# 4. 安装 Zabbix Web 前端
dnf install -y zabbix-web-mysql zabbix-apache-conf
```

---

## 安装和配置数据库

### 安装 MySQL

```bash
# CentOS 7
yum install -y mariadb-server mariadb

# CentOS 8
dnf install -y mysql-server

# 启动 MySQL
systemctl start mysqld
systemctl enable mysqld
```

### 初始化 MySQL

```bash
# 安全初始化
mysql_secure_installation

# 设置 root 密码
# 删除匿名用户
# 禁止 root 远程登录
# 删除测试数据库
```

### 创建 Zabbix 数据库

```bash
# 登录 MySQL
mysql -u root -p

# 创建数据库
CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;

# 创建用户并授权
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix_password';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;

# 退出
EXIT;
```

### 导入初始数据

```bash
# 导入数据库结构和数据
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix

# 输入密码：zabbix_password
```

---

## 配置 Zabbix Server

### 编辑配置文件

```bash
# 编辑 Zabbix Server 配置
vim /etc/zabbix/zabbix_server.conf

# 修改以下参数
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix_password

# 其他重要参数
ListenPort=10051           # 监听端口
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=10             # 日志文件大小（MB）
Timeout=30                 # 超时时间（秒）
```

### 启动 Zabbix Server

```bash
# 启动服务
systemctl start zabbix-server zabbix-agent

# 设置开机自启
systemctl enable zabbix-server zabbix-agent

# 查看状态
systemctl status zabbix-server

# 查看日志
tail -f /var/log/zabbix/zabbix_server.log
```

---

## 配置 Zabbix Web

### 配置 PHP

```bash
# CentOS 7（使用 SCL）
vim /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf

# CentOS 8
vim /etc/php-fpm.d/zabbix.conf

# 修改时区
php_value[date.timezone] = Asia/Shanghai
```

### 启动 Web 服务

```bash
# CentOS 7
systemctl start rh-php72-php-fpm httpd
systemctl enable rh-php72-php-fpm httpd

# CentOS 8
systemctl start php-fpm httpd
systemctl enable php-fpm httpd
```

### 配置防火墙

```bash
# 开放端口
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=10051/tcp
firewall-cmd --reload
```

---

## Web 界面初始化

### 访问 Web 界面

```
http://服务器IP/zabbix
```

### 安装向导

**步骤 1：欢迎页面**
- 点击 "Next step"

**步骤 2：检查先决条件**
- 确保所有项目都是 OK
- 如果有错误，根据提示修复

**步骤 3：配置数据库连接**
- Database type: MySQL
- Database host: localhost
- Database port: 0（默认）
- Database name: zabbix
- User: zabbix
- Password: zabbix_password

**步骤 4：Zabbix Server 详情**
- Host: localhost
- Port: 10051
- Name: Zabbix Server（可自定义）

**步骤 5：预安装摘要**
- 检查配置信息
- 点击 "Next step"

**步骤 6：安装完成**
- 点击 "Finish"

### 登录 Zabbix

**默认账号**：
- 用户名：Admin
- 密码：zabbix

**首次登录后建议**：
1. 修改 Admin 密码
2. 修改界面语言为中文
3. 配置邮件告警

---

## 验证安装

### 检查服务状态

```bash
# 检查 Zabbix Server
systemctl status zabbix-server

# 检查 Zabbix Agent
systemctl status zabbix-agent

# 检查 Web 服务
systemctl status httpd

# 检查数据库
systemctl status mysqld
```

### 检查端口

```bash
# 检查 Zabbix Server 端口
netstat -tunlp | grep 10051

# 检查 Zabbix Agent 端口
netstat -tunlp | grep 10050

# 检查 Web 端口
netstat -tunlp | grep 80
```

### 检查日志

```bash
# Zabbix Server 日志
tail -f /var/log/zabbix/zabbix_server.log

# Zabbix Agent 日志
tail -f /var/log/zabbix/zabbix_agentd.log

# Apache 日志
tail -f /var/log/httpd/error_log
```

---

## 常见问题

### 1. 数据库连接失败

**现象**：Web 界面提示数据库连接失败

**解决**：
```bash
# 检查数据库服务
systemctl status mysqld

# 检查数据库连接
mysql -uzabbix -p -e "SELECT 1"

# 检查配置文件
grep ^DB /etc/zabbix/zabbix_server.conf
```

### 2. Zabbix Server 启动失败

**现象**：`systemctl start zabbix-server` 失败

**解决**：
```bash
# 查看日志
tail -100 /var/log/zabbix/zabbix_server.log

# 常见原因：
# - 数据库连接失败
# - 配置文件错误
# - 端口被占用
```

### 3. Web 界面无法访问

**现象**：浏览器无法打开 Zabbix 页面

**解决**：
```bash
# 检查 httpd 服务
systemctl status httpd

# 检查防火墙
firewall-cmd --list-ports

# 检查 SELinux
getenforce
```

---

## 小结

本节学习了：

✅ Zabbix 的概念和特点  
✅ Zabbix 架构和组件  
✅ 监控方式和版本选择  
✅ 系统要求和安装准备  
✅ Zabbix Server 的安装  
✅ 数据库的配置  
✅ Web 界面的初始化  
✅ 常见问题排查  

下一节将学习 Zabbix 的监控配置和使用。

---

## 扩展阅读

- [Zabbix 官方文档](https://www.zabbix.com/documentation/current/)
- [Zabbix 中文社区](https://www.zabbix.org.cn/)
- [Zabbix 最佳实践](https://www.zabbix.com/documentation/current/manual/installation/requirements)
