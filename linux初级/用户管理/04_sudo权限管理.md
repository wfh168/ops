# sudo 权限管理

## 什么是 sudo

sudo（superuser do）允许普通用户以 root 权限执行命令。

### sudo 的优势

| 特性 | su | sudo |
|------|----|----|
| 需要密码 | root 密码 | 当前用户密码 |
| 权限范围 | 完全切换 | 单个命令 |
| 安全性 | 需要共享 root 密码 | 不需要 root 密码 |
| 审计 | 难以追踪 | 有详细日志 |
| 权限控制 | 全部或没有 | 可精细控制 |

---

## 一、sudo 基本使用

### 基本命令

```bash
# 以 root 权限执行命令
sudo command

# 切换到 root
sudo -i                           # 完全切换（推荐）
sudo -s                           # 保留环境变量
sudo su -                         # 等同于 sudo -i

# 以其他用户身份执行
sudo -u username command

# 编辑需要 root 权限的文件
sudo vim /etc/hosts
sudoedit /etc/hosts               # 更安全的方式

# 查看 sudo 权限
sudo -l                           # 列出当前用户可执行的命令

# 更新 sudo 时间戳（延长免密时间）
sudo -v

# 清除 sudo 时间戳
sudo -k
```

### sudo 密码缓存

```bash
# 首次使用 sudo 需要输入密码
sudo ls

# 5-15 分钟内再次使用无需密码
sudo cat /etc/shadow

# 清除缓存
sudo -k
```

---

## 二、sudoers 配置文件

### 配置文件位置

```bash
/etc/sudoers                      # 主配置文件
/etc/sudoers.d/                   # 额外配置目录
```

### 编辑 sudoers

```bash
# 使用 visudo 编辑（推荐，会检查语法）
visudo

# 编辑 sudoers.d 下的文件
visudo -f /etc/sudoers.d/myconfig
```

⚠️ 永远不要直接用 vim 编辑 /etc/sudoers，语法错误会导致无法使用 sudo！

---

## 三、sudoers 语法

### 基本格式

```
用户/组  主机=(运行身份)  命令
```

### 示例解析

```bash
# 1. 允许 wheel 组所有成员使用 sudo
%wheel  ALL=(ALL)  ALL
│       │   │      │
│       │   │      └── 可执行所有命令
│       │   └── 可以以任何用户身份运行
│       └── 在所有主机上
└── wheel 组（% 表示组）

# 2. 允许 user1 使用 sudo
user1  ALL=(ALL)  ALL

# 3. 允许 user2 执行特定命令
user2  ALL=(ALL)  /usr/bin/systemctl restart nginx

# 4. 允许 admin 组免密使用 sudo
%admin  ALL=(ALL)  NOPASSWD: ALL

# 5. 允许 user3 重启系统（免密）
user3  ALL=(ALL)  NOPASSWD: /usr/sbin/reboot, /usr/sbin/shutdown
```

---

## 四、常用配置

### 1. 添加用户到 sudo

```bash
# 方法1：加入 wheel 组（推荐）
usermod -aG wheel username

# 方法2：直接在 sudoers 中添加
visudo
# 添加：username  ALL=(ALL)  ALL
```

### 2. 免密 sudo

```bash
visudo
# 添加：
username  ALL=(ALL)  NOPASSWD: ALL

# 或者修改 wheel 组
%wheel  ALL=(ALL)  NOPASSWD: ALL
```

### 3. 限制命令

```bash
# 只允许重启 nginx
user1  ALL=(ALL)  /usr/bin/systemctl restart nginx

# 允许多个命令
user2  ALL=(ALL)  /usr/bin/systemctl restart nginx, /usr/bin/systemctl status nginx

# 使用命令别名
Cmnd_Alias NGINX_CMDS = /usr/bin/systemctl restart nginx, \
                        /usr/bin/systemctl reload nginx, \
                        /usr/bin/systemctl status nginx
user2  ALL=(ALL)  NGINX_CMDS
```

### 4. 限制用户身份

```bash
# 只能以 www-data 用户身份运行
user1  ALL=(www-data)  ALL

# 可以以 root 和 mysql 身份运行
user2  ALL=(root,mysql)  ALL
```

---

## 五、别名定义

### User_Alias - 用户别名

```bash
User_Alias ADMINS = user1, user2, user3
User_Alias DEVELOPERS = dev1, dev2, dev3

ADMINS  ALL=(ALL)  ALL
DEVELOPERS  ALL=(ALL)  /usr/bin/systemctl restart nginx
```

### Host_Alias - 主机别名

```bash
Host_Alias WEBSERVERS = web1, web2, web3
Host_Alias DBSERVERS = db1, db2

ADMINS  WEBSERVERS=(ALL)  ALL
```

### Cmnd_Alias - 命令别名

```bash
Cmnd_Alias NETWORKING = /sbin/route, /sbin/ifconfig, /bin/ping
Cmnd_Alias SOFTWARE = /bin/rpm, /usr/bin/yum, /usr/bin/dnf
Cmnd_Alias SERVICES = /usr/bin/systemctl start, /usr/bin/systemctl stop

ADMINS  ALL=(ALL)  NETWORKING, SOFTWARE, SERVICES
```

### Runas_Alias - 运行身份别名

```bash
Runas_Alias WEB = www-data, nginx, apache
Runas_Alias DB = mysql, postgres

user1  ALL=(WEB)  ALL
user2  ALL=(DB)  ALL
```

---

## 六、实战配置

### 场景1：Web 管理员

```bash
# 创建配置文件
visudo -f /etc/sudoers.d/webadmin

# 内容：
Cmnd_Alias WEB_CMDS = /usr/bin/systemctl restart nginx, \
                      /usr/bin/systemctl reload nginx, \
                      /usr/bin/systemctl status nginx, \
                      /usr/bin/vim /etc/nginx/*

User_Alias WEBADMINS = webadmin1, webadmin2

WEBADMINS  ALL=(ALL)  NOPASSWD: WEB_CMDS
```

### 场景2：数据库管理员

```bash
visudo -f /etc/sudoers.d/dbadmin

# 内容：
Cmnd_Alias DB_CMDS = /usr/bin/systemctl * mysql, \
                     /usr/bin/mysql, \
                     /usr/bin/mysqldump

User_Alias DBADMINS = dbadmin1, dbadmin2

DBADMINS  ALL=(ALL)  NOPASSWD: DB_CMDS
```

### 场景3：开发人员

```bash
visudo -f /etc/sudoers.d/developers

# 内容：
Cmnd_Alias DEV_CMDS = /usr/bin/systemctl restart nginx, \
                      /usr/bin/systemctl restart php-fpm, \
                      /usr/bin/tail /var/log/*

%developers  ALL=(ALL)  NOPASSWD: DEV_CMDS
```

---

## 七、安全配置

### 1. 日志记录

```bash
# 查看 sudo 日志
cat /var/log/secure | grep sudo   # CentOS/RHEL
cat /var/log/auth.log | grep sudo # Ubuntu/Debian

# 示例日志
# Jan 7 10:00:00 server sudo: user1 : TTY=pts/0 ; PWD=/home/user1 ; USER=root ; COMMAND=/bin/ls
```

### 2. 会话超时

```bash
visudo

# 添加：
Defaults    timestamp_timeout=5   # 5分钟后需要重新输入密码
Defaults    timestamp_timeout=0   # 每次都需要密码
Defaults    timestamp_timeout=-1  # 永不超时（不推荐）
```

### 3. 环境变量控制

```bash
# 保留特定环境变量
Defaults    env_keep += "LANG LC_* HOME"

# 重置环境变量
Defaults    env_reset

# 设置安全路径
Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin
```

### 4. 禁止危险操作

```bash
# 禁止使用 sudo su
Defaults    !rootpw
Defaults    !targetpw

# 要求 TTY（防止某些攻击）
Defaults    requiretty
```

---

## 八、故障排查

### 检查语法

```bash
# 检查 sudoers 语法
visudo -c

# 检查特定文件
visudo -c -f /etc/sudoers.d/myconfig
```

### 调试模式

```bash
# 查看详细信息
sudo -l -v

# 查看为什么命令被拒绝
sudo -l command
```

### 常见错误

```bash
# 错误1：用户不在 sudoers 中
# user1 is not in the sudoers file. This incident will be reported.
# 解决：将用户加入 wheel 组或在 sudoers 中添加

# 错误2：语法错误
# visudo: syntax error
# 解决：使用 visudo -c 检查语法

# 错误3：权限不足
# Sorry, user user1 is not allowed to execute '/bin/command' as root
# 解决：检查 sudoers 配置
```

---

## 练习题

1. 如何让用户使用 sudo 时不需要输入密码？
2. 为什么要用 visudo 而不是直接编辑 /etc/sudoers？
3. 如何查看当前用户可以执行哪些 sudo 命令？

<details>
<summary>答案</summary>

1. 在 sudoers 中添加 `username ALL=(ALL) NOPASSWD: ALL`
2. visudo 会检查语法错误，防止配置错误导致无法使用 sudo
3. `sudo -l`

</details>
