# crontab 高级用法

## 一、特殊时间字符串

### @reboot - 开机执行

```bash
# 系统启动时执行一次
@reboot /scripts/startup.sh

# 实际应用
@reboot /scripts/mount_nfs.sh
@reboot /scripts/start_services.sh
```

### @yearly / @annually - 每年执行

```bash
# 每年1月1日 00:00 执行
@yearly /scripts/yearly_report.sh

# 等同于
0 0 1 1 * /scripts/yearly_report.sh
```

### @monthly - 每月执行

```bash
# 每月1日 00:00 执行
@monthly /scripts/monthly_cleanup.sh

# 等同于
0 0 1 * * /scripts/monthly_cleanup.sh
```

### @weekly - 每周执行

```bash
# 每周日 00:00 执行
@weekly /scripts/weekly_backup.sh

# 等同于
0 0 * * 0 /scripts/weekly_backup.sh
```

### @daily / @midnight - 每天执行

```bash
# 每天 00:00 执行
@daily /scripts/daily_backup.sh

# 等同于
0 0 * * * /scripts/daily_backup.sh
```

### @hourly - 每小时执行

```bash
# 每小时 00 分执行
@hourly /scripts/hourly_check.sh

# 等同于
0 * * * * /scripts/hourly_check.sh
```

---

## 二、复杂时间表达式

### 多个时间点

```bash
# 每天的 8:00, 12:00, 18:00 执行
0 8,12,18 * * * /scripts/check.sh

# 每周一、三、五的 9:00 执行
0 9 * * 1,3,5 /scripts/report.sh

# 每月的 1号、15号 执行
0 0 1,15 * * /scripts/backup.sh
```

### 时间范围

```bash
# 工作时间（8:00-18:00）每小时执行
0 8-18 * * * /scripts/work_check.sh

# 工作日（周一到周五）执行
0 9 * * 1-5 /scripts/workday.sh

# 每年的1月到6月执行
0 0 1 1-6 * /scripts/first_half.sh
```

### 间隔执行

```bash
# 每2小时执行
0 */2 * * * /scripts/check.sh

# 每3天执行
0 0 */3 * * /scripts/cleanup.sh

# 每15分钟执行
*/15 * * * * /scripts/monitor.sh

# 每2小时的第30分钟执行
30 */2 * * * /scripts/task.sh
```

### 组合条件

```bash
# 工作日的工作时间（周一到周五，9:00-18:00）
0 9-18 * * 1-5 /scripts/work_task.sh

# 每个季度的第一天
0 0 1 1,4,7,10 * /scripts/quarterly.sh

# 每周末（周六、周日）上午10点
0 10 * * 6,0 /scripts/weekend.sh
```

---

## 三、环境变量管理

### 设置多个环境变量

```bash
# 编辑 crontab
crontab -e

# 设置环境变量
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
MAILTO=admin@example.com
HOME=/home/username
LANG=en_US.UTF-8

# 任务
0 2 * * * /scripts/backup.sh
```

### 在脚本中加载环境

```bash
#!/bin/bash

# 加载系统环境
source /etc/profile
source ~/.bashrc

# 或者手动设置
export PATH=/usr/local/bin:/usr/bin:/bin
export LANG=en_US.UTF-8

# 任务逻辑
echo "Task running..."
```

---

## 四、锁机制防止重复执行

### 使用 flock

```bash
# 创建脚本
cat > /scripts/backup_with_lock.sh << 'EOF'
#!/bin/bash

LOCKFILE=/var/lock/backup.lock

# 获取锁，如果已被锁定则退出
exec 200>$LOCKFILE
flock -n 200 || exit 1

# 执行任务
echo "Starting backup..."
/usr/bin/mysqldump -u root -ppassword mydb > /backup/mydb.sql
echo "Backup completed"

# 释放锁（脚本结束时自动释放）
EOF

chmod +x /scripts/backup_with_lock.sh

# crontab
*/5 * * * * /scripts/backup_with_lock.sh
```

### 使用 PID 文件

```bash
#!/bin/bash

PIDFILE=/var/run/backup.pid

# 检查是否已在运行
if [ -f $PIDFILE ]; then
    PID=$(cat $PIDFILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Script is already running (PID: $PID)"
        exit 1
    fi
fi

# 写入当前 PID
echo $$ > $PIDFILE

# 执行任务
echo "Starting backup..."
sleep 60  # 模拟长时间任务

# 清理 PID 文件
rm -f $PIDFILE
```

---

## 五、日志管理

### 日志轮转

```bash
# 创建带日志轮转的脚本
cat > /scripts/backup_with_log.sh << 'EOF'
#!/bin/bash

LOGFILE=/var/log/backup.log
MAXSIZE=10485760  # 10MB

# 检查日志大小
if [ -f $LOGFILE ]; then
    SIZE=$(stat -f%z "$LOGFILE" 2>/dev/null || stat -c%s "$LOGFILE")
    if [ $SIZE -gt $MAXSIZE ]; then
        mv $LOGFILE $LOGFILE.$(date +%Y%m%d)
        gzip $LOGFILE.$(date +%Y%m%d)
    fi
fi

# 记录日志
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting backup" >> $LOGFILE
/usr/bin/mysqldump -u root -ppassword mydb > /backup/mydb.sql 2>> $LOGFILE
echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup completed" >> $LOGFILE
EOF
```

### 按日期分割日志

```bash
#!/bin/bash

DATE=$(date +%Y%m%d)
LOGFILE=/var/log/backup_$DATE.log

echo "$(date '+%H:%M:%S') - Starting backup" >> $LOGFILE
# 执行任务
echo "$(date '+%H:%M:%S') - Backup completed" >> $LOGFILE

# 删除7天前的日志
find /var/log -name "backup_*.log" -mtime +7 -delete
```

---

## 六、错误处理

### 捕获错误并通知

```bash
#!/bin/bash

LOGFILE=/var/log/backup.log
ADMIN_EMAIL=admin@example.com

# 执行任务并捕获错误
if ! /usr/bin/mysqldump -u root -ppassword mydb > /backup/mydb.sql 2>> $LOGFILE; then
    # 备份失败，发送邮件
    echo "Backup failed at $(date)" | mail -s "Backup Failed" $ADMIN_EMAIL
    exit 1
fi

echo "$(date): Backup successful" >> $LOGFILE
```

### 重试机制

```bash
#!/bin/bash

MAX_RETRIES=3
RETRY_DELAY=60

for i in $(seq 1 $MAX_RETRIES); do
    echo "Attempt $i of $MAX_RETRIES"
    
    if /usr/bin/mysqldump -u root -ppassword mydb > /backup/mydb.sql; then
        echo "Backup successful"
        exit 0
    fi
    
    if [ $i -lt $MAX_RETRIES ]; then
        echo "Backup failed, retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
    fi
done

echo "Backup failed after $MAX_RETRIES attempts"
exit 1
```

---

## 七、实战案例

### 案例1：数据库备份（完整版）

```bash
cat > /scripts/mysql_backup.sh << 'EOF'
#!/bin/bash

# 配置
DB_USER="root"
DB_PASS="password"
DB_NAME="mydb"
BACKUP_DIR="/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
LOGFILE="/var/log/mysql_backup.log"
KEEP_DAYS=7

# 创建备份目录
mkdir -p $BACKUP_DIR

# 锁文件
LOCKFILE=/var/lock/mysql_backup.lock
exec 200>$LOCKFILE
flock -n 200 || { echo "$(date): Backup already running" >> $LOGFILE; exit 1; }

# 记录开始
echo "$(date): Starting MySQL backup" >> $LOGFILE

# 执行备份
if mysqldump -u$DB_USER -p$DB_PASS $DB_NAME | gzip > $BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz; then
    echo "$(date): Backup successful - ${DB_NAME}_${DATE}.sql.gz" >> $LOGFILE
    
    # 删除旧备份
    find $BACKUP_DIR -name "${DB_NAME}_*.sql.gz" -mtime +$KEEP_DAYS -delete
    echo "$(date): Old backups cleaned" >> $LOGFILE
else
    echo "$(date): Backup failed" >> $LOGFILE
    exit 1
fi
EOF

chmod +x /scripts/mysql_backup.sh

# crontab
0 2 * * * /scripts/mysql_backup.sh
```

### 案例2：网站备份

```bash
cat > /scripts/website_backup.sh << 'EOF'
#!/bin/bash

SITE_DIR="/var/www/html"
BACKUP_DIR="/backup/website"
DATE=$(date +%Y%m%d)
KEEP_DAYS=30

mkdir -p $BACKUP_DIR

# 备份网站文件
tar -czf $BACKUP_DIR/website_$DATE.tar.gz -C $SITE_DIR .

# 删除旧备份
find $BACKUP_DIR -name "website_*.tar.gz" -mtime +$KEEP_DAYS -delete

# 同步到远程服务器
rsync -avz $BACKUP_DIR/ backup@remote:/backup/website/
EOF

chmod +x /scripts/website_backup.sh

# crontab - 每天凌晨3点
0 3 * * * /scripts/website_backup.sh >> /var/log/website_backup.log 2>&1
```

### 案例3：系统监控

```bash
cat > /scripts/system_monitor.sh << 'EOF'
#!/bin/bash

LOGFILE="/var/log/system_monitor.log"
ALERT_EMAIL="admin@example.com"

# 检查磁盘使用率
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): Disk usage is ${DISK_USAGE}%" | tee -a $LOGFILE | \
        mail -s "Disk Usage Alert" $ALERT_EMAIL
fi

# 检查内存使用率
MEM_USAGE=$(free | awk 'NR==2 {printf "%.0f", $3/$2*100}')
if [ $MEM_USAGE -gt 90 ]; then
    echo "$(date): Memory usage is ${MEM_USAGE}%" | tee -a $LOGFILE | \
        mail -s "Memory Usage Alert" $ALERT_EMAIL
fi

# 检查服务状态
for service in nginx mysql redis; do
    if ! systemctl is-active --quiet $service; then
        echo "$(date): $service is down, attempting restart" | tee -a $LOGFILE
        systemctl start $service
        echo "Service $service is down" | mail -s "Service Alert" $ALERT_EMAIL
    fi
done
EOF

chmod +x /scripts/system_monitor.sh

# crontab - 每5分钟检查
*/5 * * * * /scripts/system_monitor.sh
```

---

## 八、性能优化

### 避免同时执行

```bash
# 错误：所有任务同时执行
0 2 * * * /scripts/backup_db.sh
0 2 * * * /scripts/backup_files.sh
0 2 * * * /scripts/clean_logs.sh

# 正确：错开执行时间
0 2 * * * /scripts/backup_db.sh
10 2 * * * /scripts/backup_files.sh
20 2 * * * /scripts/clean_logs.sh
```

### 使用 nice 降低优先级

```bash
# 降低任务优先级，避免影响系统性能
0 2 * * * nice -n 19 /scripts/backup.sh
```

### 限制资源使用

```bash
# 使用 ionice 限制 IO
0 2 * * * ionice -c3 /scripts/backup.sh

# 组合使用
0 2 * * * nice -n 19 ionice -c3 /scripts/backup.sh
```

---

## 练习题

1. `@daily` 等同于什么时间表达式？
2. 如何防止 crontab 任务重复执行？
3. 如何让备份任务不影响系统性能？

<details>
<summary>答案</summary>

1. `0 0 * * *`（每天凌晨0点）
2. 使用 flock 锁机制或 PID 文件检查
3. 使用 `nice -n 19` 降低 CPU 优先级，使用 `ionice -c3` 降低 IO 优先级

</details>
