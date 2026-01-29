# 用户管理学习指南

## 学习路线

```
01_用户和组概念.md      ──▶  理解 Linux 多用户系统
        │
        ▼
02_用户管理命令.md      ──▶  掌握 useradd/usermod/userdel
        │
        ▼
03_组管理命令.md        ──▶  掌握 groupadd/gpasswd
        │
        ▼
04_sudo权限管理.md      ──▶  掌握 sudo 和 sudoers 配置
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_用户和组概念.md | UID/GID、主组/附加组、配置文件 | 0.5 天 |
| 02_用户管理命令.md | useradd/usermod/userdel/passwd | 0.5 天 |
| 03_组管理命令.md | groupadd/groupmod/gpasswd | 0.5 天 |
| 04_sudo权限管理.md | sudo 使用、sudoers 配置 | 0.5 天 |

## 核心概念

### 必须理解的概念

1. **UID/GID** - 系统通过数字识别用户和组
2. **主组 vs 附加组** - 每个用户有一个主组，可以有多个附加组
3. **配置文件** - /etc/passwd、/etc/shadow、/etc/group
4. **sudo** - 比 su 更安全的权限提升方式

### 重要配置文件

```bash
/etc/passwd       # 用户信息（所有人可读）
/etc/shadow       # 密码信息（只有 root 可读）
/etc/group        # 组信息
/etc/gshadow      # 组密码
/etc/sudoers      # sudo 配置
```

### 必须掌握的命令

```bash
# 用户管理
useradd -m username               # 创建用户
passwd username                   # 设置密码
usermod -aG group username        # 添加到组
userdel -r username               # 删除用户

# 组管理
groupadd groupname                # 创建组
gpasswd -a username groupname     # 添加用户到组
gpasswd -d username groupname     # 从组中删除用户

# 查询
id username                       # 查看用户信息
groups username                   # 查看用户所属组
getent passwd username            # 查看用户详情
getent group groupname            # 查看组详情

# sudo
sudo command                      # 以 root 权限执行
sudo -l                           # 查看 sudo 权限
visudo                            # 编辑 sudoers
```

## 常用操作速查

### 创建完整用户

```bash
useradd -m -s /bin/bash -c "描述" -G wheel username
passwd username
```

### 将用户加入 sudo

```bash
usermod -aG wheel username        # CentOS/RHEL
usermod -aG sudo username         # Ubuntu/Debian
```

### 创建服务账号

```bash
useradd -r -s /sbin/nologin -c "Service Account" servicename
```

### 批量创建用户

```bash
for user in user1 user2 user3; do
    useradd -m "$user"
    echo "$user:password" | chpasswd
done
```

## 安全最佳实践

1. **使用 sudo 而非 su** - 更安全，有审计日志
2. **定期审计用户** - 删除不需要的账号
3. **强密码策略** - 使用 PAM 配置密码复杂度
4. **限制 sudo 权限** - 只给必要的命令权限
5. **禁用 root 远程登录** - 使用普通用户 + sudo

## 面试常考

1. UID 0 代表什么？（root 用户）
2. 主组和附加组的区别？
3. /etc/passwd 和 /etc/shadow 的区别？
4. 如何让用户使用 sudo 不需要密码？
5. 软链接和硬链接的区别？（虽然在文件属性，但常一起考）

## 下一步

完成用户管理学习后，进入「权限管理」模块，学习 Linux 的权限体系（rwx、特殊权限、ACL）。
