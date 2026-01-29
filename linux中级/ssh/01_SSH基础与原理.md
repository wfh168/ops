# SSH 基础与原理

## 什么是 SSH？

SSH（Secure Shell）是一种加密的网络协议，用于在不安全的网络中安全地远程登录和执行命令。

### SSH 的特点

- **加密传输**：所有数据都经过加密
- **身份验证**：支持密码和密钥认证
- **端口转发**：可以建立安全隧道
- **文件传输**：支持 SCP 和 SFTP

---

## SSH 工作原理

### 连接过程

```
客户端                                服务器
  │                                    │
  ├──────── 1. 建立 TCP 连接 ─────────▶│
  │                                    │
  │◀────── 2. 服务器发送公钥 ──────────┤
  │                                    │
  ├──────── 3. 客户端验证公钥 ─────────▶│
  │                                    │
  ├──────── 4. 协商加密算法 ───────────▶│
  │                                    │
  ├──────── 5. 用户认证 ───────────────▶│
  │                                    │
  │◀────── 6. 认证成功，建立会话 ──────┤
  │                                    │
  └──────── 7. 加密通信 ───────────────▶│
```

### SSH 版本

| 版本 | 特点 | 安全性 | 使用建议 |
|------|------|--------|----------|
| SSH-1 | 早期版本 | ❌ 不安全 | 禁用 |
| SSH-2 | 当前标准 | ✅ 安全 | 推荐使用 |

---

## SSH 认证方式

### 1. 密码认证

最简单但不够安全的方式。

```bash
# 基本语法
ssh 用户名@服务器IP

# 示例
ssh root@192.168.1.100
ssh user@example.com

# 指定端口
ssh -p 2222 root@192.168.1.100
```

**优点**：
- 简单易用
- 无需配置

**缺点**：
- 容易被暴力破解
- 需要每次输入密码
- 不适合自动化脚本

### 2. 密钥认证（推荐）

使用公钥/私钥对进行认证，更安全。

```bash
# 生成密钥对
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 参数说明
-t rsa          # 密钥类型（rsa、dsa、ecdsa、ed25519）
-b 4096         # 密钥长度（位）
-C "comment"    # 注释（通常是邮箱）

# 生成过程
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): [回车]
Enter passphrase (empty for no passphrase): [输入密码或回车]
Enter same passphrase again: [再次输入]
```

**密钥文件位置**：
```bash
~/.ssh/id_rsa       # 私钥（保密！）
~/.ssh/id_rsa.pub   # 公钥（可以公开）
```

**复制公钥到服务器**：

```bash
# 方法1：使用 ssh-copy-id（推荐）
ssh-copy-id user@192.168.1.100

# 方法2：手动复制
cat ~/.ssh/id_rsa.pub | ssh user@192.168.1.100 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 方法3：直接复制内容
# 1. 查看公钥
cat ~/.ssh/id_rsa.pub
# 2. 登录服务器
ssh user@192.168.1.100
# 3. 添加到 authorized_keys
echo "公钥内容" >> ~/.ssh/authorized_keys
```

**设置正确的权限**：

```bash
# 在服务器上执行
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**优点**：
- 非常安全
- 无需输入密码
- 适合自动化
- 可以设置密钥密码（双重保护）

---

## SSH 配置文件

### 服务器端配置

配置文件：`/etc/ssh/sshd_config`

```bash
# 查看配置
cat /etc/ssh/sshd_config

# 常用配置项
Port 22                          # SSH 端口
ListenAddress 0.0.0.0            # 监听地址
Protocol 2                       # 使用 SSH-2 协议

PermitRootLogin no               # 禁止 root 登录（推荐）
PasswordAuthentication yes       # 允许密码认证
PubkeyAuthentication yes         # 允许密钥认证

MaxAuthTries 3                   # 最大认证尝试次数
LoginGraceTime 60                # 登录超时时间（秒）
ClientAliveInterval 60           # 客户端存活检测间隔
ClientAliveCountMax 3            # 最大存活检测次数

AllowUsers user1 user2           # 允许登录的用户
DenyUsers user3 user4            # 拒绝登录的用户
```

**修改配置后重启服务**：

```bash
# CentOS/RHEL
systemctl restart sshd

# Ubuntu/Debian
systemctl restart ssh

# 检查状态
systemctl status sshd
```

### 客户端配置

配置文件：`~/.ssh/config`

```bash
# 创建配置文件
vim ~/.ssh/config

# 示例配置
Host myserver
    HostName 192.168.1.100
    User root
    Port 22
    IdentityFile ~/.ssh/id_rsa

Host web1
    HostName web1.example.com
    User deploy
    Port 2222
    IdentityFile ~/.ssh/web_rsa

Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**使用配置**：

```bash
# 直接使用别名连接
ssh myserver
ssh web1

# 等同于
ssh -p 22 root@192.168.1.100
ssh -p 2222 deploy@web1.example.com
```

---

## SSH 常用命令

### 基本连接

```bash
# 基本连接
ssh user@host

# 指定端口
ssh -p 2222 user@host

# 执行远程命令
ssh user@host "ls -la"
ssh user@host "df -h"

# 执行多条命令
ssh user@host "cd /var/log && tail -f messages"

# 使用指定密钥
ssh -i ~/.ssh/custom_key user@host
```

### 文件传输

#### SCP（Secure Copy）

```bash
# 上传文件
scp local_file user@host:/remote/path/
scp file.txt root@192.168.1.100:/tmp/

# 上传目录
scp -r local_dir user@host:/remote/path/
scp -r /data/backup root@192.168.1.100:/backup/

# 下载文件
scp user@host:/remote/file local_path/
scp root@192.168.1.100:/var/log/messages /tmp/

# 下载目录
scp -r user@host:/remote/dir local_path/

# 指定端口
scp -P 2222 file.txt user@host:/tmp/

# 限制带宽（KB/s）
scp -l 1024 large_file.zip user@host:/tmp/
```

#### SFTP（SSH File Transfer Protocol）

```bash
# 连接 SFTP
sftp user@host

# SFTP 命令
sftp> ls                    # 列出远程目录
sftp> lls                   # 列出本地目录
sftp> pwd                   # 显示远程当前目录
sftp> lpwd                  # 显示本地当前目录
sftp> cd /path              # 切换远程目录
sftp> lcd /path             # 切换本地目录
sftp> get remote_file       # 下载文件
sftp> put local_file        # 上传文件
sftp> mkdir dirname         # 创建远程目录
sftp> rmdir dirname         # 删除远程目录
sftp> rm filename           # 删除远程文件
sftp> quit                  # 退出
```

### 远程执行脚本

```bash
# 执行本地脚本
ssh user@host < local_script.sh

# 执行远程脚本
ssh user@host "bash /path/to/script.sh"

# 传输并执行
cat script.sh | ssh user@host "bash -s"
```

---

## SSH 密钥类型

### 常用密钥类型对比

| 类型 | 密钥长度 | 安全性 | 速度 | 推荐 |
|------|----------|--------|------|------|
| RSA | 2048-4096 | ⭐⭐⭐⭐ | 中等 | ✅ |
| DSA | 1024 | ⭐⭐ | 快 | ❌ 已过时 |
| ECDSA | 256-521 | ⭐⭐⭐⭐ | 快 | ✅ |
| Ed25519 | 256 | ⭐⭐⭐⭐⭐ | 最快 | ✅ 最推荐 |

### 生成不同类型的密钥

```bash
# RSA（传统，兼容性好）
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Ed25519（现代，推荐）
ssh-keygen -t ed25519 -C "your_email@example.com"

# ECDSA
ssh-keygen -t ecdsa -b 521 -C "your_email@example.com"
```

---

## SSH 安全加固

### 1. 修改默认端口

```bash
# 编辑配置
vim /etc/ssh/sshd_config

# 修改端口
Port 2222

# 重启服务
systemctl restart sshd
```

### 2. 禁用 root 登录

```bash
# 编辑配置
vim /etc/ssh/sshd_config

# 禁用 root
PermitRootLogin no

# 重启服务
systemctl restart sshd
```

### 3. 禁用密码认证

```bash
# 确保密钥认证已配置
# 编辑配置
vim /etc/ssh/sshd_config

# 禁用密码认证
PasswordAuthentication no
PubkeyAuthentication yes

# 重启服务
systemctl restart sshd
```

### 4. 限制登录用户

```bash
# 只允许特定用户
AllowUsers user1 user2

# 或拒绝特定用户
DenyUsers baduser1 baduser2
```

### 5. 使用防火墙

```bash
# 只允许特定 IP 访问 SSH
iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP
```

### 6. 安装 fail2ban

```bash
# 安装
yum install fail2ban -y

# 配置
vim /etc/fail2ban/jail.local

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/secure
maxretry = 3
bantime = 3600

# 启动
systemctl start fail2ban
systemctl enable fail2ban
```

---

## 实战案例

### 案例1：批量管理服务器

```bash
# 创建服务器列表
cat > servers.txt << EOF
192.168.1.101
192.168.1.102
192.168.1.103
EOF

# 批量执行命令
for server in $(cat servers.txt); do
    echo "=== $server ==="
    ssh root@$server "hostname && uptime"
done

# 批量分发文件
for server in $(cat servers.txt); do
    scp config.conf root@$server:/etc/
done
```

### 案例2：SSH 跳板机

```bash
# 通过跳板机连接目标服务器
ssh -J jumphost@jump.example.com user@target.example.com

# 或使用 ProxyJump
ssh -o ProxyJump=jumphost@jump.example.com user@target.example.com

# 配置文件方式
vim ~/.ssh/config

Host target
    HostName target.example.com
    User user
    ProxyJump jumphost@jump.example.com
```

### 案例3：免密码登录脚本

```bash
#!/bin/bash
# auto_ssh_key.sh - 自动配置 SSH 密钥

SERVERS="192.168.1.101 192.168.1.102 192.168.1.103"
PASSWORD="your_password"

# 生成密钥（如果不存在）
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

# 安装 sshpass（用于自动输入密码）
yum install sshpass -y

# 分发公钥
for server in $SERVERS; do
    echo "配置 $server ..."
    sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no root@$server
done

echo "完成！"
```

---

## 常见问题

### 1. 连接超时

```bash
# 问题
ssh: connect to host 192.168.1.100 port 22: Connection timed out

# 排查
ping 192.168.1.100              # 检查网络
telnet 192.168.1.100 22         # 检查端口
systemctl status sshd           # 检查服务
iptables -L -n                  # 检查防火墙
```

### 2. 权限被拒绝

```bash
# 问题
Permission denied (publickey,password)

# 排查
# 1. 检查密钥权限
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 2. 检查服务器 authorized_keys
ssh user@host "ls -la ~/.ssh/"
ssh user@host "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

# 3. 查看日志
tail -f /var/log/secure
```

### 3. 主机密钥变更

```bash
# 问题
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!

# 解决
ssh-keygen -R 192.168.1.100     # 删除旧的主机密钥
```

### 4. 连接缓慢

```bash
# 编辑配置
vim /etc/ssh/sshd_config

# 禁用 DNS 反向解析
UseDNS no

# 禁用 GSSAPI 认证
GSSAPIAuthentication no

# 重启服务
systemctl restart sshd
```

---

## 练习题

### 基础练习

1. 生成一个 4096 位的 RSA 密钥对
2. 将公钥复制到远程服务器
3. 使用密钥登录服务器（无需密码）
4. 修改 SSH 端口为 2222
5. 禁用 root 用户登录

### 进阶练习

1. 配置 SSH 客户端配置文件，使用别名连接
2. 使用 SCP 上传和下载文件
3. 通过 SSH 执行远程命令
4. 配置 SSH 跳板机
5. 编写脚本批量管理多台服务器

---

## 下一步

完成 SSH 基础学习后，继续学习：
- **02_SSH高级应用.md**：端口转发、隧道、代理

SSH 是 Linux 运维的基础技能，务必熟练掌握！
