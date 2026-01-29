# Rsync 实时同步

## 什么是实时同步？

**实时同步（Real-time Sync）** 是指当源目录发生变化时，立即自动同步到目标目录，而不是定时同步。

### 为什么需要实时同步？

传统的定时同步（cron）存在以下问题：

❌ **延迟高**：最快也要 1 分钟的延迟  
❌ **资源浪费**：即使没有变化也要扫描  
❌ **不够实时**：无法满足实时性要求高的场景  

实时同步的优势：

✅ **零延迟**：文件变化后立即同步  
✅ **节省资源**：只在有变化时才同步  
✅ **高效**：只同步变化的文件  

### 应用场景

1. **Web 服务器集群**：主服务器内容实时同步到从服务器
2. **代码发布**：代码更新后立即部署
3. **数据备份**：重要数据实时备份
4. **日志收集**：日志文件实时收集
5. **文件共享**：多服务器文件实时共享

---

## inotify 简介

### 什么是 inotify？

**inotify** 是 Linux 内核提供的文件系统事件监控机制，可以监控文件和目录的变化。

### inotify 支持的事件

| 事件 | 说明 |
|------|------|
| `IN_ACCESS` | 文件被访问 |
| `IN_MODIFY` | 文件被修改 |
| `IN_ATTRIB` | 文件属性被修改 |
| `IN_CLOSE_WRITE` | 可写文件被关闭 |
| `IN_CLOSE_NOWRITE` | 只读文件被关闭 |
| `IN_OPEN` | 文件被打开 |
| `IN_MOVED_FROM` | 文件被移出 |
| `IN_MOVED_TO` | 文件被移入 |
| `IN_CREATE` | 文件被创建 |
| `IN_DELETE` | 文件被删除 |
| `IN_DELETE_SELF` | 监控的目录被删除 |

### 检查内核支持

```bash
# 检查内核是否支持 inotify
ls -l /proc/sys/fs/inotify/

# 输出示例
-rw-r--r-- 1 root root 0 Jan 29 10:00 max_queued_events
-rw-r--r-- 1 root root 0 Jan 29 10:00 max_user_instances
-rw-r--r-- 1 root root 0 Jan 29 10:00 max_user_watches

# 查看当前限制
cat /proc/sys/fs/inotify/max_user_watches
# 默认值：8192
```

---

## inotify-tools 安装

### CentOS/RHEL

```bash
# 安装 EPEL 源
yum install -y epel-release

# 安装 inotify-tools
yum install -y inotify-tools

# 验证安装
inotifywait --help
inotifywatch --help
```

### Ubuntu/Debian

```bash
# 安装 inotify-tools
apt update
apt install -y inotify-tools

# 验证安装
inotifywait --version
```

### 编译安装（可选）

```bash
# 下载源码
wget https://github.com/inotify-tools/inotify-tools/archive/refs/tags/3.22.6.0.tar.gz
tar -zxvf 3.22.6.0.tar.gz
cd inotify-tools-3.22.6.0

# 编译安装
./autogen.sh
./configure --prefix=/usr/local/inotify
make && make install

# 添加到 PATH
echo 'export PATH=/usr/local/inotify/bin:$PATH' >> /etc/profile
source /etc/profile
```

---

## inotifywait 命令

### 基本用法

```bash
# 监控单个文件
inotifywait /tmp/test.txt

# 监控目录
inotifywait /data/web/

# 递归监控目录
inotifywait -r /data/web/

# 持续监控
inotifywait -m /data/web/
```

### 常用选项

| 选项 | 说明 |
|------|------|
| `-m` | 持续监控（不退出） |
| `-r` | 递归监控子目录 |
| `-q` | 安静模式（减少输出） |
| `-e` | 指定监控的事件 |
| `--exclude` | 排除文件或目录 |
| `--format` | 自定义输出格式 |
| `--timefmt` | 时间格式 |

### 监控特定事件

```bash
# 监控文件修改
inotifywait -m -e modify /data/web/

# 监控文件创建和删除
inotifywait -m -e create,delete /data/web/

# 监控文件关闭（写入完成）
inotifywait -m -e close_write /data/web/

# 监控多个事件
inotifywait -m -e modify,create,delete,move /data/web/
```

### 自定义输出格式

```bash
# 自定义输出格式
inotifywait -m -r --timefmt '%Y-%m-%d %H:%M:%S' \
  --format '%T %w%f %e' \
  -e modify,create,delete /data/web/

# 输出示例
2024-01-29 10:30:15 /data/web/index.html MODIFY
2024-01-29 10:30:20 /data/web/new.txt CREATE
2024-01-29 10:30:25 /data/web/old.txt DELETE
```

### 排除文件

```bash
# 排除日志文件
inotifywait -m -r --exclude '\.log$' /data/web/

# 排除多个模式
inotifywait -m -r --exclude '(\.log$|\.tmp$|\.swp$)' /data/web/

# 排除目录
inotifywait -m -r --exclude '/cache/' /data/web/
```

---

## 实时同步脚本

### 基本实时同步脚本

```bash
#!/bin/bash

# 源目录
SRC_DIR="/data/web/"

# 目标服务器和目录
DEST_USER="root"
DEST_HOST="192.168.1.10"
DEST_DIR="/var/www/html/"

# 监控并同步
inotifywait -mrq -e modify,create,delete,move $SRC_DIR | while read path action file
do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $path$file - $action"
    rsync -avz --delete $SRC_DIR ${DEST_USER}@${DEST_HOST}:${DEST_DIR}
done
```

### 优化版实时同步脚本

```bash
#!/bin/bash

# 配置变量
SRC_DIR="/data/web/"
DEST_USER="root"
DEST_HOST="192.168.1.10"
DEST_DIR="/var/www/html/"
LOG_FILE="/var/log/rsync_realtime.log"
EXCLUDE_FILE="/etc/rsync_exclude.txt"

# 检查源目录
if [ ! -d "$SRC_DIR" ]; then
    echo "源目录不存在: $SRC_DIR" | tee -a $LOG_FILE
    exit 1
fi

# 初始化同步
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始初始化同步" | tee -a $LOG_FILE
rsync -avz --delete --exclude-from=$EXCLUDE_FILE \
    $SRC_DIR ${DEST_USER}@${DEST_HOST}:${DEST_DIR} >> $LOG_FILE 2>&1

# 实时监控并同步
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始实时监控" | tee -a $LOG_FILE
inotifywait -mrq --timefmt '%Y-%m-%d %H:%M:%S' \
    --format '%T %w%f %e' \
    --exclude '(\.log$|\.tmp$|\.swp$|/cache/)' \
    -e modify,create,delete,move,attrib \
    $SRC_DIR | while read datetime filepath event
do
    echo "$datetime - $filepath - $event" >> $LOG_FILE
    
    # 延迟 1 秒，避免频繁同步
    sleep 1
    
    # 执行同步
    rsync -avz --delete --exclude-from=$EXCLUDE_FILE \
        $SRC_DIR ${DEST_USER}@${DEST_HOST}:${DEST_DIR} >> $LOG_FILE 2>&1
    
    if [ $? -eq 0 ]; then
        echo "$datetime - 同步成功" >> $LOG_FILE
    else
        echo "$datetime - 同步失败" >> $LOG_FILE
    fi
done
```

创建排除文件 `/etc/rsync_exclude.txt`：

```
*.log
*.tmp
*.swp
.git/
cache/
temp/
```

### 守护进程模式实时同步脚本

```bash
#!/bin/bash

# 配置变量
SRC_DIR="/data/web/"
DEST_HOST="192.168.1.10"
DEST_MODULE="webdata"
DEST_USER="webuser"
PASSWORD_FILE="/etc/rsync.password"
LOG_FILE="/var/log/rsync_realtime.log"

# 初始化同步
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始初始化同步" | tee -a $LOG_FILE
rsync -avz --delete --password-file=$PASSWORD_FILE \
    $SRC_DIR rsync://${DEST_USER}@${DEST_HOST}/${DEST_MODULE}/ >> $LOG_FILE 2>&1

# 实时监控并同步
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始实时监控" | tee -a $LOG_FILE
inotifywait -mrq --timefmt '%Y-%m-%d %H:%M:%S' \
    --format '%T %w%f %e' \
    -e modify,create,delete,move \
    $SRC_DIR | while read datetime filepath event
do
    echo "$datetime - $filepath - $event" >> $LOG_FILE
    
    sleep 1
    
    rsync -avz --delete --password-file=$PASSWORD_FILE \
        $SRC_DIR rsync://${DEST_USER}@${DEST_HOST}/${DEST_MODULE}/ >> $LOG_FILE 2>&1
    
    if [ $? -eq 0 ]; then
        echo "$datetime - 同步成功" >> $LOG_FILE
    else
        echo "$datetime - 同步失败" >> $LOG_FILE
    fi
done
```

---

## 配置为系统服务

### 创建 systemd 服务

创建服务文件 `/etc/systemd/system/rsync-realtime.service`：

```ini
[Unit]
Description=Rsync Real-time Sync Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/rsync_realtime.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

将脚本放到 `/usr/local/bin/rsync_realtime.sh` 并设置权限：

```bash
chmod +x /usr/local/bin/rsync_realtime.sh
```

启动服务：

```bash
# 重载 systemd
systemctl daemon-reload

# 启动服务
systemctl start rsync-realtime

# 设置开机自启
systemctl enable rsync-realtime

# 查看状态
systemctl status rsync-realtime

# 查看日志
journalctl -u rsync-realtime -f
```

---

## 性能优化

### 1. 调整 inotify 参数

```bash
# 增加监控文件数量限制
echo 524288 > /proc/sys/fs/inotify/max_user_watches

# 永久生效
vim /etc/sysctl.conf
fs.inotify.max_user_watches = 524288
fs.inotify.max_queued_events = 32768
fs.inotify.max_user_instances = 1024

# 使配置生效
sysctl -p
```

### 2. 批量同步

避免每次变化都同步，可以收集一段时间的变化后批量同步：

```bash
#!/bin/bash

SRC_DIR="/data/web/"
DEST="root@192.168.1.10:/var/www/html/"
SYNC_INTERVAL=5  # 5 秒同步一次
NEED_SYNC=0

# 监控文件变化
inotifywait -mrq -e modify,create,delete,move $SRC_DIR | while read line
do
    NEED_SYNC=1
done &

# 定时同步
while true
do
    if [ $NEED_SYNC -eq 1 ]; then
        echo "$(date) - 开始同步"
        rsync -avz --delete $SRC_DIR $DEST
        NEED_SYNC=0
    fi
    sleep $SYNC_INTERVAL
done
```

### 3. 只同步变化的文件

```bash
#!/bin/bash

SRC_DIR="/data/web/"
DEST="root@192.168.1.10:/var/www/html/"

inotifywait -mrq --format '%w%f' -e modify,create,delete,move $SRC_DIR | while read file
do
    echo "$(date) - 同步文件: $file"
    rsync -avz "$file" $DEST
done
```

---

## 实战案例

### 案例 1：Web 服务器集群实时同步

**场景**：主 Web 服务器内容实时同步到 2 台从服务器

**主服务器配置**：

```bash
# 1. 安装 inotify-tools
yum install -y inotify-tools

# 2. 配置 SSH 免密登录
ssh-keygen -t rsa
ssh-copy-id root@192.168.1.11
ssh-copy-id root@192.168.1.12

# 3. 创建同步脚本
vim /usr/local/bin/web_sync.sh
```

```bash
#!/bin/bash

SRC_DIR="/var/www/html/"
DEST_SERVERS=("192.168.1.11" "192.168.1.12")
DEST_DIR="/var/www/html/"
LOG_FILE="/var/log/web_sync.log"

# 初始化同步
for server in "${DEST_SERVERS[@]}"
do
    echo "$(date) - 初始化同步到 $server" | tee -a $LOG_FILE
    rsync -avz --delete $SRC_DIR root@$server:$DEST_DIR >> $LOG_FILE 2>&1
done

# 实时监控并同步
inotifywait -mrq -e modify,create,delete,move $SRC_DIR | while read path action file
do
    echo "$(date) - $path$file - $action" >> $LOG_FILE
    
    for server in "${DEST_SERVERS[@]}"
    do
        rsync -avz --delete $SRC_DIR root@$server:$DEST_DIR >> $LOG_FILE 2>&1
    done
done
```

```bash
# 4. 设置权限
chmod +x /usr/local/bin/web_sync.sh

# 5. 配置为系统服务
vim /etc/systemd/system/web-sync.service
```

```ini
[Unit]
Description=Web Real-time Sync Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/web_sync.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
# 6. 启动服务
systemctl daemon-reload
systemctl start web-sync
systemctl enable web-sync
```

### 案例 2：代码自动部署

**场景**：开发服务器代码变化后自动部署到测试服务器

**开发服务器配置**：

```bash
# 创建部署脚本
vim /usr/local/bin/auto_deploy.sh
```

```bash
#!/bin/bash

SRC_DIR="/data/code/myapp/"
DEST_HOST="192.168.1.20"
DEST_DIR="/var/www/myapp/"
LOG_FILE="/var/log/auto_deploy.log"

# 排除文件
EXCLUDE=(
    ".git/"
    "node_modules/"
    "*.log"
    ".env"
)

# 构建排除参数
EXCLUDE_ARGS=""
for item in "${EXCLUDE[@]}"
do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$item"
done

# 实时监控并部署
inotifywait -mrq -e modify,create,delete,move \
    --exclude '(\.git/|node_modules/|\.log$)' \
    $SRC_DIR | while read path action file
do
    echo "$(date) - 检测到变化: $path$file - $action" | tee -a $LOG_FILE
    
    # 延迟 3 秒，等待文件写入完成
    sleep 3
    
    echo "$(date) - 开始部署" | tee -a $LOG_FILE
    rsync -avz --delete $EXCLUDE_ARGS \
        $SRC_DIR root@$DEST_HOST:$DEST_DIR >> $LOG_FILE 2>&1
    
    if [ $? -eq 0 ]; then
        echo "$(date) - 部署成功" | tee -a $LOG_FILE
        
        # 重启应用（可选）
        ssh root@$DEST_HOST "systemctl restart myapp"
    else
        echo "$(date) - 部署失败" | tee -a $LOG_FILE
    fi
done
```

### 案例 3：数据库备份实时同步

**场景**：数据库备份文件实时同步到备份服务器

```bash
#!/bin/bash

BACKUP_DIR="/data/mysql_backup/"
DEST_HOST="192.168.1.30"
DEST_MODULE="backup"
DEST_USER="backup"
PASSWORD_FILE="/etc/rsync.password"
LOG_FILE="/var/log/backup_sync.log"

# 实时监控备份目录
inotifywait -mrq -e close_write,moved_to $BACKUP_DIR | while read path action file
do
    # 只同步 .sql 和 .tar.gz 文件
    if [[ "$file" =~ \.(sql|tar\.gz)$ ]]; then
        echo "$(date) - 检测到新备份: $file" | tee -a $LOG_FILE
        
        # 同步到备份服务器
        rsync -avz --password-file=$PASSWORD_FILE \
            "${path}${file}" \
            rsync://${DEST_USER}@${DEST_HOST}/${DEST_MODULE}/ >> $LOG_FILE 2>&1
        
        if [ $? -eq 0 ]; then
            echo "$(date) - 备份同步成功: $file" | tee -a $LOG_FILE
        else
            echo "$(date) - 备份同步失败: $file" | tee -a $LOG_FILE
        fi
    fi
done
```

---

## 监控和故障排查

### 查看监控状态

```bash
# 查看 inotify 使用情况
cat /proc/sys/fs/inotify/max_user_watches
cat /proc/sys/fs/inotify/max_queued_events

# 查看当前监控的文件数
find /proc/*/fd -lname anon_inode:inotify 2>/dev/null | wc -l

# 查看服务状态
systemctl status rsync-realtime

# 查看日志
tail -f /var/log/rsync_realtime.log
journalctl -u rsync-realtime -f
```

### 常见问题

#### 1. 监控文件数超限

**现象**：`Failed to watch /data/web; upper limit on inotify watches reached!`

**解决**：
```bash
# 增加监控限制
echo 524288 > /proc/sys/fs/inotify/max_user_watches

# 永久生效
vim /etc/sysctl.conf
fs.inotify.max_user_watches = 524288
sysctl -p
```

#### 2. 同步延迟

**原因**：文件变化太频繁

**解决**：使用批量同步，收集一段时间后再同步

#### 3. CPU 占用高

**原因**：监控的文件太多或变化太频繁

**解决**：
- 排除不需要监控的目录
- 增加同步间隔
- 使用批量同步

---

## 实战练习

### 练习 1：基本实时同步

```bash
# 1. 安装 inotify-tools
yum install -y inotify-tools

# 2. 创建测试目录
mkdir -p /tmp/source /tmp/dest

# 3. 测试 inotifywait
inotifywait -m /tmp/source/

# 4. 在另一个终端创建文件
echo "test" > /tmp/source/test.txt

# 5. 观察 inotifywait 输出
```

### 练习 2：编写实时同步脚本

```bash
# 1. 创建脚本
vim /tmp/sync.sh

#!/bin/bash
SRC="/tmp/source/"
DEST="/tmp/dest/"

inotifywait -mrq -e modify,create,delete $SRC | while read line
do
    echo "$(date) - 同步中..."
    rsync -av --delete $SRC $DEST
done

# 2. 运行脚本
chmod +x /tmp/sync.sh
/tmp/sync.sh &

# 3. 测试
echo "test1" > /tmp/source/file1.txt
echo "test2" > /tmp/source/file2.txt
ls /tmp/dest/
```

### 练习 3：配置为系统服务

```bash
# 1. 将脚本放到系统目录
cp /tmp/sync.sh /usr/local/bin/

# 2. 创建 systemd 服务
vim /etc/systemd/system/sync.service

# 3. 启动服务
systemctl daemon-reload
systemctl start sync
systemctl status sync
```

---

## 小结

本节学习了：

✅ 实时同步的概念和应用场景  
✅ inotify 文件监控机制  
✅ inotify-tools 的安装和使用  
✅ 编写实时同步脚本  
✅ 配置为系统服务  
✅ 性能优化和故障排查  
✅ 实战案例（Web 集群、代码部署、备份同步）  

至此，Rsync 文件同步的学习全部完成！

---

## 扩展阅读

- [inotify 官方文档](https://man7.org/linux/man-pages/man7/inotify.7.html)
- [inotify-tools GitHub](https://github.com/inotify-tools/inotify-tools)
- [Rsync + inotify 最佳实践](https://wiki.archlinux.org/title/Rsync)
