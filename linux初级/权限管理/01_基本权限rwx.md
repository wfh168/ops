# 基本权限 rwx

## 权限概述

Linux 通过权限控制用户对文件和目录的访问。

```
-rw-r--r-- 1 root root 1024 Jan 7 10:00 file.txt
 │││││││││
 │││││││└┴── 其他用户权限 (other)
 │││││└┴──── 所属组权限 (group)
 │││└┴────── 所有者权限 (owner/user)
 │└───────── 文件类型
 └────────── 权限位
```

---

## 一、权限类型

### 三种权限

| 权限 | 符号 | 数字 | 对文件的作用 | 对目录的作用 |
|------|------|------|-------------|-------------|
| 读 | r | 4 | 查看文件内容 | 列出目录内容（ls） |
| 写 | w | 2 | 修改文件内容 | 创建/删除文件 |
| 执行 | x | 1 | 执行文件 | 进入目录（cd） |
| 无 | - | 0 | 无权限 | 无权限 |

### 三类用户

| 用户类型 | 说明 | 符号 |
|---------|------|------|
| 所有者 | 文件的拥有者 | u (user) |
| 所属组 | 文件所属组的成员 | g (group) |
| 其他人 | 既不是所有者也不在所属组 | o (other) |
| 所有人 | 以上三类的总和 | a (all) |

---

## 二、权限对文件的影响

### r - 读权限

```bash
# 有 r 权限
cat file.txt                      # ✅ 可以查看
less file.txt                     # ✅ 可以查看
cp file.txt backup.txt            # ✅ 可以复制

# 无 r 权限
cat file.txt                      # ❌ Permission denied
```

### w - 写权限

```bash
# 有 w 权限
echo "new content" > file.txt     # ✅ 可以修改
rm file.txt                       # ⚠️ 取决于目录权限！

# 无 w 权限
echo "new content" > file.txt     # ❌ Permission denied
```

⚠️ 注意：删除文件取决于目录的 w 权限，而非文件本身！

### x - 执行权限

```bash
# 有 x 权限
./script.sh                       # ✅ 可以执行
/bin/ls                           # ✅ 可以执行

# 无 x 权限
./script.sh                       # ❌ Permission denied
bash script.sh                    # ✅ 可以（通过解释器执行）
```

---

## 三、权限对目录的影响

### r - 读权限

```bash
# 有 r 权限
ls /dir                           # ✅ 可以列出文件名
ls -l /dir                        # ⚠️ 需要 x 权限才能看详情

# 无 r 权限
ls /dir                           # ❌ Permission denied
```

### w - 写权限

```bash
# 有 w 权限（还需要 x 权限）
touch /dir/newfile                # ✅ 可以创建文件
rm /dir/file                      # ✅ 可以删除文件
mkdir /dir/subdir                 # ✅ 可以创建子目录

# 无 w 权限
touch /dir/newfile                # ❌ Permission denied
```

⚠️ 目录的 w 权限决定能否在目录中创建/删除文件！

### x - 执行权限（最重要！）

```bash
# 有 x 权限
cd /dir                           # ✅ 可以进入
cat /dir/file                     # ✅ 可以访问文件
ls -l /dir                        # ✅ 可以查看详情

# 无 x 权限
cd /dir                           # ❌ Permission denied
cat /dir/file                     # ❌ Permission denied
ls /dir                           # ⚠️ 只能看文件名，看不到详情
```

⚠️ 目录的 x 权限是访问目录内容的前提！

### 目录权限组合

| 权限 | 效果 |
|------|------|
| r-- | 只能 ls 看文件名，无法进入或查看详情 |
| -w- | 无意义（需要 x 才能进入） |
| --x | 可以进入，但看不到文件列表 |
| r-x | 可以进入，可以列出文件（常用） |
| rw- | 无意义（需要 x 才能进入） |
| rwx | 完全控制（常用） |

---

## 四、权限表示方法

### 符号表示

```bash
rwxr-xr-x
│││││││││
│││││││└┴── 其他人：r-x (读+执行)
│││││└┴──── 所属组：r-x (读+执行)
│││└┴────── 所有者：rwx (读+写+执行)
```

### 数字表示

```bash
# 权限转数字
r = 4
w = 2
x = 1
- = 0

# 计算
rwx = 4+2+1 = 7
rw- = 4+2+0 = 6
r-x = 4+0+1 = 5
r-- = 4+0+0 = 4
-wx = 0+2+1 = 3
-w- = 0+2+0 = 2
--x = 0+0+1 = 1
--- = 0+0+0 = 0
```

### 常见权限组合

| 数字 | 符号 | 说明 | 适用 |
|------|------|------|------|
| 777 | rwxrwxrwx | 完全开放（危险！） | 临时测试 |
| 755 | rwxr-xr-x | 所有者全权，其他人只读执行 | 目录、可执行文件 |
| 644 | rw-r--r-- | 所有者读写，其他人只读 | 普通文件 |
| 600 | rw------- | 只有所有者可读写 | 私密文件 |
| 700 | rwx------ | 只有所有者可访问 | 私密目录 |
| 666 | rw-rw-rw- | 所有人可读写（不推荐） | 特殊场景 |
| 444 | r--r--r-- | 所有人只读 | 只读文件 |

---

## 五、chmod - 修改权限

### 数字模式（推荐）

```bash
chmod 755 file.txt                # rwxr-xr-x
chmod 644 file.txt                # rw-r--r--
chmod 600 file.txt                # rw-------
chmod 777 file.txt                # rwxrwxrwx（危险！）

# 递归修改
chmod -R 755 /data/www            # 修改目录及其所有内容
```

### 符号模式

```bash
# 基本语法
chmod [ugoa][+-=][rwx] file

# u=user, g=group, o=other, a=all
# +=添加, -=删除, ==设置

# 示例
chmod u+x file.sh                 # 所有者添加执行权限
chmod g-w file.txt                # 所属组删除写权限
chmod o=r file.txt                # 其他人设置为只读
chmod a+x file.sh                 # 所有人添加执行权限
chmod u+rw,g+r,o-rwx file.txt     # 组合操作

# 递归修改
chmod -R u+w /data                # 递归添加所有者写权限
```

### 参考模式

```bash
# 使文件权限与另一个文件相同
chmod --reference=ref_file target_file
```

---

## 六、chown - 修改所有者

```bash
# 修改所有者
chown newowner file.txt

# 修改所有者和所属组
chown newowner:newgroup file.txt
chown newowner.newgroup file.txt  # 另一种写法

# 只修改所属组
chown :newgroup file.txt

# 递归修改
chown -R user:group /data/www

# 参考模式
chown --reference=ref_file target_file
```

---

## 七、chgrp - 修改所属组

```bash
# 修改所属组
chgrp newgroup file.txt

# 递归修改
chgrp -R newgroup /data/www

# 参考模式
chgrp --reference=ref_file target_file
```

---

## 八、实战案例

### 案例1：配置 Web 目录

```bash
# 创建目录
mkdir -p /var/www/html

# 设置所有者
chown -R www-data:www-data /var/www/html

# 设置权限
chmod -R 755 /var/www/html        # 目录和可执行文件
find /var/www/html -type f -exec chmod 644 {} \;  # 普通文件
find /var/www/html -type d -exec chmod 755 {} \;  # 目录
```

### 案例2：保护敏感文件

```bash
# SSH 私钥
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 700 ~/.ssh

# 配置文件
chmod 600 /etc/my.cnf
chmod 640 /etc/shadow
```

### 案例3：共享目录

```bash
# 创建共享目录
mkdir /data/shared
chgrp developers /data/shared
chmod 2775 /data/shared           # 2=SGID，后面会讲

# 现在 developers 组成员都可以读写
```

### 案例4：脚本文件

```bash
# 创建脚本
cat > script.sh << 'EOF'
#!/bin/bash
echo "Hello World"
EOF

# 添加执行权限
chmod +x script.sh
# 或
chmod 755 script.sh

# 执行
./script.sh
```

---

## 九、权限检查流程

```
用户访问文件
    │
    ▼
是文件所有者？
    │
    ├─ 是 → 检查所有者权限 (u)
    │
    └─ 否 → 在文件所属组？
            │
            ├─ 是 → 检查所属组权限 (g)
            │
            └─ 否 → 检查其他人权限 (o)
```

⚠️ 注意：即使你在所属组中，如果你是所有者，也只看所有者权限！

---

## 十、常见问题

### 1. 为什么有 w 权限还是删不了文件？

```bash
# 删除文件取决于目录的 w 权限
ls -ld /dir                       # 检查目录权限
chmod u+w /dir                    # 给目录添加写权限
```

### 2. 为什么 ls 能看到文件名但看不到详情？

```bash
# 需要目录的 x 权限
chmod u+x /dir
```

### 3. 如何让脚本可执行？

```bash
chmod +x script.sh
# 或
chmod 755 script.sh
```

---

## 练习题

1. 权限 rwxr-x--- 对应的数字是多少？
2. 如何让一个文件只有所有者可以读写，其他人完全无权限？
3. 目录的 x 权限有什么作用？

<details>
<summary>答案</summary>

1. 750 (rwx=7, r-x=5, ---=0)
2. `chmod 600 filename`
3. x 权限允许进入目录，是访问目录内容的前提，没有 x 权限就无法 cd 进入或访问目录中的文件

</details>
