# Nginx 配置 HTTPS

## 准备工作

### 1. 准备证书文件

```bash
# 需要的文件
cert.crt        # 证书文件
cert.key        # 私钥文件
ca-bundle.crt   # 证书链文件（可选）

# 创建证书目录
mkdir -p /etc/nginx/ssl
chmod 700 /etc/nginx/ssl

# 复制证书文件
cp cert.crt /etc/nginx/ssl/
cp cert.key /etc/nginx/ssl/
cp ca-bundle.crt /etc/nginx/ssl/

# 设置权限
chmod 644 /etc/nginx/ssl/cert.crt
chmod 600 /etc/nginx/ssl/cert.key
```

### 2. 检查 Nginx SSL 模块

```bash
# 查看是否编译了 SSL 模块
nginx -V 2>&1 | grep -o with-http_ssl_module

# 如果没有，需要重新编译 Nginx
# 或使用包管理器安装支持 SSL 的版本
```

---

## 基本 HTTPS 配置

### 最简单的配置

```nginx
server {
    listen 443 ssl;
    server_name example.com www.example.com;
    
    # SSL 证书
    ssl_certificate /etc/nginx/ssl/cert.crt;
    ssl_certificate_key /etc/nginx/ssl/cert.key;
    
    # 网站根目录
    root /data/www/example;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}
```

### 测试配置

```bash
# 测试配置文件
nginx -t

# 重新加载
nginx -s reload

# 测试 HTTPS
curl -I https://example.com

# 测试 HTTP 重定向
curl -I http://example.com
```

---

## 完整的 HTTPS 配置

### 推荐配置

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL 证书
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # SSL 协议版本
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # 加密套件
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    
    # SSL 会话缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/nginx/ssl/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # 网站配置
    root /data/www/example;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # 日志
    access_log /var/log/nginx/example.com.access.log;
    error_log /var/log/nginx/example.com.error.log;
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    # ACME 验证（Let's Encrypt）
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
    }
    
    # 其他请求重定向到 HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}
```

---

## SSL 配置详解

### 1. SSL 协议版本

```nginx
# 只使用 TLS 1.2 和 1.3（推荐）
ssl_protocols TLSv1.2 TLSv1.3;

# 兼容旧客户端（不推荐）
ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;

# 只使用 TLS 1.3（最安全，但兼容性差）
ssl_protocols TLSv1.3;
```

### 2. 加密套件

```nginx
# 现代配置（推荐）
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';

# 中等配置（兼容性好）
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA';

# 优先使用服务器加密套件
ssl_prefer_server_ciphers on;
```

### 3. SSL 会话缓存

```nginx
# 共享会话缓存（推荐）
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

# 禁用 Session Tickets（更安全）
ssl_session_tickets off;

# 或启用 Session Tickets
ssl_session_tickets on;
ssl_session_ticket_key /etc/nginx/ssl/ticket.key;
```

### 4. OCSP Stapling

```nginx
# 启用 OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;

# 信任的 CA 证书
ssl_trusted_certificate /etc/nginx/ssl/chain.pem;

# DNS 解析器
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
```

### 5. DH 参数

```bash
# 生成 DH 参数（提高安全性）
openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

# 或 4096 位（更安全但更慢）
openssl dhparam -out /etc/nginx/ssl/dhparam.pem 4096
```

```nginx
# 配置 DH 参数
ssl_dhparam /etc/nginx/ssl/dhparam.pem;
```

---

## HTTP/2 配置

### 启用 HTTP/2

```nginx
server {
    # 同时启用 HTTPS 和 HTTP/2
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    server_name example.com;
    
    ssl_certificate /etc/nginx/ssl/cert.crt;
    ssl_certificate_key /etc/nginx/ssl/cert.key;
    
    # 其他配置...
}
```

### HTTP/2 优化

```nginx
http {
    # HTTP/2 推送
    http2_push_preload on;
    
    # HTTP/2 最大并发流
    http2_max_concurrent_streams 128;
    
    # HTTP/2 最大字段大小
    http2_max_field_size 16k;
    
    # HTTP/2 最大头部大小
    http2_max_header_size 32k;
}
```

---

## 安全头配置

### HSTS（强制 HTTPS）

```nginx
# 基本配置
add_header Strict-Transport-Security "max-age=31536000" always;

# 包含子域名
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# 预加载（提交到浏览器 HSTS 预加载列表）
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

### 其他安全头

```nginx
# 防止点击劫持
add_header X-Frame-Options "SAMEORIGIN" always;

# 防止 MIME 类型嗅探
add_header X-Content-Type-Options "nosniff" always;

# XSS 保护
add_header X-XSS-Protection "1; mode=block" always;

# CSP（内容安全策略）
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;

# Referrer 策略
add_header Referrer-Policy "no-referrer-when-downgrade" always;

# 权限策略
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

---

## 实战案例

### 案例1：静态网站 HTTPS

```nginx
server {
    listen 443 ssl http2;
    server_name blog.example.com;
    
    ssl_certificate /etc/nginx/ssl/blog.crt;
    ssl_certificate_key /etc/nginx/ssl/blog.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    root /data/www/blog;
    index index.html;
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}

server {
    listen 80;
    server_name blog.example.com;
    return 301 https://$server_name$request_uri;
}
```

### 案例2：反向代理 HTTPS

```nginx
upstream backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    ssl_certificate /etc/nginx/ssl/api.crt;
    ssl_certificate_key /etc/nginx/ssl/api.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name api.example.com;
    return 301 https://$server_name$request_uri;
}
```

### 案例3：多域名 HTTPS

```nginx
# 主域名
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    root /data/www/main;
}

# 子域名1
server {
    listen 443 ssl http2;
    server_name blog.example.com;
    
    ssl_certificate /etc/nginx/ssl/blog.example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/blog.example.com.key;
    
    root /data/www/blog;
}

# 子域名2
server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    ssl_certificate /etc/nginx/ssl/api.example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/api.example.com.key;
    
    location / {
        proxy_pass http://localhost:8080;
    }
}

# HTTP 重定向
server {
    listen 80;
    server_name example.com www.example.com blog.example.com api.example.com;
    return 301 https://$host$request_uri;
}
```

### 案例4：通配符证书

```nginx
# 使用通配符证书保护所有子域名
server {
    listen 443 ssl http2 default_server;
    server_name *.example.com;
    
    # 通配符证书
    ssl_certificate /etc/nginx/ssl/wildcard.example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/wildcard.example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # 根据子域名路由
    set $subdomain "";
    if ($host ~* "^(.+)\.example\.com$") {
        set $subdomain $1;
    }
    
    root /data/www/$subdomain;
    index index.html;
}
```

---

## SSL 配置模板

### 通用 SSL 配置

```nginx
# 创建通用 SSL 配置文件
# /etc/nginx/conf.d/ssl-common.conf

# SSL 协议和加密套件
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers on;

# SSL 会话缓存
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;

# DH 参数
ssl_dhparam /etc/nginx/ssl/dhparam.pem;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# 安全头
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

### 使用通用配置

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    # 包含通用 SSL 配置
    include /etc/nginx/conf.d/ssl-common.conf;
    
    root /data/www/example;
}
```

---

## 性能优化

### 1. 启用 SSL 会话复用

```nginx
ssl_session_cache shared:SSL:50m;
ssl_session_timeout 1d;
```

### 2. 启用 HTTP/2

```nginx
listen 443 ssl http2;
```

### 3. 启用 OCSP Stapling

```nginx
ssl_stapling on;
ssl_stapling_verify on;
```

### 4. 使用 KeepAlive

```nginx
keepalive_timeout 65;
keepalive_requests 100;
```

### 5. 启用 Gzip 压缩

```nginx
gzip on;
gzip_vary on;
gzip_types text/plain text/css application/json application/javascript;
```

---

## 测试和验证

### 在线测试工具

```bash
# SSL Labs（最权威）
https://www.ssllabs.com/ssltest/

# 目标：A+ 评级

# 其他工具
https://www.sslshopper.com/ssl-checker.html
https://www.digicert.com/help/
```

### 命令行测试

```bash
# 测试 SSL 连接
openssl s_client -connect example.com:443 -servername example.com

# 测试 TLS 版本
openssl s_client -connect example.com:443 -tls1_2
openssl s_client -connect example.com:443 -tls1_3

# 测试证书链
openssl s_client -connect example.com:443 -showcerts

# 测试 OCSP Stapling
openssl s_client -connect example.com:443 -status

# 使用 curl 测试
curl -I https://example.com
curl -v https://example.com
```

### 浏览器测试

```
1. 打开网站
2. 点击地址栏的锁图标
3. 查看证书信息
4. 检查连接安全性
```

---

## 故障排查

### 问题1：证书不被信任

```bash
# 原因
1. 自签名证书
2. 证书过期
3. 证书链不完整
4. 域名不匹配

# 解决
# 检查证书
openssl x509 -in cert.crt -text -noout

# 检查证书链
openssl verify -CAfile ca-bundle.crt cert.crt

# 确保配置了完整证书链
ssl_certificate /etc/nginx/ssl/fullchain.pem;
```

### 问题2：SSL 握手失败

```bash
# 查看错误日志
tail -f /var/log/nginx/error.log

# 常见原因
1. 证书和私钥不匹配
2. 私钥权限错误
3. SSL 协议版本不支持

# 验证证书和私钥
openssl x509 -noout -modulus -in cert.crt | openssl md5
openssl rsa -noout -modulus -in cert.key | openssl md5

# 检查私钥权限
ls -l /etc/nginx/ssl/cert.key
chmod 600 /etc/nginx/ssl/cert.key
```

### 问题3：Mixed Content（混合内容）

```bash
# 原因
HTTPS 页面加载 HTTP 资源

# 解决
# 1. 所有资源使用 HTTPS
<script src="https://example.com/script.js"></script>

# 2. 使用协议相对 URL
<script src="//example.com/script.js"></script>

# 3. 使用 CSP 头自动升级
add_header Content-Security-Policy "upgrade-insecure-requests" always;
```

### 问题4：性能问题

```bash
# 启用会话复用
ssl_session_cache shared:SSL:50m;

# 启用 HTTP/2
listen 443 ssl http2;

# 启用 OCSP Stapling
ssl_stapling on;

# 使用 CDN
```

---

## 练习题

### 基础练习

1. 使用自签名证书配置 HTTPS
2. 配置 HTTP 到 HTTPS 的重定向
3. 配置 HSTS 头
4. 测试 HTTPS 连接
5. 查看网站的 SSL 评级

### 进阶练习

1. 配置完整的 SSL 安全参数
2. 启用 HTTP/2
3. 配置 OCSP Stapling
4. 配置多域名 HTTPS
5. 优化 SSL 性能
6. 配置所有安全头

---

## 总结

Nginx HTTPS 配置要点：
- ✅ 正确配置证书和私钥
- ✅ 使用 TLS 1.2/1.3
- ✅ 配置强加密套件
- ✅ 启用会话缓存
- ✅ 配置安全头（HSTS 等）
- ✅ 启用 HTTP/2
- ✅ 测试和验证配置

---

## 下一步

完成 Nginx HTTPS 配置后，继续学习：
- **03_Let's Encrypt实战.md**：使用免费证书

HTTPS 是现代网站的标配，务必熟练掌握！
