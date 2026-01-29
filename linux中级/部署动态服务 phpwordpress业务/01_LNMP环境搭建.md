# LNMP 环境搭建

## 什么是 LNMP？

**LNMP** 是 Linux + Nginx + MySQL + PHP 的缩写，是目前最流行的 Web 服务器架构之一。

### LNMP 架构

```
┌─────────────────────────────────────┐
│          客户端（浏览器）            │
└────────────┬────────────────────────┘
             │ HTTP 请求
             ▼
┌─────────────────────────────────────┐
│          Nginx (Web 服务器)          │
│          - 处理静态文件              │
│          - 反向代理                  │
└────────────┬────────────────────────┘
             │ FastCGI
             ▼
┌─────────────────────────────────────┐
│          PHP-FPM (PHP 解释器)        │
│          - 处理动态请求              │
│          - 执行 PHP 代码             │
└────────────┬────────────────────────┘
             │ SQL 查询
             ▼
┌─────────────────────────────────────┐
│          MySQL (数据库)              │
│          - 存储数据                  │
│          - 数据查询                  │
└─────────────────────────────────────┘
```

### LNMP vs LAMP

| 特性 | LNMP | LAMP |
|------|------|------|
| Web 服务器 | Nginx | Apache |
| 性能 | 高并发性能好 | 中等 |
| 内存占用 | 低 | 较高 |
| 配置 | 相对简单 | 功能丰富 |
| 静态文件 | 非常快 | 较快 |
| 动态内容 | FastCGI | mod_php |

---

## 系统准备

### 1. 系统要求

- **操作系统**：CentOS 7/8 或 Ubuntu 18.04/20.04
- **内存**：至少 1GB（推荐 2GB）
- **磁盘**：至少 20GB

### 2. 系统初始化

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

---

## 安装 Nginx

### CentOS 7/8

```bash
# 1. 添加 Nginx 官方仓库
cat > /etc/yum.repos.d/nginx.repo << 'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

# 2. 安装 Nginx
yum install -y nginx

# 3. 启动 Nginx
systemctl start nginx
systemctl enable nginx

# 4. 查看版本
nginx -v

# 5. 测试访问
curl http://localhost
```

### Ubuntu/Debian

```bash
# 1. 安装 Nginx
apt update
apt install -y nginx

# 2. 启动服务
systemctl start nginx
systemctl enable nginx

# 3. 查看版本
nginx -v
```

---

## 安装 MySQL

### CentOS 7

```bash
# 1. 安装 MySQL 仓库
wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
rpm -ivh mysql80-community-release-el7-3.noarch.rpm

# 2. 安装 MySQL
yum install -y mysql-server

# 3. 启动 MySQL
systemctl start mysqld
systemctl enable mysqld

# 4. 获取临时密码
grep 'temporary password' /var/log/mysqld.log

# 5. 安全初始化
mysql_secure_installation

# 修改 root 密码
# 删除匿名用户
# 禁止 root 远程登录
# 删除测试数据库
```

### CentOS 8

```bash
# 1. 安装 MySQL
dnf install -y @mysql

# 2. 启动服务
systemctl start mysqld
systemctl enable mysqld

# 3. 安全初始化
mysql_secure_installation
```

### 使用 MariaDB（替代方案）

```bash
# CentOS 7/8
yum install -y mariadb-server mariadb

# 启动服务
systemctl start mariadb
systemctl enable mariadb

# 安全初始化
mysql_secure_installation
```

---

## 安装 PHP

### CentOS 7

```bash
# 1. 安装 EPEL 和 Remi 仓库
yum install -y epel-release
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm

# 2. 启用 PHP 7.4 仓库
yum install -y yum-utils
yum-config-manager --enable remi-php74

# 3. 安装 PHP 和常用扩展
yum install -y php php-fpm php-mysql php-gd php-mbstring php-xml php-json php-curl

# 4. 查看 PHP 版本
php -v

# 5. 启动 PHP-FPM
systemctl start php-fpm
systemctl enable php-fpm
```

### CentOS 8

```bash
# 1. 安装 PHP 7.4
dnf install -y php php-fpm php-mysqlnd php-gd php-mbstring php-xml php-json php-curl

# 2. 启动服务
systemctl start php-fpm
systemctl enable php-fpm
```

### Ubuntu/Debian

```bash
# 1. 添加 PHP 仓库
apt install -y software-properties-common
add-apt-repository ppa:ondrej/php

# 2. 安装 PHP
apt update
apt install -y php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-mbstring php7.4-xml php7.4-curl

# 3. 启动服务
systemctl start php7.4-fpm
systemctl enable php7.4-fpm
```

---

## 配置 PHP-FPM

### 编辑 PHP-FPM 配置

```bash
# 编辑 www.conf
vim /etc/php-fpm.d/www.conf

# 修改以下参数
user = nginx                    # 运行用户
group = nginx                   # 运行组
listen = /var/run/php-fpm.sock  # 监听 socket（或 127.0.0.1:9000）
listen.owner = nginx
listen.group = nginx
listen.mode = 0660

# 进程管理
pm = dynamic                    # 动态进程管理
pm.max_children = 50            # 最大子进程数
pm.start_servers = 5            # 启动时进程数
pm.min_spare_servers = 5        # 最小空闲进程数
pm.max_spare_servers = 35       # 最大空闲进程数
```

### 编辑 PHP 配置

```bash
# 编辑 php.ini
vim /etc/php.ini

# 修改以下参数
upload_max_filesize = 64M       # 上传文件大小限制
post_max_size = 64M             # POST 数据大小限制
max_execution_time = 300        # 脚本执行时间限制
memory_limit = 256M             # 内存限制
date.timezone = Asia/Shanghai   # 时区设置
```

### 重启 PHP-FPM

```bash
systemctl restart php-fpm

# 查看状态
systemctl status php-fpm

# 查看进程
ps aux | grep php-fpm
```

---

## 配置 Nginx 支持 PHP

### 创建站点配置

```bash
# 创建配置文件
vim /etc/nginx/conf.d/default.conf
```

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    # 日志配置
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # PHP 处理
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm.sock;  # 或 127.0.0.1:9000
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
    }

    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
```

### 测试配置

```bash
# 测试 Nginx 配置
nginx -t

# 重启 Nginx
systemctl restart nginx
```

---

## 测试 LNMP 环境

### 创建 PHP 测试文件

```bash
# 创建 phpinfo 文件
cat > /usr/share/nginx/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

# 设置权限
chown nginx:nginx /usr/share/nginx/html/info.php
```

### 测试 PHP

```bash
# 浏览器访问
http://服务器IP/info.php

# 或使用 curl
curl http://localhost/info.php
```

### 测试 MySQL 连接

```bash
# 创建测试文件
cat > /usr/share/nginx/html/mysql_test.php << 'EOF'
<?php
$servername = "localhost";
$username = "root";
$password = "your_password";

// 创建连接
$conn = new mysqli($servername, $username, $password);

// 检测连接
if ($conn->connect_error) {
    die("连接失败: " . $conn->connect_error);
}
echo "MySQL 连接成功";
?>
EOF
```

---

## 配置防火墙

### firewalld

```bash
# 开放 HTTP 端口
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# 查看规则
firewall-cmd --list-all
```

### iptables

```bash
# 开放 80 和 443 端口
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 保存规则
service iptables save
```

---

## 优化配置

### Nginx 优化

```bash
vim /etc/nginx/nginx.conf

user nginx;
worker_processes auto;          # 自动设置为 CPU 核心数
worker_rlimit_nofile 65535;     # 文件描述符限制

events {
    worker_connections 10240;   # 每个进程的最大连接数
    use epoll;                  # 使用 epoll 模型
}

http {
    # 基本设置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1k;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    include /etc/nginx/conf.d/*.conf;
}
```

### PHP-FPM 优化

```bash
vim /etc/php-fpm.d/www.conf

# 进程管理优化
pm = dynamic
pm.max_children = 100           # 根据内存调整
pm.start_servers = 20
pm.min_spare_servers = 10
pm.max_spare_servers = 30
pm.max_requests = 500           # 进程处理请求数后重启

# 慢日志
slowlog = /var/log/php-fpm/www-slow.log
request_slowlog_timeout = 5s
```

### MySQL 优化

```bash
vim /etc/my.cnf

[mysqld]
# InnoDB 优化
innodb_buffer_pool_size = 1G    # 设置为物理内存的 50-70%
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# 连接数
max_connections = 500

# 查询缓存（MySQL 5.7）
query_cache_size = 64M
query_cache_type = 1

# 慢查询日志
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
```

---

## 一键安装脚本

```bash
#!/bin/bash
# LNMP 一键安装脚本

echo "开始安装 LNMP 环境..."

# 1. 系统初始化
echo "1. 系统初始化..."
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
yum update -y

# 2. 安装 Nginx
echo "2. 安装 Nginx..."
cat > /etc/yum.repos.d/nginx.repo << 'EOF'
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

yum install -y nginx
systemctl start nginx
systemctl enable nginx

# 3. 安装 MySQL
echo "3. 安装 MySQL..."
yum install -y mariadb-server mariadb
systemctl start mariadb
systemctl enable mariadb

# 4. 安装 PHP
echo "4. 安装 PHP..."
yum install -y epel-release
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y yum-utils
yum-config-manager --enable remi-php74
yum install -y php php-fpm php-mysql php-gd php-mbstring php-xml php-json php-curl

# 5. 配置 PHP-FPM
echo "5. 配置 PHP-FPM..."
sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf
systemctl start php-fpm
systemctl enable php-fpm

# 6. 配置 Nginx
echo "6. 配置 Nginx..."
cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.php index.html;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

systemctl restart nginx

# 7. 创建测试文件
echo "7. 创建测试文件..."
cat > /usr/share/nginx/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

chown -R nginx:nginx /usr/share/nginx/html

# 8. 配置防火墙
echo "8. 配置防火墙..."
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

echo "LNMP 安装完成！"
echo "访问 http://$(hostname -I | awk '{print $1}')/info.php 测试"
```

---

## 常见问题

### 1. Nginx 无法启动

**检查**：
```bash
# 查看错误日志
tail -f /var/log/nginx/error.log

# 检查配置
nginx -t

# 检查端口占用
netstat -tunlp | grep 80
```

### 2. PHP 文件被下载而不是执行

**原因**：Nginx 未正确配置 PHP 处理

**解决**：
```bash
# 检查 Nginx 配置中的 PHP 处理部分
# 确保 fastcgi_pass 指向正确的 socket 或端口
```

### 3. 502 Bad Gateway

**原因**：PHP-FPM 未运行或连接失败

**解决**：
```bash
# 检查 PHP-FPM 状态
systemctl status php-fpm

# 检查 socket 文件
ls -l /var/run/php-fpm.sock

# 检查权限
chown nginx:nginx /var/run/php-fpm.sock
```

---

## 小结

本节学习了：

✅ LNMP 架构和组件  
✅ Nginx 的安装和配置  
✅ MySQL 的安装和配置  
✅ PHP 和 PHP-FPM 的安装和配置  
✅ Nginx 与 PHP 的集成  
✅ 环境测试和优化  
✅ 一键安装脚本  

下一节将学习 WordPress 的安装和配置。

---

## 扩展阅读

- [Nginx 官方文档](http://nginx.org/en/docs/)
- [PHP-FPM 配置](https://www.php.net/manual/zh/install.fpm.configuration.php)
- [MySQL 优化指南](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
