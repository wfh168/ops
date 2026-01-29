# MySQL 安装与配置

## 一、MySQL 简介

### 1.1 什么是 MySQL

MySQL 是一个开源的关系型数据库管理系统（RDBMS），由瑞典 MySQL AB 公司开发，目前属于 Oracle 公司。

**特点**：
- 开源免费
- 性能优秀
- 易于使用
- 跨平台支持
- 社区活跃
- 应用广泛

**应用场景**：
- Web 应用
- 电商系统
- 内容管理系统
- 数据仓库
- 日志系统
- 游戏后台

### 1.2 MySQL 版本

**主要版本**：
- **MySQL 5.7**：稳定版本，企业广泛使用
- **MySQL 8.0**：最新版本，性能更优，新特性更多
- **MariaDB**：MySQL 的分支，完全兼容

**版本选择建议**：
- 新项目：推荐 MySQL 8.0
- 生产环境：MySQL 5.7（稳定）
- 学习：MySQL 8.0（新特性）

---

## 二、Linux 环境安装

### 2.1 CentOS/RHEL 安装

#### 方式1：YUM 安装（推荐）

```bash
# 1. 下载 MySQL YUM 源
wget https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm

# 2. 安装 YUM 源
sudo rpm -ivh mysql80-community-release-el7-7.noarch.rpm

# 3. 查看可用版本
yum repolist all | grep mysql

# 4. 选择版本（可选，默认 8.0）
# 禁用 MySQL 8.0
sudo yum-config-manager --disable mysql80-community
# 启用 MySQL 5.7
sudo yum-config-manager --enable mysql57-community

# 5. 安装 MySQL
sudo yum install -y mysql-community-server

# 6. 查看安装的版本
mysql --version
```

#### 方式2：二进制包安装

```bash
# 1. 下载二进制包
cd /opt
wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.35-linux-glibc2.12-x86_64.tar.xz

# 2. 解压
tar -xvf mysql-8.0.35-linux-glibc2.12-x86_64.tar.xz
mv mysql-8.0.35-linux-glibc2.12-x86_64 mysql

# 3. 创建 MySQL 用户
groupadd mysql
useradd -r -g mysql -s /bin/false mysql

# 4. 创建数据目录
mkdir -p /data/mysql
chown -R mysql:mysql /data/mysql
chmod 750 /data/mysql

# 5. 配置环境变量
echo 'export PATH=/opt/mysql/bin:$PATH' >> /etc/profile
source /etc/profile

# 6. 初始化数据库
cd /opt/mysql
bin/mysqld --initialize --user=mysql --basedir=/opt/mysql --datadir=/data/mysql

# 注意：记录临时密码！
# 输出类似：A temporary password is generated for root@localhost: xxxx
```

### 2.2 Ubuntu/Debian 安装

```bash
# 1. 更新包列表
sudo apt update

# 2. 安装 MySQL
sudo apt install -y mysql-server

# 3. 查看版本
mysql --version

# 4. 查看服务状态
sudo systemctl status mysql
```

### 2.3 启动 MySQL 服务

```bash
# 启动服务
sudo systemctl start mysqld    # CentOS
sudo systemctl start mysql     # Ubuntu

# 设置开机自启
sudo systemctl enable mysqld   # CentOS
sudo systemctl enable mysql    # Ubuntu

# 查看状态
sudo systemctl status mysqld   # CentOS
sudo systemctl status mysql    # Ubuntu

# 重启服务
sudo systemctl restart mysqld  # CentOS
sudo systemctl restart mysql   # Ubuntu

# 停止服务
sudo systemctl stop mysqld     # CentOS
sudo systemctl stop mysql      # Ubuntu
```

---

## 三、初始化配置

### 3.1 获取临时密码

```bash
# CentOS/RHEL
sudo grep 'temporary password' /var/log/mysqld.log

# 输出示例
# A temporary password is generated for root@localhost: kq7wP#5tN>mK
```

### 3.2 首次登录

```bash
# 使用临时密码登录
mysql -u root -p
# 输入临时密码
```

### 3.3 修改 root 密码

```sql
-- MySQL 5.7
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword123!';

-- MySQL 8.0
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'NewPassword123!';

-- 刷新权限
FLUSH PRIVILEGES;

-- 退出
EXIT;
```

### 3.4 安全配置脚本

```bash
# 运行安全配置脚本
sudo mysql_secure_installation

# 配置选项：
# 1. 是否设置密码验证插件？ [Y/N] - 根据需要选择
# 2. 修改 root 密码？ [Y/N] - Y
# 3. 删除匿名用户？ [Y/N] - Y
# 4. 禁止 root 远程登录？ [Y/N] - Y（生产环境）
# 5. 删除 test 数据库？ [Y/N] - Y
# 6. 重新加载权限表？ [Y/N] - Y
```

---

## 四、配置文件

### 4.1 配置文件位置

```bash
# CentOS/RHEL
/etc/my.cnf

# Ubuntu/Debian
/etc/mysql/mysql.conf.d/mysqld.cnf

# 自定义配置目录
/etc/my.cnf.d/
```

### 4.2 基本配置

```ini
# /etc/my.cnf

[mysqld]
# 基本设置
port = 3306
datadir = /var/lib/mysql
socket = /var/lib/mysql/mysql.sock
pid-file = /var/run/mysqld/mysqld.pid

# 字符集
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 连接设置
max_connections = 200
max_connect_errors = 100

# 日志设置
log-error = /var/log/mysqld.log

# 慢查询日志
slow_query_log = 1
slow_query_log_file = /var/log/mysql-slow.log
long_query_time = 2

# 二进制日志
log-bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7

# InnoDB 设置
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 1

[mysql]
# 客户端字符集
default-character-set = utf8mb4

[client]
port = 3306
socket = /var/lib/mysql/mysql.sock
default-character-set = utf8mb4
```

### 4.3 重启服务使配置生效

```bash
sudo systemctl restart mysqld
```

---

## 五、客户端工具

### 5.1 命令行客户端

```bash
# 本地登录
mysql -u root -p

# 指定主机登录
mysql -h 192.168.1.100 -u root -p

# 指定端口登录
mysql -h 192.168.1.100 -P 3306 -u root -p

# 指定数据库登录
mysql -u root -p -D mydb

# 执行 SQL 文件
mysql -u root -p < script.sql

# 执行 SQL 语句
mysql -u root -p -e "SHOW DATABASES;"
```

### 5.2 MySQL Workbench

**下载地址**：https://dev.mysql.com/downloads/workbench/

**功能**：
- 可视化数据库管理
- SQL 编辑器
- 数据建模
- 服务器管理
- 数据导入导出

### 5.3 Navicat

**功能**：
- 多数据库支持
- 可视化查询构建器
- 数据同步
- 备份和恢复
- SSH 隧道支持

### 5.4 DBeaver（开源）

**下载地址**：https://dbeaver.io/

**功能**：
- 免费开源
- 支持多种数据库
- SQL 编辑器
- ER 图
- 数据导入导出

---

## 六、基本管理命令

### 6.1 登录和退出

```sql
-- 登录
mysql -u root -p

-- 查看当前用户
SELECT USER();

-- 查看当前数据库
SELECT DATABASE();

-- 退出
EXIT;
-- 或
QUIT;
-- 或
\q
```

### 6.2 查看系统信息

```sql
-- 查看版本
SELECT VERSION();

-- 查看当前时间
SELECT NOW();

-- 查看系统变量
SHOW VARIABLES;

-- 查看特定变量
SHOW VARIABLES LIKE 'character%';
SHOW VARIABLES LIKE 'max_connections';

-- 查看状态
SHOW STATUS;

-- 查看进程列表
SHOW PROCESSLIST;

-- 查看存储引擎
SHOW ENGINES;
```

### 6.3 数据库操作

```sql
-- 查看所有数据库
SHOW DATABASES;

-- 创建数据库
CREATE DATABASE mydb;

-- 创建数据库（指定字符集）
CREATE DATABASE mydb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 选择数据库
USE mydb;

-- 查看当前数据库
SELECT DATABASE();

-- 删除数据库
DROP DATABASE mydb;
```

### 6.4 表操作

```sql
-- 查看所有表
SHOW TABLES;

-- 查看表结构
DESC table_name;
-- 或
DESCRIBE table_name;
-- 或
SHOW COLUMNS FROM table_name;

-- 查看建表语句
SHOW CREATE TABLE table_name;

-- 查看表状态
SHOW TABLE STATUS LIKE 'table_name';
```

---

## 七、用户和权限管理

### 7.1 创建用户

```sql
-- 创建本地用户
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';

-- 创建远程用户
CREATE USER 'username'@'%' IDENTIFIED BY 'password';

-- 创建指定 IP 用户
CREATE USER 'username'@'192.168.1.100' IDENTIFIED BY 'password';
```

### 7.2 授予权限

```sql
-- 授予所有权限
GRANT ALL PRIVILEGES ON *.* TO 'username'@'localhost';

-- 授予特定数据库权限
GRANT ALL PRIVILEGES ON mydb.* TO 'username'@'localhost';

-- 授予特定表权限
GRANT SELECT, INSERT, UPDATE ON mydb.users TO 'username'@'localhost';

-- 授予查询权限
GRANT SELECT ON mydb.* TO 'username'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;
```

### 7.3 查看权限

```sql
-- 查看当前用户权限
SHOW GRANTS;

-- 查看指定用户权限
SHOW GRANTS FOR 'username'@'localhost';
```

### 7.4 撤销权限

```sql
-- 撤销权限
REVOKE ALL PRIVILEGES ON mydb.* FROM 'username'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;
```

### 7.5 删除用户

```sql
-- 删除用户
DROP USER 'username'@'localhost';
```

---

## 八、远程访问配置

### 8.1 修改配置文件

```bash
# 编辑配置文件
sudo vim /etc/my.cnf

# 注释或删除以下行
# bind-address = 127.0.0.1

# 重启服务
sudo systemctl restart mysqld
```

### 8.2 创建远程用户

```sql
-- 创建远程用户
CREATE USER 'remote_user'@'%' IDENTIFIED BY 'password';

-- 授予权限
GRANT ALL PRIVILEGES ON *.* TO 'remote_user'@'%';

-- 刷新权限
FLUSH PRIVILEGES;
```

### 8.3 配置防火墙

```bash
# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload

# Ubuntu/Debian
sudo ufw allow 3306/tcp
sudo ufw reload
```

---

## 九、Windows 环境安装

### 9.1 下载安装包

访问：https://dev.mysql.com/downloads/mysql/

选择：Windows (x86, 64-bit), ZIP Archive

### 9.2 安装步骤

```powershell
# 1. 解压到目录
# 例如：C:\mysql

# 2. 创建配置文件 my.ini
[mysqld]
basedir=C:\mysql
datadir=C:\mysql\data
port=3306
character-set-server=utf8mb4

[client]
default-character-set=utf8mb4

# 3. 初始化数据库
cd C:\mysql\bin
mysqld --initialize --console
# 记录临时密码

# 4. 安装服务
mysqld --install MySQL

# 5. 启动服务
net start MySQL

# 6. 登录并修改密码
mysql -u root -p
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword123!';
```

---

## 十、故障排查

### 10.1 无法启动

```bash
# 查看错误日志
sudo tail -f /var/log/mysqld.log

# 检查端口占用
sudo netstat -tunlp | grep 3306

# 检查数据目录权限
ls -ld /var/lib/mysql

# 修复权限
sudo chown -R mysql:mysql /var/lib/mysql
```

### 10.2 忘记密码

```bash
# 1. 停止 MySQL
sudo systemctl stop mysqld

# 2. 跳过权限启动
sudo mysqld_safe --skip-grant-tables &

# 3. 登录（无需密码）
mysql -u root

# 4. 修改密码
USE mysql;
UPDATE user SET authentication_string=PASSWORD('NewPassword123!') WHERE User='root';
FLUSH PRIVILEGES;
EXIT;

# 5. 重启 MySQL
sudo systemctl restart mysqld
```

### 10.3 连接被拒绝

```bash
# 检查服务状态
sudo systemctl status mysqld

# 检查端口监听
sudo netstat -tunlp | grep 3306

# 检查防火墙
sudo firewall-cmd --list-all

# 检查用户权限
mysql -u root -p
SELECT user, host FROM mysql.user;
```

---

## 十一、实战练习

### 练习1：安装 MySQL

1. 在 Linux 系统上安装 MySQL 8.0
2. 完成初始化配置
3. 修改 root 密码
4. 运行安全配置脚本

### 练习2：用户管理

1. 创建数据库用户
2. 授予不同级别的权限
3. 测试用户登录
4. 撤销和删除用户

### 练习3：远程访问

1. 配置 MySQL 允许远程访问
2. 创建远程用户
3. 配置防火墙
4. 使用客户端工具连接

---

## 十二、总结

本节学习了：

✅ MySQL 简介和版本选择  
✅ Linux 环境安装方法  
✅ 初始化配置  
✅ 配置文件详解  
✅ 客户端工具使用  
✅ 基本管理命令  
✅ 用户和权限管理  
✅ 远程访问配置  
✅ Windows 环境安装  
✅ 故障排查  

**下一节**：学习 SQL 基础语法。

---

## 参考资料

- [MySQL 官方文档](https://dev.mysql.com/doc/)
- [MySQL 下载](https://dev.mysql.com/downloads/)
- [MySQL 教程](https://www.mysqltutorial.org/)
