# Rsync 基础与安装

## 什么是 Rsync？

**Rsync（Remote Sync，远程同步）** 是一个快速、多功能的文件同步工具，可以在本地和远程系统之间高效地同步文件和目录。

### Rsync 的特点

✅ **增量传输**：只传输变化的部分，节省带宽  
✅ **断点续传**：支持中断后继续传输  
✅ **保持属性**：可以保持文件权限、时间戳、所有者等  
✅ **压缩传输**：支持传输时压缩，提高速度  
✅ **安全传输**：支持 SSH 加密传输  
✅ **灵活过滤**：支持包含/排除文件规则  

### Rsync 的应用场景

1. **数据备份**：定期备份服务器数据
2. **网站同步**：同步 Web 服务器内容
3. **镜像站点**：创建镜像服务器
4. **代码部署**：部署应用程序代码
5. **数据迁移**：服务器数据迁移
6. **实时同步**：配合 inotify 实现实时同步

---

## Rsync 工作原理

### 增量传输算法

Rsync 使用独特的增量传输算法，只传输文件的差异部分：

```
源端                                目标端
┌─────────────┐                  ┌─────────────┐
│  文件 A     │                  │  文件 A'    │
│  (新版本)   │                  │  (旧版本)   │
└─────────────┘                  └─────────────┘
       │                                │
       │  1. 目标端生成校验和           │
       │ ←──────────────────────────── │
       │                                │
       │  2. 源端比对差异               │
       │                                │
       │  3. 只传输差异部分             │
       │ ──────────────────────────→   │
       │                                │
       ▼                                ▼
   传输完成                         文件更新
```

### 工作流程

1. **建立连接**：源端和目标端建立连接
2. **生成文件列表**：扫描需要同步的文件
3. **计算校验和**：目标端计算现有文件的校验和
4. **比对差异**：源端比对文件差异
5. **传输数据**：只传输变化的部分
6. **更新文件**：目标端更新文件

---

## Rsync 工作模式

### 1. 本地模式

在同一台机器上复制文件：

```bash
rsync [选项] 源路径 目标路径
```

**示例**：
```bash
# 复制目录
rsync -av /data/source/ /data/backup/
```

### 2. 远程 Shell 模式（SSH）

通过 SSH 在不同机器间同步：

```bash
# 推送到远程
rsync [选项] 源路径 用户@主机:目标路径

# 从远程拉取
rsync [选项] 用户@主机:源路径 目标路径
```

**示例**：
```bash
# 推送到远程服务器
rsync -avz /data/web/ root@192.168.1.10:/var/www/

# 从远程服务器拉取
rsync -avz root@192.168.1.10:/data/backup/ /backup/
```

### 3. Rsync 守护进程模式

Rsync 作为服务运行，提供更高性能：

```bash
# 推送到 Rsync 服务器
rsync [选项] 源路径 rsync://用户@主机/模块名

# 从 Rsync 服务器拉取
rsync [选项] rsync://用户@主机/模块名 目标路径
```

**示例**：
```bash
# 推送到 Rsync 服务器
rsync -avz /data/web/ rsync://backup@192.168.1.10/webdata

# 从 Rsync 服务器拉取
rsync -avz rsync://backup@192.168.1.10/webdata /backup/
```

---

## 安装 Rsync

### CentOS/RHEL

```bash
# 安装 Rsync
yum install -y rsync

# 查看版本
rsync --version

# 输出示例
rsync  version 3.1.2  protocol version 31
```

### Ubuntu/Debian

```bash
# 安装 Rsync
apt update
apt install -y rsync

# 查看版本
rsync --version
```

### 验证安装

```bash
# 查看 Rsync 命令
which rsync

# 输出
/usr/bin/rsync

# 查看帮助
rsync --help
man rsync
```

---

## Rsync 基本选项

### 常用选项

| 选项 | 说明 | 推荐 |
|------|------|------|
| `-a` | 归档模式（等于 -rlptgoD） | ✅ 必用 |
| `-v` | 显示详细信息 | ✅ 推荐 |
| `-z` | 压缩传输 | ✅ 远程传输推荐 |
| `-r` | 递归复制目录 | - |
| `-l` | 保留符号链接 | - |
| `-p` | 保留权限 | - |
| `-t` | 保留时间戳 | - |
| `-g` | 保留组 | - |
| `-o` | 保留所有者 | - |
| `-D` | 保留设备文件 | - |

### 其他常用选项

| 选项 | 说明 |
|------|------|
| `-h` | 人类可读的输出 |
| `-n` | 模拟运行（不实际执行） |
| `--delete` | 删除目标端多余文件 |
| `--exclude` | 排除文件 |
| `--include` | 包含文件 |
| `--progress` | 显示传输进度 |
| `--stats` | 显示传输统计 |
| `-e` | 指定远程 shell |
| `--bwlimit` | 限制带宽 |

### 组合选项

```bash
# -a：归档模式（最常用）
# 等价于：-rlptgoD
rsync -a source/ dest/

# -av：归档 + 详细输出
rsync -av source/ dest/

# -avz：归档 + 详细 + 压缩（远程传输推荐）
rsync -avz source/ dest/

# -avzP：归档 + 详细 + 压缩 + 进度
# -P 等价于 --partial --progress
rsync -avzP source/ dest/
```

---

## 基本使用示例

### 1. 本地复制

```bash
# 复制目录（保留尾部斜杠）
rsync -av /data/source/ /data/backup/

# 复制目录本身（不带尾部斜杠）
rsync -av /data/source /data/backup/

# 显示进度
rsync -avP /data/source/ /data/backup/
```

**注意**：尾部斜杠的区别
- `/data/source/`：复制目录内容到目标
- `/data/source`：复制目录本身到目标

### 2. 远程推送

```bash
# 推送到远程服务器
rsync -avz /data/web/ root@192.168.1.10:/var/www/

# 指定 SSH 端口
rsync -avz -e "ssh -p 2222" /data/web/ root@192.168.1.10:/var/www/

# 显示进度
rsync -avzP /data/web/ root@192.168.1.10:/var/www/
```

### 3. 远程拉取

```bash
# 从远程服务器拉取
rsync -avz root@192.168.1.10:/data/backup/ /backup/

# 拉取多个目录
rsync -avz root@192.168.1.10:'/data/backup1/ /data/backup2/' /backup/
```

### 4. 模拟运行

```bash
# 模拟运行，查看会同步哪些文件（不实际执行）
rsync -avzn /data/source/ /data/backup/

# 输出示例
sending incremental file list
file1.txt
file2.txt
dir1/
dir1/file3.txt

sent 234 bytes  received 20 bytes  508.00 bytes/sec
total size is 1,234  speedup is 4.86 (DRY RUN)
```

### 5. 删除目标端多余文件

```bash
# 使目标端和源端完全一致（删除目标端多余文件）
rsync -av --delete /data/source/ /data/backup/
```

**警告**：`--delete` 会删除目标端多余的文件，使用前请确认！

---

## 排除和包含文件

### 排除文件

```bash
# 排除单个文件
rsync -av --exclude='file.txt' /data/source/ /data/backup/

# 排除多个文件
rsync -av --exclude='*.log' --exclude='*.tmp' /data/source/ /data/backup/

# 排除目录
rsync -av --exclude='cache/' --exclude='logs/' /data/source/ /data/backup/

# 排除多种模式
rsync -av \
  --exclude='*.log' \
  --exclude='*.tmp' \
  --exclude='cache/' \
  --exclude='.git/' \
  /data/source/ /data/backup/
```

### 使用排除文件

创建 `exclude.txt`：

```
*.log
*.tmp
cache/
.git/
node_modules/
```

使用排除文件：

```bash
rsync -av --exclude-from='exclude.txt' /data/source/ /data/backup/
```

### 包含文件

```bash
# 只包含特定文件
rsync -av --include='*.txt' --exclude='*' /data/source/ /data/backup/

# 包含特定目录
rsync -av --include='important/' --exclude='*' /data/source/ /data/backup/
```

---

## 限制带宽

```bash
# 限制带宽为 1000 KB/s
rsync -avz --bwlimit=1000 /data/source/ root@192.168.1.10:/data/backup/

# 限制带宽为 10 MB/s
rsync -avz --bwlimit=10000 /data/source/ root@192.168.1.10:/data/backup/
```

---

## 查看传输统计

```bash
# 显示传输统计信息
rsync -av --stats /data/source/ /data/backup/

# 输出示例
Number of files: 1,234 (reg: 1,000, dir: 234)
Number of created files: 10
Number of deleted files: 0
Number of regular files transferred: 10
Total file size: 1.23G bytes
Total transferred file size: 123.45M bytes
Literal data: 123.45M bytes
Matched data: 0 bytes
File list size: 12.34K
Total bytes sent: 123.46M
Total bytes received: 234

sent 123.46M bytes  received 234 bytes  8.23M bytes/sec
total size is 1.23G  speedup is 9.96
```

---

## 实战练习

### 练习 1：本地目录同步

```bash
# 1. 创建测试目录
mkdir -p /tmp/source /tmp/backup

# 2. 创建测试文件
echo "file1" > /tmp/source/file1.txt
echo "file2" > /tmp/source/file2.txt
mkdir /tmp/source/dir1
echo "file3" > /tmp/source/dir1/file3.txt

# 3. 同步目录
rsync -av /tmp/source/ /tmp/backup/

# 4. 验证
ls -la /tmp/backup/

# 5. 修改文件后再次同步
echo "updated" >> /tmp/source/file1.txt
rsync -av /tmp/source/ /tmp/backup/
```

### 练习 2：远程同步（需要两台服务器）

```bash
# 1. 推送到远程服务器
rsync -avz /data/web/ root@192.168.1.10:/var/www/

# 2. 从远程服务器拉取
rsync -avz root@192.168.1.10:/data/backup/ /backup/

# 3. 使用 SSH 密钥（免密码）
ssh-keygen -t rsa
ssh-copy-id root@192.168.1.10
rsync -avz /data/web/ root@192.168.1.10:/var/www/
```

### 练习 3：排除文件

```bash
# 1. 创建测试文件
mkdir -p /tmp/test
touch /tmp/test/file1.txt
touch /tmp/test/file2.log
touch /tmp/test/file3.tmp
mkdir /tmp/test/cache

# 2. 同步时排除日志和临时文件
rsync -av --exclude='*.log' --exclude='*.tmp' --exclude='cache/' \
  /tmp/test/ /tmp/backup/

# 3. 验证（只有 file1.txt 被同步）
ls /tmp/backup/
```

---

## 常见问题

### 1. 尾部斜杠的区别

```bash
# 有斜杠：复制目录内容
rsync -av /data/source/ /data/backup/
# 结果：/data/backup/file1.txt

# 无斜杠：复制目录本身
rsync -av /data/source /data/backup/
# 结果：/data/backup/source/file1.txt
```

### 2. 权限问题

**现象**：`rsync: failed to set permissions`

**解决**：
```bash
# 不保留权限
rsync -rltvz /data/source/ /data/backup/

# 或使用 --no-perms
rsync -av --no-perms /data/source/ /data/backup/
```

### 3. SSH 连接问题

**现象**：`ssh: connect to host 192.168.1.10 port 22: Connection refused`

**解决**：
```bash
# 检查 SSH 服务
systemctl status sshd

# 指定 SSH 端口
rsync -avz -e "ssh -p 2222" /data/source/ root@192.168.1.10:/data/backup/
```

---

## 小结

本节学习了：

✅ Rsync 的概念和特点  
✅ Rsync 的工作原理和模式  
✅ 如何安装 Rsync  
✅ Rsync 的基本选项和使用  
✅ 如何排除和包含文件  
✅ 如何限制带宽和查看统计  

下一节将学习 Rsync 的高级用法和守护进程模式。

---

## 扩展阅读

- [Rsync 官方文档](https://rsync.samba.org/)
- [Rsync 算法详解](https://rsync.samba.org/tech_report/)
- [Rsync 最佳实践](https://wiki.archlinux.org/title/Rsync)
