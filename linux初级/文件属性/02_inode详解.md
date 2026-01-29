# inode 详解

## 什么是 inode

inode（索引节点）是 Linux 文件系统中存储文件元信息的数据结构。

```
┌─────────────────────────────────────────────────────────────┐
│                      文件系统结构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   目录文件                  inode 表              数据块     │
│  ┌─────────┐            ┌──────────┐          ┌─────────┐  │
│  │文件名 → │───────────▶│ inode 1  │─────────▶│ 数据... │  │
│  │ inode号 │            │ 权限     │          └─────────┘  │
│  └─────────┘            │ 属主     │                       │
│                         │ 大小     │                       │
│                         │ 时间戳   │                       │
│                         │ 数据指针 │                       │
│                         └──────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

---

## inode 存储的信息

```bash
stat filename                     # 查看文件的 inode 信息
```

```
  File: test.txt
  Size: 1024            Blocks: 8          IO Block: 4096   regular file
Device: fd00h/64768d    Inode: 12345678    Links: 1
Access: (0644/-rw-r--r--)  Uid: ( 0/ root)   Gid: ( 0/ root)
Access: 2024-01-07 10:00:00.000000000 +0800
Modify: 2024-01-07 09:00:00.000000000 +0800
Change: 2024-01-07 09:00:00.000000000 +0800
 Birth: -
```

### inode 包含的内容

| 信息 | 说明 |
|------|------|
| 文件类型 | 普通文件、目录、链接等 |
| 权限 | rwx 权限位 |
| 属主/属组 | UID 和 GID |
| 文件大小 | 字节数 |
| 时间戳 | atime/mtime/ctime |
| 硬链接数 | 指向此 inode 的文件名数量 |
| 数据块指针 | 指向实际数据存储位置 |

### inode 不包含的内容
- 文件名（存储在目录文件中）

---

## 查看 inode

```bash
# 查看文件的 inode 号
ls -i filename
ls -li                            # 列表显示带 inode

# 查看详细 inode 信息
stat filename

# 查看文件系统 inode 使用情况
df -i
```

---

## 三个时间戳

| 时间戳 | 名称 | 更新时机 |
|--------|------|----------|
| atime | Access Time | 读取文件内容时 |
| mtime | Modify Time | 修改文件内容时 |
| ctime | Change Time | 修改文件属性时（权限、属主等） |

```bash
# 查看时间戳
stat file.txt

# 修改时间戳
touch -a file.txt                 # 更新 atime
touch -m file.txt                 # 更新 mtime
touch -d "2024-01-01" file.txt    # 设置指定时间
```

### 时间戳与 find

```bash
find /var -mtime -7               # 7天内修改过的文件
find /var -atime +30              # 30天前访问过的文件
find /var -ctime -1               # 1天内属性变化的文件
```

---

## inode 耗尽问题

### 问题现象
```bash
# 磁盘空间充足但无法创建文件
touch newfile
# touch: cannot touch 'newfile': No space left on device

# 检查 inode 使用
df -i
# Filesystem      Inodes  IUsed   IFree IUse% Mounted on
# /dev/sda1      1000000 1000000      0  100% /
```

### 原因
大量小文件耗尽了 inode，即使磁盘空间还有剩余。

### 解决方法
```bash
# 查找文件数量最多的目录
find / -xdev -type f | cut -d "/" -f 2 | sort | uniq -c | sort -rn

# 查找并删除无用小文件
find /tmp -type f -mtime +30 -delete
```

---

## 硬链接与 inode

```bash
# 创建硬链接
echo "hello" > original.txt
ln original.txt hardlink.txt

# 查看 inode（相同）
ls -li original.txt hardlink.txt
# 12345 -rw-r--r-- 2 root root 6 Jan 7 10:00 hardlink.txt
# 12345 -rw-r--r-- 2 root root 6 Jan 7 10:00 original.txt
#   ^              ^
#   │              └── 硬链接数变为 2
#   └── inode 号相同
```

### 硬链接数的含义
- 普通文件：默认为 1
- 目录：至少为 2（自身 + `.`）
- 每增加一个硬链接，计数 +1
- 计数为 0 时，文件被真正删除

```bash
# 目录的硬链接数
ls -ld /etc
# drwxr-xr-x 77 root root 4096 Jan 7 10:00 /etc
#            ^
#            └── 77 = 1(自身) + 1(.) + 75(子目录的..)
```

---

## 软链接与 inode

```bash
# 创建软链接
ln -s original.txt softlink.txt

# 查看 inode（不同）
ls -li original.txt softlink.txt
# 12345 -rw-r--r-- 1 root root  6 Jan 7 10:00 original.txt
# 12346 lrwxrwxrwx 1 root root 12 Jan 7 10:00 softlink.txt -> original.txt
#   ^                          ^
#   │                          └── 软链接大小 = 目标路径长度
#   └── inode 号不同
```

---

## 删除文件的本质

```
删除文件 = 删除目录中的文件名 → inode 链接数 -1

当链接数 = 0 且没有进程占用时：
  → inode 被释放
  → 数据块被标记为可用
```

### 文件被占用时删除

```bash
# 场景：删除正在被进程使用的日志文件
rm /var/log/app.log               # 文件被删除
ls /var/log/app.log               # 文件不存在

# 但磁盘空间未释放！
df -h                             # 空间没变化

# 查找被删除但仍被占用的文件
lsof | grep deleted

# 解决：重启占用该文件的进程
systemctl restart app
```

---

## 实战技巧

### 通过 inode 删除特殊文件名

```bash
# 文件名包含特殊字符无法删除
ls -i                             # 获取 inode 号
find . -inum 12345 -delete        # 通过 inode 删除
```

### 检查文件系统健康

```bash
# 检查 inode 使用率
df -i

# 检查磁盘使用率
df -h

# 两个都要关注！
```

---

## 练习题

1. 如何查看一个文件的 inode 号？
2. mtime 和 ctime 有什么区别？
3. 为什么删除大文件后磁盘空间没有释放？

<details>
<summary>答案</summary>

1. `ls -i filename` 或 `stat filename`
2. mtime 是文件内容修改时间，ctime 是文件属性（权限、属主等）修改时间
3. 可能有进程仍在使用该文件，用 `lsof | grep deleted` 查找并重启相关进程

</details>
