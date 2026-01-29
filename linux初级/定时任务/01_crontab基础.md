# crontab 基础

## 什么是 crontab

crontab 是 Linux 的定时任务工具，可以让系统在指定时间自动执行命令或脚本。

```
┌─────────────────────────────────────────────────────────┐
│                    crontab 工作流程                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   用户编辑 crontab                                       │
│         │                                               │
│         ▼                                               │
│   保存到 /var/spool/cron/username                       │
│         │                                               │
│         ▼                                               │
│   crond 守护进程每分钟检查一次                           │
│         │                                               │
│         ▼                                               │
│   到达指定时间 → 执行任务                                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 一、crontab 基本命令

### 管理定时任务

```bash
# 编辑当前用户的 crontab
crontab -e

# 查看当前用户的 crontab
crontab -l

# 删除当前用户的 crontab
crontab -r

# 删除前确认
crontab -i -r

# 管理其他用户的 crontab（需要 root）
crontab -u username -e
crontab -u username -l
```

### crond 服务管理

```bash
# 查看 crond 服务状态
systemctl status crond

# 启动 crond
systemctl start crond

# 停止 crond
systemctl stop crond

# 重启 crond
systemctl restart crond

# 开机自启
systemctl enable crond

# 检查是否开机自启
systemctl is-enabled crond
```

---

## 二、crontab 时间格式

### 基本格式

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─── 星期几 (0-7, 0和7都表示周日)
│ │ │ └───── 月份 (1-12)
│ │ └─────── 日期 (1-31)
│ └───────── 小时 (0-23)
└─────────── 分钟 (0-59)
```

### 时间字段说明

| 字段 | 范围 | 说明 |
|------|------|------|
| 分钟 | 0-59 | 每小时的第几分钟 |
| 小时 | 0-23 | 每天的第几小时 |
| 日期 | 1-31 | 每月的第几天 |
| 月份 | 1-12 | 每年的第几月 |
| 星期 | 0-7 | 每周的第几天（0和7都是周日） |

---

## 三、时间表达式

### 特殊符号

| 符号 | 含义 | 示例 |
|------|------|------|
| * | 任意值 | `* * * * *` 每分钟 |
| , | 列举多个值 | `0 8,12,18 * * *` 8点、12点、18点 |
| - | 范围 | `0 8-18 * * *` 8点到18点 |
| / | 间隔 | `*/5 * * * *` 每5分钟 |

### 常用时间示例

```bash
# 每分钟执行
* * * * * command

# 每小时执行（每小时的第0分钟）
0 * * * * command

# 每天凌晨2点执行
0 2 * * * command

# 每天上午8点30分执行
30 8 * * * command

# 每周一上午9点执行
0 9 * * 1 command

# 每月1号凌晨3点执行
0 3 1 * * command

# 每年1月1日凌晨0点执行
0 0 1 1 * command

# 每5分钟执行一次
*/5 * * * * command

# 每小时的第10、20、30分钟执行
10,20,30 * * * * command

# 每天8点到18点，每小时执行
0 8-18 * * * command

# 工作日（周一到周五）上午9点执行
0 9 * * 1-5 command

# 每个月的1号和15号执行
0 0 1,15 * * command

# 每隔2小时执行
0 */2 * * * command

# 每天凌晨1点到5点，每小时执行
0 1-5 * * * command

# 每周六、周日上午10点执行
0 10 * * 6,0 command
```

---

## 四、crontab 文件格式

### 完整示例

```bash
# 编辑 crontab
crontab -e

# 内容示例
# 每天凌晨2点备份数据库
0 2 * * * /scripts/backup_db.sh

# 每5分钟检查服务状态
*/5 * * * * /scripts/check_service.sh

# 每周一上午9点发送报告
0 9 * * 1 /scripts/send_report.sh

# 每月1号清理日志
0 0 1 * * /scripts/clean_logs.sh
```

### 注释

```bash
# 这是注释
# 每天备份
0 2 * * * /scripts/backup.sh

# 可以添加多行注释
# 用于说明任务的作用
0 3 * * * /scripts/cleanup.sh
```

---

## 五、环境变量

### crontab 中的环境变量

```bash
# crontab 的环境变量很少，需要手动设置

# 设置 PATH
PATH=/usr/local/bin:/usr/bin:/bin

# 设置 SHELL
SHELL=/bin/bash

# 设置邮件接收者
MAILTO=admin@example.com

# 设置 HOME
HOME=/home/username

# 任务
0 2 * * * /scripts/backup.sh
```

### 常见问题

```bash
# ❌ 错误：命令找不到
0 2 * * * backup.sh

# ✅ 正确：使用绝对路径
0 2 * * * /usr/local/bin/backup.sh

# ✅ 或者设置 PATH
PATH=/usr/local/bin:/usr/bin:/bin
0 2 * * * backup.sh
```

---

## 六、输出重定向

### 标准输出和错误

```bash
# 输出到文件
0 2 * * * /scripts/backup.sh > /var/log/backup.log 2>&1

# 追加到文件
0 2 * * * /scripts/backup.sh >> /var/log/backup.log 2>&1

# 丢弃所有输出
0 2 * * * /scripts/backup.sh > /dev/null 2>&1

# 只保留错误信息
0 2 * * * /scripts/backup.sh > /dev/null 2>> /var/log/backup_error.log

# 分别记录标准输出和错误
0 2 * * * /scripts/backup.sh > /var/log/backup.log 2> /var/log/backup_error.log
```

### 邮件通知

```bash
# 默认情况下，crontab 会将输出发送到用户邮箱
# 查看邮件
mail

# 禁用邮件
MAILTO=""
0 2 * * * /scripts/backup.sh

# 发送到指定邮箱
MAILTO=admin@example.com
0 2 * * * /scripts/backup.sh
```

---

## 七、实战示例

### 示例1：每天备份数据库

```bash
# 创建备份脚本
cat > /scripts/backup_mysql.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
mysqldump -u root -ppassword mydb > /backup/mydb_$DATE.sql
find /backup -name "mydb_*.sql" -mtime +7 -delete
EOF

chmod +x /scripts/backup_mysql.sh

# 添加到 crontab
crontab -e
# 每天凌晨2点执行
0 2 * * * /scripts/backup_mysql.sh >> /var/log/backup.log 2>&1
```

### 示例2：定期清理日志

```bash
# 创建清理脚本
cat > /scripts/clean_logs.sh << 'EOF'
#!/bin/bash
# 删除7天前的日志
find /var/log/myapp -name "*.log" -mtime +7 -delete
# 清空大于100M的日志
find /var/log/myapp -name "*.log" -size +100M -exec truncate -s 0 {} \;
EOF

chmod +x /scripts/clean_logs.sh

# 添加到 crontab
# 每天凌晨3点执行
0 3 * * * /scripts/clean_logs.sh
```

### 示例3：监控服务状态

```bash
# 创建监控脚本
cat > /scripts/check_nginx.sh << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet nginx; then
    systemctl start nginx
    echo "$(date): Nginx was down, restarted" >> /var/log/nginx_monitor.log
fi
EOF

chmod +x /scripts/check_nginx.sh

# 添加到 crontab
# 每5分钟检查一次
*/5 * * * * /scripts/check_nginx.sh
```

### 示例4：定期同步文件

```bash
# 每小时同步一次
0 * * * * rsync -av /data/source/ /data/backup/ >> /var/log/sync.log 2>&1

# 每天凌晨1点同步到远程服务器
0 1 * * * rsync -avz /data/ user@remote:/backup/ >> /var/log/remote_sync.log 2>&1
```

---

## 八、调试技巧

### 1. 测试脚本

```bash
# 先手动执行脚本，确保没问题
/scripts/backup.sh

# 检查脚本权限
ls -l /scripts/backup.sh
chmod +x /scripts/backup.sh
```

### 2. 查看日志

```bash
# 查看 cron 日志
tail -f /var/log/cron

# 查看任务输出
tail -f /var/log/backup.log
```

### 3. 临时测试

```bash
# 设置为每分钟执行，测试是否正常
* * * * * /scripts/test.sh >> /tmp/test.log 2>&1

# 等待1-2分钟后检查
cat /tmp/test.log

# 测试完成后改回正常时间
```

---

## 九、注意事项

### 1. 使用绝对路径

```bash
# ❌ 错误
0 2 * * * backup.sh

# ✅ 正确
0 2 * * * /usr/local/bin/backup.sh
```

### 2. 脚本要有执行权限

```bash
chmod +x /scripts/backup.sh
```

### 3. 注意环境变量

```bash
# 在脚本开头设置环境变量
#!/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin
source /etc/profile
```

### 4. 重定向输出

```bash
# 避免邮箱被塞满
0 2 * * * /scripts/backup.sh > /dev/null 2>&1
```

### 5. 时间冲突

```bash
# 避免多个任务同时执行
0 2 * * * /scripts/backup_db.sh
5 2 * * * /scripts/backup_files.sh
10 2 * * * /scripts/clean_logs.sh
```

---

## 练习题

1. 如何设置每天上午10点30分执行任务？
2. `*/10 * * * *` 表示什么意思？
3. 为什么 crontab 中的命令要使用绝对路径？

<details>
<summary>答案</summary>

1. `30 10 * * * command`
2. 每10分钟执行一次
3. 因为 crontab 的环境变量很少，PATH 可能不包含命令所在目录，使用绝对路径可以避免"命令找不到"的错误

</details>
