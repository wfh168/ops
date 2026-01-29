# 定时任务学习指南

## 学习路线

```
01_crontab基础.md       ──▶  掌握 crontab 基本使用
        │
        ▼
02_crontab高级用法.md   ──▶  学习高级技巧和实战
        │
        ▼
03_系统定时任务.md      ──▶  理解系统级定时任务
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_crontab基础.md | crontab 命令、时间格式、基本用法 | 0.5 天 |
| 02_crontab高级用法.md | 特殊字符串、锁机制、日志管理 | 0.5 天 |
| 03_系统定时任务.md | /etc/crontab、cron.d、anacron | 0.5 天 |

## 核心概念

### crontab 时间格式

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─── 星期 (0-7)
│ │ │ └───── 月份 (1-12)
│ │ └─────── 日期 (1-31)
│ └───────── 小时 (0-23)
└─────────── 分钟 (0-59)
```

### 特殊符号

| 符号 | 含义 | 示例 |
|------|------|------|
| * | 任意值 | `* * * * *` 每分钟 |
| , | 列举 | `0 8,12,18 * * *` 8点、12点、18点 |
| - | 范围 | `0 8-18 * * *` 8点到18点 |
| / | 间隔 | `*/5 * * * *` 每5分钟 |

### 特殊时间字符串

| 字符串 | 等同于 | 说明 |
|--------|--------|------|
| @reboot | - | 开机时执行 |
| @yearly | 0 0 1 1 * | 每年执行 |
| @monthly | 0 0 1 * * | 每月执行 |
| @weekly | 0 0 * * 0 | 每周执行 |
| @daily | 0 0 * * * | 每天执行 |
| @hourly | 0 * * * * | 每小时执行 |

## 常用命令

```bash
# 管理 crontab
crontab -e                        # 编辑
crontab -l                        # 查看
crontab -r                        # 删除

# 管理 crond 服务
systemctl status crond            # 查看状态
systemctl start crond             # 启动
systemctl enable crond            # 开机自启

# 查看日志
tail -f /var/log/cron             # cron 日志
```

## 常用时间表达式

```bash
# 每分钟
* * * * * command

# 每小时
0 * * * * command

# 每天凌晨2点
0 2 * * * command

# 每5分钟
*/5 * * * * command

# 工作日上午9点
0 9 * * 1-5 command

# 每月1号和15号
0 0 1,15 * * command

# 每天8点到18点，每小时
0 8-18 * * * command

# 每周六、周日
0 10 * * 6,0 command
```

## 任务类型

### 用户任务

```bash
# 编辑用户 crontab
crontab -e

# 格式（5个字段）
分 时 日 月 周 命令
```

### 系统任务

```bash
# /etc/crontab
# 格式（6个字段，多了用户）
分 时 日 月 周 用户 命令

# /etc/cron.d/
# 独立的配置文件

# /etc/cron.{hourly,daily,weekly,monthly}/
# 放置可执行脚本
```

## 实战场景

### 场景1：数据库备份

```bash
# 每天凌晨2点备份
0 2 * * * /scripts/backup_mysql.sh >> /var/log/backup.log 2>&1
```

### 场景2：日志清理

```bash
# 每天凌晨3点清理7天前的日志
0 3 * * * find /var/log/myapp -name "*.log" -mtime +7 -delete
```

### 场景3：服务监控

```bash
# 每5分钟检查服务状态
*/5 * * * * /scripts/check_service.sh
```

### 场景4：定期同步

```bash
# 每小时同步数据
0 * * * * rsync -av /data/source/ /data/backup/
```

## 最佳实践

### 1. 使用绝对路径

```bash
# ❌ 错误
0 2 * * * backup.sh

# ✅ 正确
0 2 * * * /usr/local/bin/backup.sh
```

### 2. 重定向输出

```bash
# 记录日志
0 2 * * * /scripts/backup.sh >> /var/log/backup.log 2>&1

# 丢弃输出
0 2 * * * /scripts/backup.sh > /dev/null 2>&1
```

### 3. 设置环境变量

```bash
# 在 crontab 开头设置
PATH=/usr/local/bin:/usr/bin:/bin
SHELL=/bin/bash
MAILTO=admin@example.com

# 任务
0 2 * * * /scripts/backup.sh
```

### 4. 防止重复执行

```bash
#!/bin/bash

# 使用 flock 锁
LOCKFILE=/var/lock/backup.lock
exec 200>$LOCKFILE
flock -n 200 || exit 1

# 执行任务
/usr/bin/mysqldump ...
```

### 5. 错误处理

```bash
#!/bin/bash

# 记录日志
LOGFILE=/var/log/backup.log

# 执行任务
if /usr/bin/mysqldump ...; then
    echo "$(date): Backup successful" >> $LOGFILE
else
    echo "$(date): Backup failed" >> $LOGFILE
    exit 1
fi
```

## 调试技巧

### 1. 手动测试

```bash
# 先手动执行脚本
/scripts/backup.sh

# 检查权限
ls -l /scripts/backup.sh
chmod +x /scripts/backup.sh
```

### 2. 查看日志

```bash
# cron 日志
tail -f /var/log/cron

# 任务输出日志
tail -f /var/log/backup.log
```

### 3. 临时测试

```bash
# 设置为每分钟执行
* * * * * /scripts/test.sh >> /tmp/test.log 2>&1

# 等待1-2分钟后检查
cat /tmp/test.log
```

## 常见问题

### 1. 任务不执行

- 检查 crond 服务是否运行
- 检查脚本权限
- 检查时间表达式
- 查看 /var/log/cron 日志

### 2. 命令找不到

- 使用绝对路径
- 在 crontab 中设置 PATH
- 在脚本中设置环境变量

### 3. 脚本执行失败

- 手动执行测试
- 检查脚本语法
- 查看错误日志

### 4. 邮箱被塞满

- 重定向输出到日志文件
- 设置 MAILTO=""
- 使用 > /dev/null 2>&1

## 安全建议

1. **最小权限** - 用普通用户运行任务，避免用 root
2. **日志审计** - 记录所有任务的执行日志
3. **定期检查** - 审计 crontab 配置
4. **保护脚本** - 设置适当的文件权限
5. **测试验证** - 新任务先测试再上线

## 面试常考

1. crontab 时间格式的5个字段是什么？
2. `*/5 * * * *` 表示什么意思？
3. 如何防止 crontab 任务重复执行？
4. 用户 crontab 和系统 crontab 有什么区别？
5. 为什么 crontab 中要使用绝对路径？

## 下一步

完成定时任务学习后，进入「三剑客」模块，学习 grep、sed、awk 这三个强大的文本处理工具。
