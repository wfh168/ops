# SSH 远程管理学习指南

## 学习路线

```
01_SSH基础与原理.md    ──▶  掌握 SSH 基本使用
        │
        ▼
02_SSH高级应用.md      ──▶  精通端口转发和隧道
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_SSH基础与原理.md | SSH 原理、认证、配置 | 1 天 |
| 02_SSH高级应用.md | 端口转发、隧道、批量管理 | 1 天 |

## 核心知识点

### SSH 基础
- SSH 工作原理
- 密码认证 vs 密钥认证
- SSH 配置文件
- 文件传输（SCP、SFTP）
- 安全加固

### SSH 高级
- 本地端口转发（-L）
- 远程端口转发（-R）
- 动态端口转发（-D）
- SSH Agent
- 多路复用
- 跳板机配置
- 批量管理

## 常用命令速查

### 基本连接

```bash
ssh user@host                              # 基本连接
ssh -p 2222 user@host                      # 指定端口
ssh -i ~/.ssh/key user@host                # 指定密钥
ssh user@host "command"                    # 执行远程命令
```

### 密钥管理

```bash
ssh-keygen -t rsa -b 4096                  # 生成 RSA 密钥
ssh-keygen -t ed25519                      # 生成 Ed25519 密钥
ssh-copy-id user@host                      # 复制公钥
ssh-add ~/.ssh/id_rsa                      # 添加到 agent
ssh-add -l                                 # 查看已添加的密钥
```

### 文件传输

```bash
scp file.txt user@host:/path/              # 上传文件
scp -r dir user@host:/path/                # 上传目录
scp user@host:/path/file.txt ./            # 下载文件
scp -P 2222 file.txt user@host:/path/      # 指定端口
```

### 端口转发

```bash
ssh -L 8080:target:80 user@host            # 本地转发
ssh -R 8080:localhost:80 user@host         # 远程转发
ssh -D 1080 user@host                      # 动态转发（SOCKS）
ssh -fNL 3306:localhost:3306 user@host     # 后台运行
```

### 跳板机

```bash
ssh -J jumphost user@target                # ProxyJump
ssh -J jump1,jump2 user@target             # 多级跳转
```

## 配置文件模板

### 客户端配置（~/.ssh/config）

```bash
# 基本配置
Host myserver
    HostName 192.168.1.100
    User root
    Port 22
    IdentityFile ~/.ssh/id_rsa

# 跳板机
Host internal
    HostName 10.0.0.100
    User admin
    ProxyJump jumphost

# 端口转发
Host db-tunnel
    HostName db.example.com
    User dbadmin
    LocalForward 3306 localhost:3306

# 全局配置
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
```

### 服务器配置（/etc/ssh/sshd_config）

```bash
# 基本配置
Port 22
Protocol 2
ListenAddress 0.0.0.0

# 安全配置
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no

# 性能优化
UseDNS no
GSSAPIAuthentication no

# 连接限制
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2

# 端口转发
AllowTcpForwarding yes
GatewayPorts no
```

## 实战场景

### 场景1：访问内网数据库

```bash
# 建立隧道
ssh -L 3306:db.internal:3306 user@jumphost

# 本地连接
mysql -h 127.0.0.1 -P 3306 -u root -p
```

### 场景2：内网穿透

```bash
# 本地开发服务器
npm run dev    # 运行在 localhost:3000

# 建立反向隧道
ssh -R 8080:localhost:3000 user@public_server

# 外网访问
http://public_server:8080
```

### 场景3：科学上网

```bash
# 建立 SOCKS 代理
ssh -D 1080 user@overseas_server

# 配置浏览器
# SOCKS5: 127.0.0.1:1080
```

### 场景4：批量管理

```bash
# 批量执行命令
for server in web{1..10}; do
    ssh $server "systemctl restart nginx"
done

# 使用 pssh
pssh -h hosts.txt -i "uptime"
```

## 安全最佳实践

### 1. 使用密钥认证

```bash
# 生成强密钥
ssh-keygen -t ed25519 -a 100

# 禁用密码认证
PasswordAuthentication no
```

### 2. 修改默认端口

```bash
# 修改为非标准端口
Port 2222
```

### 3. 限制登录用户

```bash
# 只允许特定用户
AllowUsers user1 user2

# 禁止 root 登录
PermitRootLogin no
```

### 4. 使用防火墙

```bash
# 只允许特定 IP
iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP
```

### 5. 安装 fail2ban

```bash
# 防止暴力破解
yum install fail2ban -y
systemctl start fail2ban
```

## 故障排查

### 连接超时

```bash
# 检查网络
ping host

# 检查端口
telnet host 22

# 检查服务
systemctl status sshd

# 检查防火墙
iptables -L -n
```

### 权限被拒绝

```bash
# 检查密钥权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 服务器端
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 查看日志
tail -f /var/log/secure
```

### 连接缓慢

```bash
# 禁用 DNS 反向解析
UseDNS no

# 禁用 GSSAPI
GSSAPIAuthentication no

# 重启服务
systemctl restart sshd
```

## 练习题

### 基础练习

1. 生成 SSH 密钥对并配置免密登录
2. 修改 SSH 端口并禁用 root 登录
3. 使用 SCP 上传和下载文件
4. 通过 SSH 执行远程命令
5. 配置 SSH 客户端配置文件

### 进阶练习

1. 建立本地端口转发访问远程数据库
2. 建立远程端口转发实现内网穿透
3. 建立动态端口转发创建 SOCKS 代理
4. 配置跳板机访问内网服务器
5. 编写脚本批量管理多台服务器
6. 配置 SSH 多路复用
7. 使用 SSH Agent 管理密钥
8. 安装配置 fail2ban 防止暴力破解

## 面试常考

1. SSH 的工作原理是什么？
2. 密码认证和密钥认证的区别？
3. 如何配置 SSH 免密登录？
4. SSH 端口转发有哪几种类型？
5. 如何加固 SSH 安全？
6. 什么是 SSH 跳板机？如何配置？
7. 如何批量管理多台服务器？
8. SSH 连接慢的原因和解决方法？

## 学习建议

### 1. 实践为主

- 搭建测试环境（至少 2 台虚拟机）
- 每个命令都要亲自操作
- 记录遇到的问题和解决方法

### 2. 安全意识

- 永远不要在生产环境禁用密钥验证
- 定期更换密钥
- 监控 SSH 登录日志
- 使用强密码和密钥

### 3. 自动化思维

- 学会编写脚本批量操作
- 使用配置文件简化操作
- 掌握 SSH Agent 和多路复用

### 4. 故障排查

- 学会查看日志
- 理解常见错误原因
- 掌握调试技巧（-v、-vv、-vvv）

## 推荐资源

### 官方文档

- [OpenSSH 官方文档](https://www.openssh.com/manual.html)
- [SSH.COM 教程](https://www.ssh.com/academy/ssh)

### 推荐书籍

- 《SSH, The Secure Shell》
- 《Linux 系统管理技术手册》

### 在线资源

- ArchWiki SSH 页面
- DigitalOcean SSH 教程
- 阮一峰 SSH 教程

## 下一步

完成 SSH 学习后，进入 **Nginx** 模块。

Nginx 是企业级 Web 服务器，学习内容包括：
- Nginx 安装配置
- 虚拟主机
- 反向代理
- 负载均衡
- 性能优化

SSH 是远程管理的基础，Nginx 是 Web 服务的核心，两者都是运维工程师的必备技能！

加油！💪
