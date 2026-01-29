# Nginx 虚拟主机

## 什么是虚拟主机？

虚拟主机（Virtual Host）允许在一台服务器上运行多个网站，每个网站使用不同的域名或端口。

### 虚拟主机的优势

- **节省成本**：一台服务器托管多个网站
- **资源共享**：共享服务器资源
- **易于管理**：统一管理多个站点
- **灵活配置**：每个站点独立配置

---

## 虚拟主机类型

### 1. 基于域名的虚拟主机（最常用）

不同域名访问不同网站。

```nginx
# 网站1
server {
    listen 80;
    server_name www.site1.com site1.com;
    root /data/www/site1;
    index index.html;
}

# 网站2
server {
    listen 80;
    server_name www.site2.com site2.com;
    root /data/www/site2;
    index index.html;
}

# 网站3
server {
    listen 80;
    server_name www.site3.com site3.com;
    root /data/www/site3;
    index index.html;
}
```

### 2. 基于端口的虚拟主机

不同端口访问不同网站。

```nginx
# 端口 80
server {
    listen 80;
    server_name example.com;
    root /data/www/site80;
}

# 端口 8080
server {
    listen 8080;
    server_name example.com;
    root /data/www/site8080;
}

# 端口 8081
server {
    listen 8081;
    server_name example.com;
    root /data/www/site8081;
}
```

### 3. 基于 IP 的虚拟主机

不同 IP 访问不同网站。

```nginx
# IP 1
server {
    listen 192.168.1.10:80;
    server_name _;
    root /data/www/site1;
}

# IP 2
server {
    listen 192.168.1.11:80;
    server_name _;
    root /data/www/site2;
}
```

---

## 实战：配置多个网站

### 准备工作

```bash
# 创建网站目录
mkdir -p /data/www/{blog,shop,forum}

# 创建测试页面
echo "<h1>Blog Site</h1>" > /data/www/blog/index.html
echo "<h1>Shop Site</h1>" > /data/www/shop/index.html
echo "<h1>Forum Site</h1>" > /data/www/forum/index.html

# 设置权限
chown -R nginx:nginx /data/www
chmod -R 755 /data/www
```

### 配置虚拟主机

```bash
# 博客站点
cat > /etc/nginx/conf.d/blog.conf << 'EOF'
server {
    listen 80;
    server_name blog.example.com www.blog.example.com;
    
    root /data/www/blog;
    index index.html index.htm;
    
    access_log /var/log/nginx/blog.access.log;
    error_log /var/log/nginx/blog.error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# 商城站点
cat > /etc/nginx/conf.d/shop.conf << 'EOF'
server {
    listen 80;
    server_name shop.example.com www.shop.example.com;
    
    root /data/www/shop;
    index index.html index.htm;
    
    access_log /var/log/nginx/shop.access.log;
    error_log /var/log/nginx/shop.error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# 论坛站点
cat > /etc/nginx/conf.d/forum.conf << 'EOF'
server {
    listen 80;
    server_name forum.example.com www.forum.example.com;
    
    root /data/www/forum;
    index index.html index.htm;
    
    access_log /var/log/nginx/forum.access.log;
    error_log /var/log/nginx/forum.error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# 测试并重载
nginx -t && nginx -s reload
```

### 配置 DNS 或 hosts

```bash
# 本地测试：修改 hosts 文件
# Linux/Mac: /etc/hosts
# Windows: C:\Windows\System32\drivers\etc\hosts

192.168.1.100 blog.example.com
192.168.1.100 shop.example.com
192.168.1.100 forum.example.com

# 测试访问
curl http://blog.example.com
curl http://shop.example.com
curl http://forum.example.com
```

---

## server_name 详解

### 精确匹配

```nginx
server {
    listen 80;
    server_name www.example.com;
}
```

### 通配符匹配

```nginx
# 前缀通配符
server {
    listen 80;
    server_name *.example.com;
}

# 后缀通配符
server {
    listen 80;
    server_name www.example.*;
}
```

### 正则表达式匹配

```nginx
server {
    listen 80;
    server_name ~^www\d+\.example\.com$;
}

# 捕获变量
server {
    listen 80;
    server_name ~^(www\.)?(?<domain>.+)$;
    root /data/www/$domain;
}
```

### 多个域名

```nginx
server {
    listen 80;
    server_name example.com www.example.com blog.example.com;
}
```

### 默认服务器

```nginx
# 方法1：使用 default_server
server {
    listen 80 default_server;
    server_name _;
    return 444;  # 关闭连接
}

# 方法2：第一个 server 块自动成为默认
server {
    listen 80;
    server_name _;
    root /data/www/default;
}
```

### 匹配优先级

```
1. 精确匹配
2. 前缀通配符（*.example.com）
3. 后缀通配符（www.example.*）
4. 正则表达式（按配置顺序）
5. 默认服务器
```

---

## 域名重定向

### www 重定向到非 www

```nginx
server {
    listen 80;
    server_name www.example.com;
    return 301 http://example.com$request_uri;
}

server {
    listen 80;
    server_name example.com;
    root /data/www/example;
}
```

### 非 www 重定向到 www

```nginx
server {
    listen 80;
    server_name example.com;
    return 301 http://www.example.com$request_uri;
}

server {
    listen 80;
    server_name www.example.com;
    root /data/www/example;
}
```

### 多域名重定向到主域名

```nginx
server {
    listen 80;
    server_name old-domain.com www.old-domain.com;
    return 301 http://new-domain.com$request_uri;
}

server {
    listen 80;
    server_name new-domain.com www.new-domain.com;
    root /data/www/new-domain;
}
```

---

## 子域名配置

### 方法1：独立配置文件

```bash
# blog 子域名
cat > /etc/nginx/conf.d/blog.example.com.conf << 'EOF'
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/blog;
    index index.html;
}
EOF

# api 子域名
cat > /etc/nginx/conf.d/api.example.com.conf << 'EOF'
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://localhost:3000;
    }
}
EOF
```

### 方法2：通配符配置

```nginx
server {
    listen 80;
    server_name ~^(?<subdomain>.+)\.example\.com$;
    root /data/www/$subdomain;
    index index.html;
    
    # blog.example.com -> /data/www/blog
    # shop.example.com -> /data/www/shop
}
```

---

## 完整的虚拟主机配置模板

```nginx
server {
    # 监听端口
    listen 80;
    listen [::]:80;  # IPv6
    
    # 域名
    server_name example.com www.example.com;
    
    # 网站根目录
    root /data/www/example;
    index index.html index.htm index.php;
    
    # 字符集
    charset utf-8;
    
    # 访问日志
    access_log /var/log/nginx/example.com.access.log main;
    error_log /var/log/nginx/example.com.error.log warn;
    
    # 主 location
    location / {
        try_files $uri $uri/ =404;
    }
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止访问备份文件
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 错误页面
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

---

## 实战案例

### 案例1：个人网站 + 博客

```nginx
# 主站
server {
    listen 80;
    server_name example.com www.example.com;
    root /data/www/main;
    index index.html;
    
    access_log /var/log/nginx/main.access.log;
}

# 博客
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/blog;
    index index.html;
    
    access_log /var/log/nginx/blog.access.log;
}
```

### 案例2：多语言网站

```nginx
# 中文站
server {
    listen 80;
    server_name www.example.cn cn.example.com;
    root /data/www/cn;
    index index.html;
    charset utf-8;
}

# 英文站
server {
    listen 80;
    server_name www.example.com en.example.com;
    root /data/www/en;
    index index.html;
    charset utf-8;
}
```

### 案例3：测试环境 + 生产环境

```nginx
# 生产环境
server {
    listen 80;
    server_name www.example.com;
    root /data/www/production;
    index index.html;
}

# 测试环境
server {
    listen 80;
    server_name test.example.com;
    root /data/www/testing;
    index index.html;
    
    # 限制访问
    allow 192.168.1.0/24;
    deny all;
}

# 开发环境
server {
    listen 80;
    server_name dev.example.com;
    root /data/www/development;
    index index.html;
    
    # 基本认证
    auth_basic "Development Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

### 案例4：移动端和PC端分离

```nginx
server {
    listen 80;
    server_name www.example.com;
    
    # 根据 User-Agent 判断
    set $mobile_request 0;
    if ($http_user_agent ~* "mobile|android|iphone|ipad|phone") {
        set $mobile_request 1;
    }
    
    # 移动端重定向
    if ($mobile_request = 1) {
        rewrite ^(.*)$ http://m.example.com$1 permanent;
    }
    
    root /data/www/pc;
    index index.html;
}

# 移动端站点
server {
    listen 80;
    server_name m.example.com;
    root /data/www/mobile;
    index index.html;
}
```

---

## 配置管理最佳实践

### 1. 使用独立配置文件

```bash
# 每个站点一个配置文件
/etc/nginx/conf.d/
├── blog.example.com.conf
├── shop.example.com.conf
├── api.example.com.conf
└── www.example.com.conf
```

### 2. 使用配置模板

```bash
# 创建模板
cat > /etc/nginx/templates/vhost.template << 'EOF'
server {
    listen 80;
    server_name DOMAIN;
    root /data/www/SITENAME;
    index index.html;
    
    access_log /var/log/nginx/SITENAME.access.log;
    error_log /var/log/nginx/SITENAME.error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# 使用模板创建新站点
sed -e 's/DOMAIN/newsite.com/g' \
    -e 's/SITENAME/newsite/g' \
    /etc/nginx/templates/vhost.template \
    > /etc/nginx/conf.d/newsite.com.conf
```

### 3. 使用 include 指令

```nginx
# 主配置文件
http {
    # 通用配置
    include /etc/nginx/conf.d/common/*.conf;
    
    # 虚拟主机
    include /etc/nginx/conf.d/sites/*.conf;
}

# 通用配置示例
# /etc/nginx/conf.d/common/gzip.conf
gzip on;
gzip_types text/plain text/css application/json;

# /etc/nginx/conf.d/common/security.conf
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options "nosniff";
```

### 4. 命名规范

```bash
# 推荐命名方式
domain.com.conf              # 域名.conf
subdomain.domain.com.conf    # 子域名.域名.conf
project-name.conf            # 项目名.conf

# 避免的命名
site1.conf                   # 不清晰
test.conf                    # 太通用
vhost.conf                   # 无意义
```

---

## 故障排查

### 问题1：域名无法访问

```bash
# 检查配置
nginx -t

# 检查 server_name
grep -r "server_name" /etc/nginx/conf.d/

# 检查端口监听
netstat -tuln | grep :80

# 检查防火墙
firewall-cmd --list-all

# 检查 DNS
nslookup domain.com
dig domain.com
```

### 问题2：访问到错误的网站

```bash
# 检查 server 块顺序
cat /etc/nginx/conf.d/*.conf

# 检查 default_server
grep -r "default_server" /etc/nginx/

# 测试域名匹配
curl -H "Host: example.com" http://服务器IP
```

### 问题3：配置不生效

```bash
# 重新加载配置
nginx -s reload

# 如果不行，重启服务
systemctl restart nginx

# 检查配置文件是否被包含
nginx -T | grep "配置文件路径"
```

---

## 练习题

### 基础练习

1. 配置 3 个基于域名的虚拟主机
2. 配置基于端口的虚拟主机
3. 配置 www 到非 www 的重定向
4. 配置子域名访问不同目录
5. 配置默认服务器

### 进阶练习

1. 配置多语言网站（中文、英文）
2. 配置测试环境和生产环境
3. 配置移动端和 PC 端分离
4. 使用正则表达式匹配子域名
5. 创建虚拟主机配置模板

---

## 总结

虚拟主机配置要点：
- ✅ 理解三种虚拟主机类型
- ✅ 掌握 server_name 匹配规则
- ✅ 学会域名重定向
- ✅ 使用独立配置文件管理
- ✅ 遵循命名和组织规范

---

## 下一步

完成虚拟主机学习后，继续学习：
- **03_Nginx反向代理.md**：代理后端应用
- **04_Nginx负载均衡.md**：流量分发

虚拟主机是 Nginx 的基础功能，务必熟练掌握！
