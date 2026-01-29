# umask 默认权限

## 什么是 umask

umask（user file-creation mode mask）决定新建文件和目录的默认权限。

---

## 一、umask 基本概念

### 查看 umask

```bash
umask                             # 显示数字形式
# 0022

umask -S                          # 显示符号形式
# u=rwx,g=rx,o=rx
```

### umask 的作用

```
新文件/目录的权限 = 最大权限 - umask

文件最大权限：666 (rw-rw-rw-)
目录最大权限：777 (rwxrwxrwx)
```

---

## 二、umask 计算规则

### 文件权限计算

```bash
# umask = 0022
# 文件最大权限 = 666

  666  (rw-rw-rw-)
- 022  (----w--w-)
------
  644  (rw-r--r--)

# 验证
umask 0022
touch file.txt
ls -l file.txt
# -rw-r--r-- 1 user group 0 Jan 7 10:00 file.txt
```

### 目录权限计算

```bash
# umask = 0022
# 目录最大权限 = 777

  777  (rwxrwxrwx)
- 022  (----w--w-)
------
  755  (rwxr-xr-x)

# 验证
umask 0022
mkdir testdir
ls -ld testdir
# drwxr-xr-x 2 user group 4096 Jan 7 10:00 testdir
```

---

## 三、常见 umask 值

| umask | 文件权限 | 目录权限 | 说明 |
|-------|---------|---------|------|
| 0022 | 644 (rw-r--r--) | 755 (rwxr-xr-x) | 默认值（推荐） |
| 0002 | 664 (rw-rw-r--) | 775 (rwxrwxr-x) | 组成员可写 |
| 0077 | 600 (rw-------) | 700 (rwx------) | 只有所有者可访问 |
| 0000 | 666 (rw-rw-rw-) | 777 (rwxrwxrwx) | 完全开放（危险！） |
| 0027 | 640 (rw-r-----) | 750 (rwxr-x---) | 组可读，其他人无权限 |

---

## 四、设置 umask

### 临时设置（当前会话）

```bash
# 设置 umask
umask 0022

# 验证
umask
# 0022

# 测试
touch file1.txt
mkdir dir1
ls -l
# -rw-r--r-- 1 user group 0 Jan 7 10:00 file1.txt
# drwxr-xr-x 2 user group 4096 Jan 7 10:00 dir1
```

### 永久设置（用户级别）

```bash
# 编辑用户配置文件
vim ~/.bashrc

# 添加
umask 0022

# 生效
source ~/.bashrc
```

### 永久设置（系统级别）

```bash
# 编辑系统配置
vim /etc/profile

# 或
vim /etc/bashrc

# 添加
umask 0022

# 对所有用户生效
```

---

## 五、不同用户的默认 umask

### root 用户

```bash
# root 默认 umask = 0022
su -
umask
# 0022

# 新建文件
touch /root/file.txt
ls -l /root/file.txt
# -rw-r--r-- 1 root root 0 Jan 7 10:00 /root/file.txt
```

### 普通用户

```bash
# 普通用户默认 umask = 0002 或 0022（取决于发行版）
umask
# 0002

# 新建文件
touch ~/file.txt
ls -l ~/file.txt
# -rw-rw-r-- 1 user user 0 Jan 7 10:00 /home/user/file.txt
```

---

## 六、umask 配置文件

### 配置文件优先级

```
1. /etc/profile              # 系统级，所有用户
2. /etc/bashrc               # 系统级，所有用户
3. ~/.bash_profile           # 用户级，登录 shell
4. ~/.bashrc                 # 用户级，交互 shell
```

### 查看当前配置

```bash
# 查看系统默认 umask
grep umask /etc/profile
grep umask /etc/bashrc

# 查看用户 umask
grep umask ~/.bashrc
grep umask ~/.bash_profile
```

---

## 七、实战案例

### 案例1：个人文件保护

```bash
# 需求：新建文件只有自己可以访问

# 设置 umask
umask 0077

# 测试
touch private.txt
ls -l private.txt
# -rw------- 1 user group 0 Jan 7 10:00 private.txt

mkdir private_dir
ls -ld private_dir
# drwx------ 2 user group 4096 Jan 7 10:00 private_dir
```

### 案例2：团队协作

```bash
# 需求：组成员可以读写新文件

# 设置 umask
umask 0002

# 测试
touch shared.txt
ls -l shared.txt
# -rw-rw-r-- 1 user group 0 Jan 7 10:00 shared.txt

mkdir shared_dir
ls -ld shared_dir
# drwxrwxr-x 2 user group 4096 Jan 7 10:00 shared_dir
```

### 案例3：Web 服务器

```bash
# 需求：Web 文件所有者可写，其他人只读

# 设置 umask
umask 0022

# 创建 Web 文件
touch /var/www/html/index.html
ls -l /var/www/html/index.html
# -rw-r--r-- 1 www-data www-data 0 Jan 7 10:00 index.html
```

### 案例4：脚本中临时修改 umask

```bash
#!/bin/bash

# 保存原 umask
OLD_UMASK=$(umask)

# 设置新 umask
umask 0077

# 创建私密文件
touch /tmp/secret.txt

# 恢复原 umask
umask $OLD_UMASK

# 创建普通文件
touch /tmp/normal.txt
```

---

## 八、umask 与 ACL

### umask 不影响 ACL

```bash
# 设置目录默认 ACL
setfacl -m d:u:user2:rwx /data/project

# 设置 umask
umask 0077

# 创建文件
touch /data/project/file.txt

# 查看权限
ls -l /data/project/file.txt
# -rw------- 1 user group 0 Jan 7 10:00 file.txt

# 查看 ACL
getfacl /data/project/file.txt
# user:user2:rwx                    # ACL 不受 umask 影响
```

---

## 九、特殊场景

### 1. 临时修改 umask

```bash
# 在子 shell 中修改
(umask 0077; touch private.txt)

# 不影响当前 shell
umask
# 0022
```

### 2. 不同 Shell 的 umask

```bash
# bash
umask 0022

# sh
umask 022                         # 可以省略前导 0

# csh/tcsh
umask 022
```

### 3. 服务的 umask

```bash
# systemd 服务的 umask
# 编辑服务文件
vim /etc/systemd/system/myapp.service

[Service]
UMask=0022                        # 设置服务的 umask

# 重新加载
systemctl daemon-reload
systemctl restart myapp
```

---

## 十、umask 最佳实践

### 1. 推荐设置

```bash
# root 用户
umask 0022                        # 文件 644，目录 755

# 普通用户（个人使用）
umask 0022                        # 文件 644，目录 755

# 普通用户（团队协作）
umask 0002                        # 文件 664，目录 775

# 高安全环境
umask 0077                        # 文件 600，目录 700
```

### 2. 检查和审计

```bash
# 检查当前 umask
umask

# 检查所有用户的 umask 配置
for user in $(cut -d: -f1 /etc/passwd); do
    echo -n "$user: "
    su - $user -c "umask" 2>/dev/null || echo "N/A"
done
```

### 3. 文档化

```bash
# 在配置文件中添加注释
# ~/.bashrc
# Set umask for team collaboration
umask 0002
```

---

## 十一、常见问题

### 1. 为什么文件没有执行权限？

```bash
# 文件最大权限是 666，不包含执行权限
# 需要手动添加
chmod +x file.sh
```

### 2. umask 设置不生效？

```bash
# 检查配置文件是否正确
grep umask ~/.bashrc

# 重新加载配置
source ~/.bashrc

# 检查是否被其他配置覆盖
grep -r umask /etc/profile.d/
```

### 3. 如何让新文件默认可执行？

```bash
# umask 无法做到（文件最大权限是 666）
# 只能创建后手动添加
touch script.sh
chmod +x script.sh
```

---

## 练习题

1. umask 0022 时，新建文件的权限是多少？
2. 如何让新建文件只有所有者可以访问？
3. umask 设置在哪个文件中可以对所有用户生效？

<details>
<summary>答案</summary>

1. 644 (rw-r--r--)，计算：666 - 022 = 644
2. 设置 `umask 0077`，新建文件权限为 600 (rw-------)
3. /etc/profile 或 /etc/bashrc

</details>
