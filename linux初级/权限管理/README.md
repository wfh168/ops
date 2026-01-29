# 权限管理学习指南

## 学习路线

```
01_基本权限rwx.md      ──▶  掌握 rwx 权限和 chmod
        │
        ▼
02_特殊权限.md          ──▶  理解 SUID/SGID/Sticky Bit
        │
        ▼
03_ACL访问控制列表.md   ──▶  掌握更灵活的权限控制
        │
        ▼
04_umask默认权限.md     ──▶  理解新文件的默认权限
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_基本权限rwx.md | rwx 权限、chmod/chown/chgrp | 1 天 |
| 02_特殊权限.md | SUID/SGID/Sticky Bit | 0.5 天 |
| 03_ACL访问控制列表.md | setfacl/getfacl、默认 ACL | 0.5 天 |
| 04_umask默认权限.md | umask 计算和配置 | 0.5 天 |

## 核心概念

### 权限体系结构

```
Linux 权限体系
├── 基本权限 (rwx)
│   ├── 所有者 (user)
│   ├── 所属组 (group)
│   └── 其他人 (other)
│
├── 特殊权限
│   ├── SUID (4) - 以所有者身份执行
│   ├── SGID (2) - 以所属组身份执行/继承组
│   └── Sticky Bit (1) - 只能删自己的文件
│
├── ACL (访问控制列表)
│   ├── 用户 ACL
│   ├── 组 ACL
│   ├── mask (最大有效权限)
│   └── 默认 ACL
│
└── umask (默认权限)
    └── 新文件权限 = 最大权限 - umask
```

### 必须掌握的命令

```bash
# 基本权限
chmod 755 file                    # 修改权限
chown user:group file             # 修改所有者和组
chgrp group file                  # 修改所属组

# 特殊权限
chmod 4755 file                   # SUID
chmod 2755 dir                    # SGID
chmod 1777 dir                    # Sticky Bit

# ACL
setfacl -m u:user2:rw file        # 设置 ACL
getfacl file                      # 查看 ACL
setfacl -m d:u:user2:rwx dir      # 默认 ACL

# umask
umask                             # 查看 umask
umask 0022                        # 设置 umask
```

## 权限速查表

### 常用权限组合

| 数字 | 符号 | 说明 | 适用 |
|------|------|------|------|
| 644 | rw-r--r-- | 所有者读写，其他人只读 | 普通文件 |
| 755 | rwxr-xr-x | 所有者全权，其他人读执行 | 目录、脚本 |
| 600 | rw------- | 只有所有者可读写 | 私密文件 |
| 700 | rwx------ | 只有所有者可访问 | 私密目录 |
| 777 | rwxrwxrwx | 完全开放（危险！） | 临时测试 |

### 特殊权限组合

| 数字 | 说明 | 常见用途 |
|------|------|----------|
| 4755 | SUID + rwxr-xr-x | 可执行文件（如 passwd） |
| 2755 | SGID + rwxr-xr-x | 共享目录 |
| 1777 | Sticky + rwxrwxrwx | 公共目录（如 /tmp） |
| 3775 | SGID + Sticky + rwxrwxr-x | 团队协作目录 |

## 实战场景

### 场景1：Web 目录权限

```bash
# 目录
find /var/www/html -type d -exec chmod 755 {} \;

# 文件
find /var/www/html -type f -exec chmod 644 {} \;

# 所有者
chown -R www-data:www-data /var/www/html
```

### 场景2：团队协作目录

```bash
mkdir /project/shared
groupadd project_team
chgrp project_team /project/shared
chmod 2775 /project/shared        # SGID + rwxrwxr-x
setfacl -m d:g:project_team:rwx /project/shared
```

### 场景3：敏感文件保护

```bash
chmod 600 ~/.ssh/id_rsa           # SSH 私钥
chmod 644 ~/.ssh/id_rsa.pub       # SSH 公钥
chmod 700 ~/.ssh                  # SSH 目录
chmod 600 /etc/shadow             # 密码文件
```

## 权限检查流程

```
用户访问文件
    │
    ▼
是文件所有者？
    │
    ├─ 是 → 使用所有者权限
    │
    └─ 否 → 有用户 ACL？
            │
            ├─ 是 → 使用用户 ACL & mask
            │
            └─ 否 → 在所属组或有组 ACL？
                    │
                    ├─ 是 → 使用组权限/组 ACL & mask
                    │
                    └─ 否 → 使用其他人权限
```

## 安全最佳实践

1. **最小权限原则** - 只给必要的权限
2. **定期审计** - 检查 SUID/SGID 文件
3. **使用组管理** - 优先用组而非单独设置
4. **保护敏感文件** - 600 或 400 权限
5. **避免 777** - 除非临时测试

## 常见问题

### 1. 为什么有 w 权限还删不了文件？
删除文件取决于目录的 w 权限，而非文件本身。

### 2. 目录的 x 权限有什么用？
x 权限允许进入目录，是访问目录内容的前提。

### 3. SUID 和 sudo 有什么区别？
SUID 是文件属性，任何人执行都获得所有者权限；sudo 需要配置，更安全。

### 4. 什么时候用 ACL？
当传统权限无法满足需求时，比如需要给多个特定用户不同权限。

### 5. umask 如何影响新文件？
新文件权限 = 最大权限 - umask（文件 666，目录 777）

## 面试常考

1. 权限 755 是什么意思？（rwxr-xr-x）
2. SUID 的作用是什么？（以所有者身份执行）
3. 如何让目录中新文件自动属于特定组？（SGID）
4. Sticky Bit 的作用？（只能删自己的文件）
5. umask 0022 时新文件权限是多少？（644）

## 下一步

完成权限管理学习后，进入「定时任务」模块，学习使用 crontab 实现自动化运维。
