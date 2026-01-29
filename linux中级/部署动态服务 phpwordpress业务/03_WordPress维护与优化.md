# WordPress 维护与优化

## 日常维护

### 1. 更新管理

**WordPress 核心更新**：
```bash
# 使用 WP-CLI 更新
wp core update --allow-root
wp core update-db --allow-root

# 或在后台手动更新
# 仪表盘 → 更新
```

**插件更新**：
```bash
# 查看可更新的插件
wp plugin list --update=available --allow-root

# 更新所有插件
wp plugin update --all --allow-root

# 更新指定插件
wp plugin update plugin-name --allow-root
```

**主题更新**：
```bash
# 更新所有主题
wp theme update --all --allow-root
```

### 2. 数据库优化

```bash
# 优化数据库
wp db optimize --allow-root

# 修复数据库
wp db repair --allow-root

# 清理修订版本
wp post delete $(wp post list --post_type='revision' --format=ids --allow-root) --allow-root

# 清理垃圾评论
wp comment delete $(wp comment list --status=spam --format=ids --allow-root) --allow-root
```

### 3. 定期备份

**自动备份脚本**：
```bash
#!/bin/bash
# /usr/local/bin/wp_backup.sh

BACKUP_DIR="/backup/wordpress"
DATE=$(date +%Y%m%d_%H%M%S)
WP_DIR="/var/www/wordpress"
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="wp_password"

mkdir -p $BACKUP_DIR/{files,database}

# 备份文件
tar -czf $BACKUP_DIR/files/wp_$DATE.tar.gz \
  --exclude='wp-content/cache' \
  --exclude='wp-content/uploads/cache' \
  $WP_DIR

# 备份数据库
mysqldump -u$DB_USER -p$DB_PASS $DB_NAME | gzip > $BACKUP_DIR/database/db_$DATE.sql.gz

# 保留最近 7 天的备份
find $BACKUP_DIR -type f -mtime +7 -delete

# 上传到远程（可选）
# rsync -avz $BACKUP_DIR/ user@backup-server:/backup/wordpress/
```

**配置定时任务**：
```bash
crontab -e
0 2 * * * /usr/local/bin/wp_backup.sh
```

---

## 性能监控

### 1. 使用 Query Monitor 插件

监控数据库查询、PHP 错误、HTTP 请求等。

### 2. 启用慢查询日志

```bash
vim /etc/my.cnf

[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 重启 MySQL
systemctl restart mysqld
```

### 3. 监控服务器资源

```bash
# 实时监控
htop

# 查看 Nginx 状态
systemctl status nginx

# 查看 PHP-FPM 状态
systemctl status php-fpm

# 查看 MySQL 状态
systemctl status mysqld
```

---

## 高级优化

### 1. CDN 加速

**使用 CDN 插件**：
- WP Super Cache + CDN
- W3 Total Cache
- Cloudflare

**配置示例**：
```php
// wp-config.php
define('WP_CONTENT_URL', 'https://cdn.your-domain.com/wp-content');
```

### 2. 数据库读写分离

**配置主从复制后**：
```php
// wp-config.php
define('DB_HOST', 'master-db:3306,slave-db:3306');
```

### 3. 使用 Memcached

```bash
# 安装 Memcached
yum install -y memcached php-memcached
systemctl start memcached
systemctl enable memcached

# 安装 WordPress 插件
# Memcached Object Cache
```

---

## 安全维护

### 1. 定期安全扫描

```bash
# 使用 WP-CLI 检查核心文件
wp core verify-checksums --allow-root

# 检查插件
wp plugin verify-checksums --all --allow-root
```

### 2. 监控日志

```bash
# Nginx 访问日志
tail -f /var/log/nginx/wordpress_access.log

# Nginx 错误日志
tail -f /var/log/nginx/wordpress_error.log

# PHP 错误日志
tail -f /var/log/php-fpm/error.log
```

### 3. 防火墙规则

```bash
# 限制 wp-login.php 访问频率
vim /etc/nginx/conf.d/wordpress.conf

http {
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
}

server {
    location = /wp-login.php {
        limit_req zone=login burst=2 nodelay;
        # ... 其他配置
    }
}
```

---

## 故障恢复

### 1. 从备份恢复

```bash
# 恢复文件
tar -xzf wp_20240129.tar.gz -C /var/www/

# 恢复数据库
zcat db_20240129.sql.gz | mysql -u wpuser -p wordpress

# 设置权限
chown -R nginx:nginx /var/www/wordpress
```

### 2. 修复数据库

```bash
# 在 wp-config.php 中添加
define('WP_ALLOW_REPAIR', true);

# 访问修复页面
http://your-domain.com/wp-admin/maint/repair.php

# 修复完成后删除该行配置
```

---

## 迁移 WordPress

### 1. 手动迁移

**导出数据**：
```bash
# 备份文件
tar -czf wordpress.tar.gz /var/www/wordpress

# 导出数据库
mysqldump -u wpuser -p wordpress > wordpress.sql
```

**导入到新服务器**：
```bash
# 解压文件
tar -xzf wordpress.tar.gz -C /var/www/

# 导入数据库
mysql -u wpuser -p wordpress < wordpress.sql

# 更新站点 URL
mysql -u wpuser -p wordpress
UPDATE wp_options SET option_value='https://new-domain.com' WHERE option_name='siteurl';
UPDATE wp_options SET option_value='https://new-domain.com' WHERE option_name='home';
```

### 2. 使用插件迁移

推荐插件：
- **Duplicator** - 完整迁移
- **All-in-One WP Migration** - 简单迁移
- **UpdraftPlus** - 备份迁移

---

## 小结

本节学习了：

✅ WordPress 日常维护  
✅ 数据库优化  
✅ 定期备份  
✅ 性能监控  
✅ 高级优化（CDN、缓存）  
✅ 安全维护  
✅ 故障恢复  
✅ 站点迁移  

至此，WordPress 部署与维护的学习全部完成！

---

## 扩展阅读

- [WordPress 性能优化](https://wordpress.org/support/article/optimization/)
- [WordPress 安全指南](https://wordpress.org/support/article/hardening-wordpress/)
- [WP-CLI 文档](https://wp-cli.org/)
