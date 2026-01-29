# WordPress 安装与配置

## 什么是 WordPress？

**WordPress** 是全球最流行的开源内容管理系统（CMS），用于创建网站和博客。

### WordPress 特点

✅ **开源免费**：完全免费使用  
✅ **易于使用**：无需编程知识  
✅ **主题丰富**：数千个免费和付费主题  
✅ **插件强大**：超过 50,000 个插件  
✅ **SEO 友好**：搜索引擎优化  
✅ **社区活跃**：庞大的用户社区  

### 系统要求

- **PHP**：7.4 或更高版本
- **MySQL**：5.7 或更高版本（或 MariaDB 10.3+）
- **HTTPS**：推荐使用 SSL 证书
- **磁盘空间**：至少 1GB

---

## 准备工作

### 1. 创建数据库

```bash
# 登录 MySQL
mysql -u root -p

# 创建数据库
CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 创建用户并授权
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wp_password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;

# 查看数据库
SHOW DATABASES;

# 退出
EXIT;
```

### 2. 创建站点目录

```bash
# 创建目录
mkdir -p /var/www/wordpress

# 设置权限
chown -R nginx:nginx /var/www/wordpress
chmod -R 755 /var/www/wordpress
```

---

## 下载 WordPress

### 方法 1：官方下载

```bash
# 下载最新版本
cd /tmp
wget https://wordpress.org/latest.tar.gz

# 或下载中文版
wget https://cn.wordpress.org/latest-zh_CN.tar.gz

# 解压
tar -xzf latest-zh_CN.tar.gz

# 移动文件
mv wordpress/* /var/www/wordpress/

# 设置权限
chown -R nginx:nginx /var/www/wordpress
```

### 方法 2：使用 WP-CLI

```bash
# 安装 WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# 下载 WordPress
cd /var/www/wordpress
wp core download --locale=zh_CN --allow-root
```

---

## 配置 WordPress

### 方法 1：Web 界面配置

**步骤 1：访问安装页面**

```
http://your-domain.com/
```

**步骤 2：选择语言**
- 选择 "简体中文"
- 点击 "继续"

**步骤 3：配置数据库**
- 数据库名：wordpress
- 用户名：wpuser
- 密码：wp_password
- 数据库主机：localhost
- 表前缀：wp_（默认）

**步骤 4：运行安装**
- 站点标题：我的博客
- 用户名：admin
- 密码：设置强密码
- 电子邮件：your@email.com
- 搜索引擎可见性：根据需要选择

**步骤 5：完成安装**
- 点击 "安装 WordPress"
- 登录后台

### 方法 2：手动配置

```bash
# 复制配置文件
cd /var/www/wordpress
cp wp-config-sample.php wp-config.php

# 编辑配置文件
vim wp-config.php
```

```php
// 数据库配置
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wpuser' );
define( 'DB_PASSWORD', 'wp_password' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

// 安全密钥（访问 https://api.wordpress.org/secret-key/1.1/salt/ 获取）
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

// 表前缀
$table_prefix = 'wp_';

// 调试模式（生产环境设置为 false）
define( 'WP_DEBUG', false );
```

### 方法 3：使用 WP-CLI

```bash
cd /var/www/wordpress

# 创建配置文件
wp config create \
  --dbname=wordpress \
  --dbuser=wpuser \
  --dbpass=wp_password \
  --dbhost=localhost \
  --locale=zh_CN \
  --allow-root

# 安装 WordPress
wp core install \
  --url=http://your-domain.com \
  --title="我的博客" \
  --admin_user=admin \
  --admin_password=admin_password \
  --admin_email=your@email.com \
  --allow-root
```

---

## 配置 Nginx

### 基本配置

```bash
vim /etc/nginx/conf.d/wordpress.conf
```

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    root /var/www/wordpress;
    index index.php index.html;

    # 日志
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;

    # 上传文件大小限制
    client_max_body_size 64M;

    # WordPress 固定链接
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP 处理
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        # FastCGI 缓存
        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
    }

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }

    # 禁止访问 wp-config.php
    location = /wp-config.php {
        deny all;
    }

    # 禁止访问 readme.html
    location = /readme.html {
        deny all;
    }
}
```

### 测试并重启 Nginx

```bash
# 测试配置
nginx -t

# 重启 Nginx
systemctl restart nginx
```

---

## WordPress 优化

### 1. 启用对象缓存

```bash
# 安装 Redis
yum install -y redis
systemctl start redis
systemctl enable redis

# 安装 PHP Redis 扩展
yum install -y php-redis
systemctl restart php-fpm

# 安装 Redis Object Cache 插件
# 在 WordPress 后台安装并启用
```

### 2. 启用 FastCGI 缓存

```bash
vim /etc/nginx/conf.d/wordpress.conf
```

```nginx
# 在 http 块中添加
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";

server {
    # ... 其他配置 ...

    # 设置缓存条件
    set $skip_cache 0;

    # POST 请求不缓存
    if ($request_method = POST) {
        set $skip_cache 1;
    }

    # 查询字符串不缓存
    if ($query_string != "") {
        set $skip_cache 1;
    }

    # 特定 URI 不缓存
    if ($request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
        set $skip_cache 1;
    }

    # 已登录用户不缓存
    if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
        set $skip_cache 1;
    }

    location ~ \.php$ {
        # ... 其他配置 ...
        
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
        add_header X-FastCGI-Cache $upstream_cache_status;
    }
}
```

```bash
# 创建缓存目录
mkdir -p /var/cache/nginx
chown -R nginx:nginx /var/cache/nginx

# 重启 Nginx
systemctl restart nginx
```

### 3. 启用 Gzip 压缩

```bash
vim /etc/nginx/nginx.conf
```

```nginx
http {
    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1k;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml application/atom+xml image/svg+xml text/x-component;
    gzip_disable "msie6";
}
```

### 4. 优化 PHP-FPM

```bash
vim /etc/php-fpm.d/www.conf

# 进程管理
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500

# 重启 PHP-FPM
systemctl restart php-fpm
```

### 5. 优化 WordPress 配置

```bash
vim /var/www/wordpress/wp-config.php
```

```php
// 禁用文件编辑
define('DISALLOW_FILE_EDIT', true);

// 自动保存间隔（秒）
define('AUTOSAVE_INTERVAL', 300);

// 文章修订版本数量
define('WP_POST_REVISIONS', 5);

// 清空回收站天数
define('EMPTY_TRASH_DAYS', 7);

// 内存限制
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

// 启用缓存
define('WP_CACHE', true);
```

---

## 配置 HTTPS

### 1. 获取 SSL 证书

```bash
# 安装 Certbot
yum install -y certbot python3-certbot-nginx

# 获取证书
certbot --nginx -d your-domain.com -d www.your-domain.com

# 自动续期
echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | tee -a /etc/crontab > /dev/null
```

### 2. 配置 Nginx HTTPS

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    root /var/www/wordpress;
    index index.php;

    # SSL 证书
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # ... 其他配置 ...
}
```

### 3. 更新 WordPress 配置

```bash
vim /var/www/wordpress/wp-config.php
```

```php
// 强制使用 HTTPS
define('FORCE_SSL_ADMIN', true);

// 设置站点 URL
define('WP_HOME', 'https://your-domain.com');
define('WP_SITEURL', 'https://your-domain.com');
```

---

## 安全加固

### 1. 修改数据库表前缀

```bash
# 在安装时设置，或使用插件修改
# 默认 wp_ 改为随机前缀，如 wp_abc123_
```

### 2. 禁用 XML-RPC

```nginx
# 在 Nginx 配置中添加
location = /xmlrpc.php {
    deny all;
}
```

### 3. 限制登录尝试

```bash
# 安装 Limit Login Attempts Reloaded 插件
# 或在 Nginx 中配置
```

```nginx
location = /wp-login.php {
    limit_req zone=login burst=2 nodelay;
    fastcgi_pass unix:/var/run/php-fpm.sock;
    # ... 其他配置 ...
}
```

### 4. 隐藏 WordPress 版本

```php
// 在 functions.php 中添加
remove_action('wp_head', 'wp_generator');
```

### 5. 定期备份

```bash
#!/bin/bash
# WordPress 备份脚本

BACKUP_DIR="/backup/wordpress"
DATE=$(date +%Y%m%d)
WP_DIR="/var/www/wordpress"
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="wp_password"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份文件
tar -czf $BACKUP_DIR/wp_files_$DATE.tar.gz $WP_DIR

# 备份数据库
mysqldump -u$DB_USER -p$DB_PASS $DB_NAME | gzip > $BACKUP_DIR/wp_db_$DATE.sql.gz

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "备份完成: $DATE"
```

---

## 常用插件推荐

### 性能优化

1. **WP Super Cache** - 页面缓存
2. **Autoptimize** - 代码优化
3. **EWWW Image Optimizer** - 图片优化
4. **Redis Object Cache** - 对象缓存

### 安全防护

1. **Wordfence Security** - 安全防护
2. **iThemes Security** - 安全加固
3. **Limit Login Attempts Reloaded** - 限制登录
4. **UpdraftPlus** - 备份恢复

### SEO 优化

1. **Yoast SEO** - SEO 优化
2. **All in One SEO** - SEO 工具
3. **Google XML Sitemaps** - 站点地图

### 功能增强

1. **Contact Form 7** - 联系表单
2. **WooCommerce** - 电商功能
3. **Elementor** - 页面构建器

---

## 故障排查

### 1. 白屏问题

**原因**：PHP 错误、内存不足、插件冲突

**解决**：
```bash
# 启用调试模式
vim /var/www/wordpress/wp-config.php

define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);

# 查看错误日志
tail -f /var/www/wordpress/wp-content/debug.log
```

### 2. 无法上传文件

**原因**：权限问题、PHP 限制

**解决**：
```bash
# 检查权限
chown -R nginx:nginx /var/www/wordpress/wp-content/uploads

# 检查 PHP 配置
vim /etc/php.ini

upload_max_filesize = 64M
post_max_size = 64M
```

### 3. 固定链接 404

**原因**：Nginx 配置问题

**解决**：
```nginx
# 确保 Nginx 配置中有
location / {
    try_files $uri $uri/ /index.php?$args;
}
```

---

## 小结

本节学习了：

✅ WordPress 的安装和配置  
✅ Nginx 的 WordPress 配置  
✅ WordPress 性能优化  
✅ HTTPS 配置  
✅ 安全加固  
✅ 常用插件推荐  
✅ 故障排查  

下一节将学习 WordPress 的高级应用和维护。

---

## 扩展阅读

- [WordPress 官方文档](https://wordpress.org/support/)
- [WordPress 中文文档](https://cn.wordpress.org/support/)
- [Nginx WordPress 优化](https://www.nginx.com/resources/wiki/start/topics/recipes/wordpress/)
