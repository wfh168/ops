# SSH 高级应用

## SSH 端口转发（隧道）

SSH 不仅可以远程登录，还可以建立加密隧道，转发网络流量。

### 端口转发类型

```
┌─────────────────────────────────────────────────┐
│           SSH 端口转发（隧道）                    │
├─────────────────────────────────────────────────┤
│                                                 │
│  1. 本地端口转发（Local Port Forwarding）        │
│     -L [本地地址:]本地端口:目标地址:目标端口       │
│                                                 │
│  2. 远程端口转发（Remote Port Forwarding）       │
│     -R [远程地址:]远程端口:目标地址:目标端口       │
│                                                 │
│  3. 动态端口转发（Dynamic Port Forwarding）      │
│     -D [本地地址:]本地端口                       │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 本地端口转发（-L）

将本地端口的流量转发到远程服务器。

### 工作原理

```
本地客户端                SSH 服务器              目标服务器
    │                        │                      │
    │  访问 localhost:8080   │                      │
    ├───────────────────────▶│                      │
    │                        │  访问 target:80      │
    │                        ├─────────────────────▶│
    │                        │◀─────────────────────┤
    │◀───────────────────────┤                      │
    │  返回数据               │                      │
```

### 基本语法

```bash
ssh -L [本地地址:]本地端口:目标地址:目标端口 user@ssh_server
```

### 实战案例

#### 案例1：访问远程数据库

```bash
# 场景：数据库服务器不允许外网访问，通过 SSH 服务器访问
ssh -L 3306:localhost:3306 user@ssh_server

# 然后在本地连接
mysql -h 127.0.0.1 -P 3306 -u root -p

# 解释
# 本地 3306 端口 → SSH 服务器 → 数据库服务器 3306 端口
```

#### 案例2：访问内网 Web 服务

```bash
# 访问内网的 Web 服务
ssh -L 8080:192.168.1.100:80 user@ssh_server

# 浏览器访问
http://localhost:8080

# 解释
# 本地 8080 → SSH 服务器 → 内网 192.168.1.100:80
```

#### 案例3：多端口转发

```bash
# 同时转发多个端口
ssh -L 3306:db.internal:3306 \
    -L 6379:redis.internal:6379 \
    -L 8080:web.internal:80 \
    user@ssh_server
```

#### 案例4：后台运行

```bash
# 后台运行，不打开 shell
ssh -fNL 3306:localhost:3306 user@ssh_server

# 参数说明
-f    # 后台运行
-N    # 不执行远程命令
-L    # 本地端口转发
```

---

## 远程端口转发（-R）

将远程服务器的端口转发到本地。

### 工作原理

```
本地客户端                SSH 服务器              外部访问者
    │                        │                      │
    │                        │◀─ 访问 server:8080 ──┤
    │                        │                      │
    │◀─ 转发到 localhost:80 ─┤                      │
    │                        │                      │
    │─ 返回数据 ─────────────▶│                      │
    │                        ├─────────────────────▶│
```

### 基本语法

```bash
ssh -R [远程地址:]远程端口:目标地址:目标端口 user@ssh_server
```

### 实战案例

#### 案例1：内网穿透

```bash
# 场景：本地开发的 Web 服务，让外网可以访问
ssh -R 8080:localhost:80 user@public_server

# 外网访问
http://public_server:8080

# 解释
# 公网服务器 8080 → SSH 隧道 → 本地 80 端口
```

#### 案例2：临时演示

```bash
# 本地运行的项目，临时给客户演示
ssh -R 3000:localhost:3000 user@demo_server

# 客户访问
http://demo_server:3000
```

#### 案例3：反向代理

```bash
# 后台运行
ssh -fNR 8080:localhost:80 user@public_server

# 查看进程
ps aux | grep ssh
```

---

## 动态端口转发（-D）

创建一个 SOCKS 代理服务器。

### 工作原理

```
本地应用                  SSH 客户端              SSH 服务器
    │                        │                      │
    │  SOCKS5 代理请求       │                      │
    ├───────────────────────▶│                      │
    │                        │  加密隧道             │
    │                        ├─────────────────────▶│
    │                        │                      │
    │                        │  访问任意目标         │
    │                        │                      ├──▶ Internet
```

### 基本语法

```bash
ssh -D [本地地址:]本地端口 user@ssh_server
```

### 实战案例

#### 案例1：科学上网

```bash
# 创建 SOCKS5 代理
ssh -D 1080 user@overseas_server

# 配置浏览器
# SOCKS5 代理：127.0.0.1:1080
```

#### 案例2：安全访问

```bash
# 通过跳板机访问内网
ssh -D 1080 user@jumphost

# 配置应用使用代理
export http_proxy=socks5://127.0.0.1:1080
export https_proxy=socks5://127.0.0.1:1080

# 测试
curl --socks5 127.0.0.1:1080 http://internal.example.com
```

#### 案例3：浏览器配置

```bash
# Firefox 配置
# 首选项 → 网络设置 → 手动代理配置
# SOCKS 主机：127.0.0.1
# 端口：1080
# SOCKS v5

# Chrome 配置（命令行启动）
chrome --proxy-server="socks5://127.0.0.1:1080"
```

---

## SSH 配置文件高级用法

### 客户端配置（~/.ssh/config）

```bash
# 基本配置
Host myserver
    HostName 192.168.1.100
    User root
    Port 22
    IdentityFile ~/.ssh/id_rsa

# 跳板机配置
Host internal
    HostName 10.0.0.100
    User admin
    ProxyJump jumphost

Host jumphost
    HostName jump.example.com
    User jumper

# 通配符配置
Host *.example.com
    User deploy
    IdentityFile ~/.ssh/deploy_key
    StrictHostKeyChecking no

# 端口转发配置
Host db-tunnel
    HostName db.example.com
    User dbadmin
    LocalForward 3306 localhost:3306
    LocalForward 6379 localhost:6379

# 保持连接
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
```

### 服务器端配置（/etc/ssh/sshd_config）

```bash
# 性能优化
UseDNS no                        # 禁用 DNS 反向解析
GSSAPIAuthentication no          # 禁用 GSSAPI 认证

# 安全加固
PermitRootLogin no               # 禁止 root 登录
PasswordAuthentication no        # 禁用密码认证
PubkeyAuthentication yes         # 启用密钥认证
PermitEmptyPasswords no          # 禁止空密码

# 连接限制
MaxAuthTries 3                   # 最大认证尝试
MaxSessions 10                   # 最大会话数
MaxStartups 10:30:60             # 并发连接限制

# 超时设置
ClientAliveInterval 300          # 客户端存活检测（秒）
ClientAliveCountMax 2            # 最大检测次数
LoginGraceTime 60                # 登录超时

# 端口转发
AllowTcpForwarding yes           # 允许 TCP 转发
GatewayPorts no                  # 远程端口转发限制
PermitTunnel yes                 # 允许隧道

# 日志
SyslogFacility AUTH              # 日志设施
LogLevel INFO                    # 日志级别
```

---

## SSH Agent

SSH Agent 可以管理私钥，避免重复输入密码。

### 启动 SSH Agent

```bash
# 启动 agent
eval $(ssh-agent)

# 或
ssh-agent bash

# 查看 agent 进程
ps aux | grep ssh-agent
```

### 添加密钥

```bash
# 添加默认密钥
ssh-add

# 添加指定密钥
ssh-add ~/.ssh/custom_key

# 查看已添加的密钥
ssh-add -l

# 删除所有密钥
ssh-add -D

# 删除指定密钥
ssh-add -d ~/.ssh/custom_key
```

### 自动启动 Agent

```bash
# 添加到 ~/.bashrc 或 ~/.bash_profile
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent)
    ssh-add
fi
```

---

## SSH 多路复用

多个 SSH 连接共享一个 TCP 连接，提高效率。

### 配置多路复用

```bash
# 编辑 ~/.ssh/config
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m

# 创建 socket 目录
mkdir -p ~/.ssh/sockets
```

### 使用多路复用

```bash
# 第一次连接（建立主连接）
ssh user@host

# 后续连接（复用主连接，速度很快）
ssh user@host
scp file.txt user@host:/tmp/

# 查看连接状态
ssh -O check user@host

# 关闭主连接
ssh -O exit user@host
```

---

## SSH 跳板机（堡垒机）

通过中间服务器访问目标服务器。

### 方法1：ProxyJump（推荐）

```bash
# 命令行方式
ssh -J jumphost user@target

# 多级跳转
ssh -J jump1,jump2 user@target

# 配置文件方式
Host target
    HostName 10.0.0.100
    User admin
    ProxyJump jumphost

Host jumphost
    HostName jump.example.com
    User jumper
```

### 方法2：ProxyCommand

```bash
# 配置文件
Host target
    HostName 10.0.0.100
    User admin
    ProxyCommand ssh -W %h:%p jumphost
```

### 方法3：SSH 隧道

```bash
# 建立隧道
ssh -L 2222:target:22 user@jumphost

# 通过隧道连接
ssh -p 2222 user@localhost
```

---

## SSH 批量管理

### 使用循环

```bash
#!/bin/bash
# 批量执行命令

SERVERS="server1 server2 server3"

for server in $SERVERS; do
    echo "=== $server ==="
    ssh $server "hostname && uptime"
done
```

### 使用 pssh（并行 SSH）

```bash
# 安装
yum install pssh -y

# 创建主机列表
cat > hosts.txt << EOF
root@192.168.1.101
root@192.168.1.102
root@192.168.1.103
EOF

# 并行执行命令
pssh -h hosts.txt -i "uptime"

# 并行复制文件
pscp -h hosts.txt file.txt /tmp/

# 并行下载文件
pslurp -h hosts.txt /etc/hosts hosts_backup
```

### 使用 Ansible

```bash
# 安装
yum install ansible -y

# 配置主机
cat > /etc/ansible/hosts << EOF
[webservers]
web1 ansible_host=192.168.1.101
web2 ansible_host=192.168.1.102
EOF

# 执行命令
ansible webservers -m shell -a "uptime"

# 复制文件
ansible webservers -m copy -a "src=file.txt dest=/tmp/"
```

---

## SSH 安全最佳实践

### 1. 使用强密钥

```bash
# 使用 Ed25519（推荐）
ssh-keygen -t ed25519 -a 100

# 或 RSA 4096 位
ssh-keygen -t rsa -b 4096
```

### 2. 密钥加密

```bash
# 生成时设置密码
ssh-keygen -t ed25519
Enter passphrase: [输入密码]

# 修改密钥密码
ssh-keygen -p -f ~/.ssh/id_rsa
```

### 3. 限制来源 IP

```bash
# 在 authorized_keys 中限制
from="192.168.1.0/24" ssh-rsa AAAAB3...

# 或使用防火墙
iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP
```

### 4. 使用 2FA（双因素认证）

```bash
# 安装 Google Authenticator
yum install google-authenticator -y

# 配置
google-authenticator

# 编辑 PAM 配置
echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd

# 编辑 SSH 配置
vim /etc/ssh/sshd_config
ChallengeResponseAuthentication yes

# 重启服务
systemctl restart sshd
```

### 5. 监控 SSH 登录

```bash
# 查看登录日志
tail -f /var/log/secure

# 查看当前登录用户
w
who

# 查看登录历史
last
lastb    # 失败的登录尝试

# 实时监控
watch -n 1 'w'
```

---

## 实战脚本

### 脚本1：自动化密钥分发

```bash
#!/bin/bash
# distribute_key.sh

SERVERS="192.168.1.101 192.168.1.102 192.168.1.103"
PASSWORD="your_password"

# 检查 sshpass
if ! command -v sshpass &> /dev/null; then
    yum install sshpass -y
fi

# 生成密钥
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

# 分发密钥
for server in $SERVERS; do
    echo "配置 $server ..."
    sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no root@$server
    if [ $? -eq 0 ]; then
        echo "✓ $server 配置成功"
    else
        echo "✗ $server 配置失败"
    fi
done
```

### 脚本2：SSH 隧道管理

```bash
#!/bin/bash
# ssh_tunnel.sh

ACTION=$1
TUNNEL_NAME=$2

case $ACTION in
    start)
        case $TUNNEL_NAME in
            mysql)
                ssh -fNL 3306:localhost:3306 db_server
                echo "MySQL 隧道已启动"
                ;;
            redis)
                ssh -fNL 6379:localhost:6379 cache_server
                echo "Redis 隧道已启动"
                ;;
            *)
                echo "未知隧道: $TUNNEL_NAME"
                ;;
        esac
        ;;
    stop)
        pkill -f "ssh.*$TUNNEL_NAME"
        echo "隧道已停止"
        ;;
    status)
        ps aux | grep "ssh.*-L" | grep -v grep
        ;;
    *)
        echo "用法: $0 {start|stop|status} {mysql|redis}"
        ;;
esac
```

### 脚本3：批量健康检查

```bash
#!/bin/bash
# health_check.sh

SERVERS=$(cat servers.txt)

for server in $SERVERS; do
    echo "检查 $server ..."
    
    # 检查连接
    if ssh -o ConnectTimeout=5 $server "exit" 2>/dev/null; then
        # 获取信息
        HOSTNAME=$(ssh $server "hostname")
        UPTIME=$(ssh $server "uptime -p")
        LOAD=$(ssh $server "uptime | awk -F'load average:' '{print \$2}'")
        DISK=$(ssh $server "df -h / | tail -1 | awk '{print \$5}'")
        
        echo "  主机名: $HOSTNAME"
        echo "  运行时间: $UPTIME"
        echo "  负载: $LOAD"
        echo "  磁盘使用: $DISK"
        echo "  状态: ✓ 正常"
    else
        echo "  状态: ✗ 无法连接"
    fi
    echo ""
done
```

---

## 故障排查

### 问题1：端口转发不工作

```bash
# 检查服务器配置
grep AllowTcpForwarding /etc/ssh/sshd_config

# 应该是
AllowTcpForwarding yes

# 检查端口是否被占用
netstat -tuln | grep 端口号

# 查看详细日志
ssh -vvv -L 8080:localhost:80 user@host
```

### 问题2：连接断开

```bash
# 配置保持连接
vim ~/.ssh/config

Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
```

### 问题3：密钥不工作

```bash
# 检查权限
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 服务器端
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 查看日志
tail -f /var/log/secure
```

---

## 练习题

### 基础练习

1. 建立本地端口转发，访问远程数据库
2. 建立远程端口转发，实现内网穿透
3. 建立动态端口转发，创建 SOCKS 代理
4. 配置 SSH 多路复用
5. 使用 SSH Agent 管理密钥

### 进阶练习

1. 配置跳板机，通过中间服务器访问目标
2. 编写脚本批量管理多台服务器
3. 配置 SSH 双因素认证
4. 使用 pssh 并行执行命令
5. 搭建 SSH 堡垒机

---

## 总结

SSH 高级功能：
- ✅ 端口转发（本地、远程、动态）
- ✅ SSH Agent 密钥管理
- ✅ 多路复用提高效率
- ✅ 跳板机访问内网
- ✅ 批量管理服务器

掌握这些技能，你将能够：
- 安全访问内网资源
- 实现内网穿透
- 高效管理大量服务器
- 搭建安全的运维架构

---

## 下一步

完成 SSH 学习后，进入 **Nginx** 模块，学习企业级 Web 服务器的部署和管理。

Nginx 是最流行的 Web 服务器和反向代理，是运维工程师的必备技能！
