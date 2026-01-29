# ACL 访问控制列表

## 什么是 ACL

ACL（Access Control List）提供了比传统 rwx 更灵活的权限控制。

### 传统权限的局限

```bash
# 传统权限只能设置：所有者、所属组、其他人
-rw-r--r-- 1 user1 group1 1024 Jan 7 10:00 file.txt

# 问题：如何让 user2 也有写权限，但不影响其他人？
# 传统方式：
# 1. 把 user2 加入 group1 → 但 group1 的其他成员也会受影响
# 2. 修改其他人权限 → 但所有人都会受影响

# ACL 方式：
# 单独给 user2 设置权限，不影响其他人
```

---

## 一、ACL 基本概念

### ACL 类型

| 类型 | 说明 |
|------|------|
| user | 指定用户的权限 |
| group | 指定组的权限 |
| mask | 最大有效权限 |
| other | 其他人的权限 |

### 查看 ACL

```bash
# 查看文件 ACL
getfacl file.txt

# 输出示例
# file: file.txt
# owner: user1
# group: group1
user::rw-                         # 所有者权限
user:user2:rw-                    # user2 的 ACL 权限
group::r--                        # 所属组权限
mask::rw-                         # 最大有效权限
other::r--                        # 其他人权限
```

### ls 显示 ACL

```bash
ls -l file.txt
-rw-rw-r--+ 1 user1 group1 1024 Jan 7 10:00 file.txt
          ^
          └── + 表示有 ACL
```

---

## 二、setfacl - 设置 ACL

### 基本语法

```bash
setfacl [选项] [规则] 文件
```

### 给用户设置 ACL

```bash
# 给 user2 设置读写权限
setfacl -m u:user2:rw file.txt

# 给 user3 设置只读权限
setfacl -m u:user3:r file.txt

# 给多个用户设置权限
setfacl -m u:user2:rw,u:user3:r file.txt
```

### 给组设置 ACL

```bash
# 给 developers 组设置读写权限
setfacl -m g:developers:rw file.txt

# 给 testers 组设置只读权限
setfacl -m g:testers:r file.txt
```

### 删除 ACL

```bash
# 删除指定用户的 ACL
setfacl -x u:user2 file.txt

# 删除指定组的 ACL
setfacl -x g:developers file.txt

# 删除所有 ACL（保留基本权限）
setfacl -b file.txt
```

### 递归设置

```bash
# 递归设置目录及其内容
setfacl -R -m u:user2:rwx /data/project

# 递归删除 ACL
setfacl -R -b /data/project
```

---

## 三、默认 ACL

### 概念

默认 ACL 作用于目录，在该目录中创建的新文件会自动继承默认 ACL。

### 设置默认 ACL

```bash
# 给目录设置默认 ACL
setfacl -m d:u:user2:rwx /data/project
#          ^
#          └── d 表示 default

# 查看
getfacl /data/project
# default:user:user2:rwx            # 默认 ACL

# 测试
touch /data/project/newfile.txt
getfacl /data/project/newfile.txt
# user:user2:rwx                    # 自动继承
```

### 同时设置当前和默认 ACL

```bash
# 设置当前 ACL
setfacl -m u:user2:rwx /data/project

# 设置默认 ACL
setfacl -m d:u:user2:rwx /data/project

# 或者一次性设置
setfacl -m u:user2:rwx,d:u:user2:rwx /data/project
```

---

## 四、mask - 最大有效权限

### 概念

mask 定义了用户和组 ACL 的最大有效权限。

```bash
# 设置 ACL
setfacl -m u:user2:rwx file.txt

# 设置 mask
setfacl -m m::r file.txt          # mask 设为只读

# 查看
getfacl file.txt
# user:user2:rwx                    # effective:r--
#                                   # 实际只有 r 权限
```

### mask 的作用

```
用户实际权限 = 用户 ACL 权限 & mask

例如：
user2 ACL: rwx (7)
mask:      r-- (4)
实际权限:  r-- (4)
```

### 自动计算 mask

```bash
# 添加 ACL 时，mask 会自动更新为所有 ACL 权限的并集
setfacl -m u:user2:rw file.txt    # mask 自动变为 rw-
setfacl -m u:user3:r file.txt     # mask 保持 rw-

# 手动设置 mask
setfacl -m m::r file.txt          # 强制设置 mask
```

---

## 五、复制和备份 ACL

### 复制 ACL

```bash
# 从 file1 复制 ACL 到 file2
getfacl file1 | setfacl --set-file=- file2

# 复制到多个文件
getfacl file1 | setfacl --set-file=- file2 file3 file4
```

### 备份和恢复 ACL

```bash
# 备份目录的 ACL
getfacl -R /data/project > /backup/acl_backup.txt

# 恢复 ACL
setfacl --restore=/backup/acl_backup.txt
```

---

## 六、实战案例

### 案例1：项目协作目录

```bash
# 需求：
# - user1 是项目负责人，完全控制
# - user2, user3 是开发人员，可读写
# - user4 是测试人员，只读
# - 新文件自动继承权限

# 1. 创建目录
mkdir /project/alpha
chown user1:project /project/alpha
chmod 750 /project/alpha

# 2. 设置 ACL
setfacl -m u:user2:rwx /project/alpha
setfacl -m u:user3:rwx /project/alpha
setfacl -m u:user4:rx /project/alpha

# 3. 设置默认 ACL
setfacl -m d:u:user2:rwx /project/alpha
setfacl -m d:u:user3:rwx /project/alpha
setfacl -m d:u:user4:rx /project/alpha

# 4. 验证
getfacl /project/alpha
```

### 案例2：日志目录

```bash
# 需求：
# - 应用程序可以写入日志
# - 运维人员可以读取日志
# - 其他人无权限

# 1. 创建目录
mkdir /var/log/myapp
chown appuser:appgroup /var/log/myapp
chmod 700 /var/log/myapp

# 2. 给运维组设置只读 ACL
setfacl -m g:ops:rx /var/log/myapp
setfacl -m d:g:ops:rx /var/log/myapp

# 3. 验证
getfacl /var/log/myapp
```

### 案例3：共享文件

```bash
# 需求：多个用户需要访问同一个文件

# 设置 ACL
setfacl -m u:user1:rw file.txt
setfacl -m u:user2:rw file.txt
setfacl -m u:user3:r file.txt
setfacl -m u:user4:r file.txt

# 查看
getfacl file.txt
```

---

## 七、ACL 与传统权限的关系

### 权限检查顺序

```
1. 检查是否是文件所有者
   └─ 是 → 使用所有者权限

2. 检查是否有用户 ACL
   └─ 是 → 使用用户 ACL & mask

3. 检查是否在所属组或有组 ACL
   └─ 是 → 使用组权限/组 ACL & mask

4. 使用其他人权限
```

### chmod 对 ACL 的影响

```bash
# 设置 ACL
setfacl -m u:user2:rwx file.txt

# 使用 chmod
chmod 644 file.txt

# 结果：
# - 所有者权限变为 rw-
# - 所属组权限变为 r--
# - mask 变为 r--
# - user2 的 ACL 仍是 rwx，但实际权限受 mask 限制变为 r--
```

---

## 八、ACL 最佳实践

### 1. 优先使用组管理

```bash
# 不推荐：给每个用户单独设置 ACL
setfacl -m u:user1:rw file.txt
setfacl -m u:user2:rw file.txt
setfacl -m u:user3:rw file.txt

# 推荐：创建组，使用组 ACL
groupadd developers
gpasswd -a user1 developers
gpasswd -a user2 developers
gpasswd -a user3 developers
setfacl -m g:developers:rw file.txt
```

### 2. 使用默认 ACL

```bash
# 对目录设置默认 ACL，新文件自动继承
setfacl -m d:u:user2:rwx /data/project
```

### 3. 定期审计 ACL

```bash
# 查找有 ACL 的文件
find /data -type f -exec ls -l {} \; | grep "+"

# 查看所有 ACL
find /data -type f -exec getfacl {} \;
```

### 4. 备份 ACL

```bash
# 定期备份
getfacl -R /data > /backup/acl_$(date +%Y%m%d).txt
```

---

## 九、ACL 限制

### 1. 文件系统支持

```bash
# 检查文件系统是否支持 ACL
mount | grep acl

# 如果不支持，需要重新挂载
mount -o remount,acl /dev/sda1

# 永久启用（编辑 /etc/fstab）
/dev/sda1  /data  ext4  defaults,acl  0  0
```

### 2. 备份工具支持

```bash
# tar 需要特殊选项才能保留 ACL
tar --acls -czf backup.tar.gz /data

# rsync 需要 -A 选项
rsync -avA /source/ /dest/

# cp 需要 -a 或 --preserve=all
cp -a file1 file2
```

---

## 练习题

1. 如何给 user2 单独设置文件的读写权限？
2. 默认 ACL 有什么作用？
3. mask 的作用是什么？

<details>
<summary>答案</summary>

1. `setfacl -m u:user2:rw filename`
2. 默认 ACL 作用于目录，在该目录中创建的新文件会自动继承默认 ACL
3. mask 定义了用户和组 ACL 的最大有效权限，实际权限 = ACL 权限 & mask

</details>
