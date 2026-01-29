# Rsync 守护进程模式

## 什么是守护进程模式？

**Rsync 守护进程模式（Daemon Mode）** 是指 Rsync 作为一个独立的服务运行，监听特定端口（默认 873），提供文件同步服务。

### 守护进程模式的优势

✅ **更高性能**：不需要每次都启动 SSH 连接  
✅ **独立认证**：使用 Rsync 自己的认证机制  
✅ **灵活配置**：可以配置多个模块，不同权限  
✅ **日志记录**：详细的传输日志  
✅ **访问控制**：基于 IP 的访问控制  

### 适用场景

- 大量文件同步
- 多客户端同步
- 需要独立认证的场景
- 需要详细日志的场景

---

## 配置文件详解

### 主配置文件：/etc/rsyncd.conf

Rsync 守护进程的配置文件，定义全局设置和模块。

**基本结构**：

```ini
# 全局配置
uid = nobody
gid = nobody
port = 873
log file = /var/log/rsyncd.log

# 模块配置
[模块名]
path = /data/share
comment = 描述信息
read only = yes
```

---

## 全局配置选项

### 基本选项

```ini
# 运行用户和组
uid = nobody
gid = nobody

# 监听端口（默认 873）
port = 873

# 监听地址（默认所有）
address = 0.0.0.0

# 日志文件
log file = /var/log/rsyncd.log

# 传输日志格式
log format = %t %a %m %f %b

# PID 文件
pid file = /var/run/rsyncd.pid

# 锁文件
lock file = /var/run/rsync.lock
```

### 安全选项

```ini
# 最大连接数
max connections = 10

# 超时时间（秒）
timeout = 300

# 使用 chroot（提高安全性）
use chroot = yes

# 严格模式
strict modes = yes

# 主机允许列表
hosts allow = 192.168.1.0/24

# 主机拒绝列表
hosts deny = *
```

---

## 模块配置选项

### 基本选项

```ini
[模块名]
# 实际路径
path = /data/share

# 描述信息
comment = 共享目录

# 只读模式
read only = yes

# 列出模块（showmount 时是否显示）
list = yes

# 忽略错误
ignore errors = yes

# 忽略非可读目录
ignore nonreadable = yes
```

### 认证选项

```ini
# 认证用户（多个用户用逗号分隔）
auth users = backup,rsyncuser

# 密码文件
secrets file = /etc/rsyncd.secrets

# 严格模式（密码文件权限必须是 600）
strict modes = yes
```

### 访问控制

```ini
# 允许的主机
hosts allow = 192.168.1.0/24 10.0.0.0/8

# 拒绝的主机
hosts deny = *

# 只读
read only = yes

# 可写
read only = no

# 上传权限
write only = no
```

### 排除选项

```ini
# 排除文件
exclude = *.log *.tmp

# 排除文件列表
exclude from = /etc/rsyncd.exclude
```

---

## 配置示例

### 示例 1：基本只读共享

```ini
# /etc/rsyncd.conf

# 全局配置
uid = nobody
gid = nobody
port = 873
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid

# 只读共享模块
[backup]
path = /data/backup
comment = Backup Directory
read only = yes
list = yes
hosts allow = 192.168.1.0/24
hosts deny = *
```

### 示例 2：需要认证的读写共享

```ini
# /etc/rsyncd.conf

# 全局配置
uid = root
gid = root
port = 873
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
max connections = 10

# 读写共享模块
[webdata]
path = /var/www/html
comment = Web Data Directory
read only = no
list = yes
auth users = webuser
secrets file = /etc/rsyncd.secrets
hosts allow = 192.168.1.0/24
```

创建密码文件 `/etc/rsyncd.secrets`：

```bash
# 格式：用户名:密码
webuser:password123
```

设置权限：

```bash
chmod 600 /etc/rsyncd.secrets
```

### 示例 3：多模块配置

```ini
# /etc/rsyncd.conf

# 全局配置
uid = nobody
gid = nobody
port = 873
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid

# 备份模块（只读）
[backup]
path = /data/backup
comment = Backup Directory
read only = yes
list = yes
hosts allow = 192.168.1.0/24

# Web 数据模块（读写，需要认证）
[webdata]
path = /var/www/html
comment = Web Data
read only = no
auth users = webuser
secrets file = /etc/rsyncd.secrets
hosts allow = 192.168.1.10 192.168.1.11

# 日志模块（只写）
[logs]
path = /data/logs
comment = Log Directory
read only = no
write only = yes
auth users = loguser
secrets file = /etc/rsyncd.secrets
hosts allow = 192.168.1.0/24
```

---

## 启动 Rsync 守护进程

### 方法 1：直接启动

```bash
# 启动守护进程
rsync --daemon

# 指定配置文件
rsync --daemon --config=/etc/rsyncd.conf

# 查看进程
ps aux | grep rsync

# 查看端口
netstat -tunlp | grep 873
```

### 方法 2：使用 systemd

创建 systemd 服务文件 `/etc/systemd/system/rsyncd.service`：

```ini
[Unit]
Description=Rsync Daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/rsync --daemon --config=/etc/rsyncd.conf
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/rsyncd.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

启动服务：

```bash
# 重载 systemd
systemctl daemon-reload

# 启动服务
systemctl start rsyncd

# 设置开机自启
systemctl enable rsyncd

# 查看状态
systemctl status rsyncd

# 重启服务
systemctl restart rsyncd

# 停止服务
systemctl stop rsyncd
```

### 方法 3：使用 xinetd（旧方法）

安装 xinetd：

```bash
yum install -y xinetd
```

创建配置文件 `/etc/xinetd.d/rsync`：

```ini
service rsync
{
    disable = no
    socket_type = stream
    wait = no
    user = root
    server = /usr/bin/rsync
    server_args = --daemon
    log_on_failure += USERID
}
```

启动 xinetd：

```bash
systemctl start xinetd
systemctl enable xinetd
```

---

## 配置防火墙

### firewalld

```bash
# 开放 Rsync 端口
firewall-cmd --permanent --add-port=873/tcp
firewall-cmd --reload

# 或添加服务
firewall-cmd --permanent --add-service=rsyncd
firewall-cmd --reload

# 查看规则
firewall-cmd --list-all
```

### iptables

```bash
# 开放 873 端口
iptables -A INPUT -p tcp --dport 873 -j ACCEPT

# 保存规则
service iptables save
```

---

## 客户端使用

### 查看可用模块

```bash
# 查看服务器上的模块列表
rsync rsync://192.168.1.10/

# 输出示例
backup          Backup Directory
webdata         Web Data Directory
logs            Log Directory
```

### 不需要认证的同步

```bash
# 从服务器拉取（只读模块）
rsync -avz rsync://192.168.1.10/backup /local/backup/

# 推送到服务器（可写模块）
rsync -avz /local/data/ rsync://192.168.1.10/webdata/
```

### 需要认证的同步

#### 方法 1：交互式输入密码

```bash
# 拉取文件（会提示输入密码）
rsync -avz rsync://webuser@192.168.1.10/webdata /local/data/
```

#### 方法 2：使用密码文件

创建客户端密码文件 `/etc/rsync.password`：

```bash
# 只包含密码（不包含用户名）
password123
```

设置权限：

```bash
chmod 600 /etc/rsync.password
```

使用密码文件：

```bash
# 指定密码文件
rsync -avz --password-file=/etc/rsync.password \
  rsync://webuser@192.168.1.10/webdata /local/data/
```

#### 方法 3：环境变量

```bash
# 设置密码环境变量
export RSYNC_PASSWORD=password123

# 同步（不需要密码文件）
rsync -avz rsync://webuser@192.168.1.10/webdata /local/data/
```

---

## 实战案例

### 案例 1：备份服务器

**需求**：搭建备份服务器，多台服务器推送备份数据

**服务端配置**：

```bash
# 1. 创建备份目录
mkdir -p /data/backup
chmod 755 /data/backup

# 2. 配置 Rsync
vim /etc/rsyncd.conf
```

```ini
uid = root
gid = root
port = 873
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
max connections = 20

[backup]
path = /data/backup
comment = Backup Server
read only = no
auth users = backup
secrets file = /etc/rsyncd.secrets
hosts allow = 192.168.1.0/24
```

```bash
# 3. 创建密码文件
echo "backup:backup123" > /etc/rsyncd.secrets
chmod 600 /etc/rsyncd.secrets

# 4. 启动服务
rsync --daemon

# 5. 配置防火墙
firewall-cmd --permanent --add-port=873/tcp
firewall-cmd --reload
```

**客户端配置**：

```bash
# 1. 创建密码文件
echo "backup123" > /etc/rsync.password
chmod 600 /etc/rsync.password

# 2. 测试同步
rsync -avz --password-file=/etc/rsync.password \
  /data/important/ rsync://backup@192.168.1.10/backup/

# 3. 配置定时任务
crontab -e
0 2 * * * rsync -avz --password-file=/etc/rsync.password /data/important/ rsync://backup@192.168.1.10/backup/
```

### 案例 2：Web 服务器集群同步

**需求**：主 Web 服务器同步内容到多台从服务器

**主服务器配置**：

```bash
# 配置 Rsync 守护进程
vim /etc/rsyncd.conf
```

```ini
uid = www
gid = www
port = 873
log file = /var/log/rsyncd.log

[webdata]
path = /var/www/html
comment = Web Data
read only = yes
list = yes
hosts allow = 192.168.1.11 192.168.1.12 192.168.1.13
```

```bash
# 启动服务
systemctl start rsyncd
systemctl enable rsyncd
```

**从服务器配置**：

```bash
# 创建同步脚本
vim /usr/local/bin/sync-web.sh
```

```bash
#!/bin/bash
rsync -avz --delete rsync://192.168.1.10/webdata/ /var/www/html/
```

```bash
# 设置权限
chmod +x /usr/local/bin/sync-web.sh

# 配置定时任务（每 5 分钟同步一次）
crontab -e
*/5 * * * * /usr/local/bin/sync-web.sh
```

### 案例 3：日志收集服务器

**需求**：多台服务器将日志推送到日志服务器

**日志服务器配置**：

```bash
# 配置 Rsync
vim /etc/rsyncd.conf
```

```ini
uid = root
gid = root
port = 873
log file = /var/log/rsyncd.log

[logs]
path = /data/logs/%HOSTNAME%
comment = Log Collection
read only = no
write only = yes
auth users = logcollector
secrets file = /etc/rsyncd.secrets
hosts allow = 192.168.1.0/24
```

```bash
# 创建密码文件
echo "logcollector:log123" > /etc/rsyncd.secrets
chmod 600 /etc/rsyncd.secrets

# 启动服务
systemctl start rsyncd
```

**客户端配置**：

```bash
# 创建密码文件
echo "log123" > /etc/rsync.password
chmod 600 /etc/rsync.password

# 创建同步脚本
vim /usr/local/bin/push-logs.sh
```

```bash
#!/bin/bash
rsync -avz --password-file=/etc/rsync.password \
  /var/log/ rsync://logcollector@192.168.1.10/logs/
```

```bash
# 配置定时任务（每小时推送一次）
crontab -e
0 * * * * /usr/local/bin/push-logs.sh
```

---

## 监控和日志

### 查看日志

```bash
# 查看 Rsync 日志
tail -f /var/log/rsyncd.log

# 日志示例
2024/01/29 10:30:15 [12345] connect from 192.168.1.20 (192.168.1.20)
2024/01/29 10:30:15 [12345] rsync to backup/ from webuser@192.168.1.20 (192.168.1.20)
2024/01/29 10:30:20 [12345] sent 1234567 bytes  received 890 bytes  total size 9876543
```

### 自定义日志格式

```ini
# /etc/rsyncd.conf
log format = %t [%p] %o %h [%a] %m (%u) %f %l
```

**格式说明**：
- `%t`：时间戳
- `%p`：进程 ID
- `%o`：操作（send/recv）
- `%h`：远程主机名
- `%a`：远程 IP
- `%m`：模块名
- `%u`：认证用户
- `%f`：文件名
- `%l`：文件大小
- `%b`：传输字节数

### 监控连接

```bash
# 查看当前连接
netstat -an | grep :873

# 查看 Rsync 进程
ps aux | grep rsync

# 查看连接数
netstat -an | grep :873 | wc -l
```

---

## 常见问题

### 1. 连接被拒绝

**现象**：`rsync: failed to connect to 192.168.1.10: Connection refused`

**解决**：
```bash
# 检查服务是否启动
systemctl status rsyncd

# 检查端口是否监听
netstat -tunlp | grep 873

# 检查防火墙
firewall-cmd --list-all
```

### 2. 认证失败

**现象**：`@ERROR: auth failed on module backup`

**解决**：
```bash
# 检查密码文件权限
ls -l /etc/rsyncd.secrets
chmod 600 /etc/rsyncd.secrets

# 检查密码文件内容
cat /etc/rsyncd.secrets

# 检查用户名是否正确
```

### 3. 权限拒绝

**现象**：`rsync: mkstemp failed: Permission denied`

**解决**：
```bash
# 检查目录权限
ls -ld /data/backup

# 修改权限
chmod 755 /data/backup

# 检查 uid/gid 配置
# 确保 Rsync 运行用户有权限访问目录
```

### 4. 主机不允许

**现象**：`@ERROR: Unknown module 'backup'`

**解决**：
```bash
# 检查 hosts allow 配置
vim /etc/rsyncd.conf

# 确保客户端 IP 在允许列表中
hosts allow = 192.168.1.0/24
```

---

## 实战练习

### 练习 1：搭建基本 Rsync 服务器

```bash
# 1. 创建配置文件
vim /etc/rsyncd.conf
# 添加基本配置和一个模块

# 2. 启动服务
rsync --daemon

# 3. 测试连接
rsync rsync://localhost/

# 4. 测试同步
rsync -avz /tmp/test/ rsync://localhost/backup/
```

### 练习 2：配置认证

```bash
# 1. 添加认证配置
vim /etc/rsyncd.conf
# 添加 auth users 和 secrets file

# 2. 创建密码文件
echo "testuser:test123" > /etc/rsyncd.secrets
chmod 600 /etc/rsyncd.secrets

# 3. 重启服务
killall rsync
rsync --daemon

# 4. 测试认证
rsync -avz rsync://testuser@localhost/backup /tmp/test/
```

### 练习 3：配置定时同步

```bash
# 1. 创建密码文件
echo "password" > /etc/rsync.password
chmod 600 /etc/rsync.password

# 2. 创建同步脚本
vim /usr/local/bin/sync.sh
#!/bin/bash
rsync -avz --password-file=/etc/rsync.password \
  /data/source/ rsync://user@192.168.1.10/backup/

# 3. 设置权限
chmod +x /usr/local/bin/sync.sh

# 4. 配置定时任务
crontab -e
0 2 * * * /usr/local/bin/sync.sh
```

---

## 小结

本节学习了：

✅ Rsync 守护进程模式的概念和优势  
✅ rsyncd.conf 配置文件详解  
✅ 如何启动和管理 Rsync 守护进程  
✅ 客户端如何连接 Rsync 服务器  
✅ 实战案例（备份服务器、Web 集群、日志收集）  
✅ 监控、日志和故障排查  

下一节将学习 Rsync 的实时同步（配合 inotify）。
