# Nginx 反向代理

## 什么是反向代理？

### 正向代理 vs 反向代理

```
正向代理（Forward Proxy）
客户端 → 代理服务器 → 目标服务器
用途：客户端访问外部资源（如科学上网）

反向代理（Reverse Proxy）
客户端 → 代理服务器 → 后端服务器
用途：保护后端服务器，负载均衡
```

### 反向代理的优势

- **隐藏后端服务器**：客户端不知道真实服务器
- **负载均衡**：分发请求到多台服务器
- **缓存静态内容**：减轻后端压力
- **SSL 终止**：在代理层处理 HTTPS
- **安全防护**：统一入口，易于防护
- **压缩优化**：统一处理 gzip 压缩

---

## 基本反向代理配置

### 最简单的反向代理

```nginx
server {
    listen 80;
    server_name example.com;
    
    location / {
        proxy_pass http://localhost:8080;
    }
}
```

### 完整的反向代理配置

```nginx
server {
    listen 80;
    server_name example.com;
    
    location / {
        # 代理目标
        proxy_pass http://backend_server;
        
        # 传递客户端真实 IP
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 缓冲设置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
}
```

---

## proxy_pass 详解

### 基本用法

```nginx
# 代理到后端服务器
location / {
    proxy_pass http://192.168.1.100:8080;
}

# 代理到 upstream
location / {
    proxy_pass http://backend;
}
```

### URI 处理

```nginx
# 不带 URI（保留原始路径）
location /api/ {
    proxy_pass http://backend;
}
# 请求：/api/users
# 转发：http://backend/api/users

# 带 URI（替换路径）
location /api/ {
    proxy_pass http://backend/;
}
# 请求：/api/users
# 转发：http://backend/users

# 带路径的 URI
location /api/ {
    proxy_pass http://backend/v1/;
}
# 请求：/api/users
# 转发：http://backend/v1/users
```

### 动态代理

```nginx
# 使用变量
location / {
    set $backend "http://192.168.1.100:8080";
    proxy_pass $backend;
}

# 根据条件代理
location / {
    if ($request_uri ~* "^/api") {
        proxy_pass http://api_backend;
    }
    if ($request_uri ~* "^/admin") {
        proxy_pass http://admin_backend;
    }
}
```

---

## proxy_set_header 详解

### 常用请求头

```nginx
location / {
    proxy_pass http://backend;
    
    # Host：原始请求的主机名
    proxy_set_header Host $host;
    
    # X-Real-IP：客户端真实 IP
    proxy_set_header X-Real-IP $remote_addr;
    
    # X-Forwarded-For：客户端 IP 链
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    
    # X-Forwarded-Proto：原始协议（http/https）
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # X-Forwarded-Host：原始主机名
    proxy_set_header X-Forwarded-Host $host;
    
    # X-Forwarded-Port：原始端口
    proxy_set_header X-Forwarded-Port $server_port;
    
    # Connection：连接类型
    proxy_set_header Connection "";
    
    # 自定义头
    proxy_set_header X-Custom-Header "value";
}
```

### 为什么需要这些头？

```
客户端 → Nginx → 后端应用

没有设置头：
后端看到的 IP：Nginx 的 IP（127.0.0.1）
后端看到的 Host：backend（upstream 名称）

设置头后：
后端看到的 IP：客户端真实 IP
后端看到的 Host：原始域名
```

---

## 代理超时设置

```nginx
location / {
    proxy_pass http://backend;
    
    # 连接超时（与后端建立连接）
    proxy_connect_timeout 60s;
    
    # 发送超时（发送请求到后端）
    proxy_send_timeout 60s;
    
    # 读取超时（从后端读取响应）
    proxy_read_timeout 60s;
    
    # 下一个上游超时
    proxy_next_upstream_timeout 0;
    proxy_next_upstream_tries 0;
}
```

---

## 代理缓冲设置

```nginx
location / {
    proxy_pass http://backend;
    
    # 启用缓冲
    proxy_buffering on;
    
    # 缓冲区大小（响应头）
    proxy_buffer_size 4k;
    
    # 缓冲区数量和大小（响应体）
    proxy_buffers 8 4k;
    
    # 繁忙缓冲区大小
    proxy_busy_buffers_size 8k;
    
    # 临时文件大小
    proxy_temp_file_write_size 8k;
    
    # 最大临时文件大小
    proxy_max_temp_file_size 1024m;
}
```

---

## 实战案例

### 案例1：代理 Node.js 应用

```nginx
# Node.js 运行在 3000 端口
server {
    listen 80;
    server_name app.example.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # WebSocket 支持
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 传递真实信息
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 静态文件直接由 Nginx 处理
    location /static/ {
        alias /data/app/static/;
        expires 30d;
    }
}
```

### 案例2：代理 Java 应用（Tomcat）

```nginx
server {
    listen 80;
    server_name java.example.com;
    
    location / {
        proxy_pass http://localhost:8080;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # Tomcat 需要较长超时
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
```

### 案例3：代理 Python 应用（Django/Flask）

```nginx
server {
    listen 80;
    server_name python.example.com;
    
    location / {
        # 使用 uWSGI 协议
        include uwsgi_params;
        uwsgi_pass unix:/run/uwsgi/app.sock;
        
        # 或使用 HTTP
        # proxy_pass http://localhost:8000;
    }
    
    location /static/ {
        alias /data/python-app/static/;
    }
    
    location /media/ {
        alias /data/python-app/media/;
    }
}
```

### 案例4：API 网关

```nginx
server {
    listen 80;
    server_name api.example.com;
    
    # 用户服务
    location /api/users/ {
        proxy_pass http://user-service:8001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 订单服务
    location /api/orders/ {
        proxy_pass http://order-service:8002/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 支付服务
    location /api/payment/ {
        proxy_pass http://payment-service:8003/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 案例5：前后端分离

```nginx
server {
    listen 80;
    server_name www.example.com;
    
    # 前端（Vue/React）
    location / {
        root /data/www/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # 后端 API
    location /api/ {
        proxy_pass http://backend:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 代理缓存

### 配置代理缓存

```nginx
# http 块中配置缓存路径
http {
    proxy_cache_path /var/cache/nginx/proxy
                     levels=1:2
                     keys_zone=my_cache:10m
                     max_size=1g
                     inactive=60m
                     use_temp_path=off;
    
    server {
        listen 80;
        server_name example.com;
        
        location / {
            proxy_pass http://backend;
            
            # 启用缓存
            proxy_cache my_cache;
            
            # 缓存状态码和时间
            proxy_cache_valid 200 304 10m;
            proxy_cache_valid 404 1m;
            
            # 缓存键
            proxy_cache_key $scheme$proxy_host$request_uri;
            
            # 添加缓存状态头
            add_header X-Cache-Status $upstream_cache_status;
            
            # 缓存锁
            proxy_cache_lock on;
            proxy_cache_lock_timeout 5s;
            
            # 后端错误时使用缓存
            proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        }
        
        # 清除缓存接口
        location /purge/ {
            allow 127.0.0.1;
            deny all;
            proxy_cache_purge my_cache $scheme$proxy_host$request_uri;
        }
    }
}
```

### 缓存状态

```
HIT：缓存命中
MISS：缓存未命中
EXPIRED：缓存过期
STALE：使用过期缓存
UPDATING：正在更新缓存
REVALIDATED：缓存重新验证
BYPASS：跳过缓存
```

---

## 错误处理

### 后端错误处理

```nginx
location / {
    proxy_pass http://backend;
    
    # 后端错误时的处理
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    proxy_next_upstream_tries 2;
    proxy_next_upstream_timeout 10s;
    
    # 自定义错误页面
    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

### 拦截后端错误

```nginx
location / {
    proxy_pass http://backend;
    
    # 拦截后端错误
    proxy_intercept_errors on;
    
    # 自定义错误页面
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
```

---

## WebSocket 代理

```nginx
server {
    listen 80;
    server_name ws.example.com;
    
    location / {
        proxy_pass http://websocket_backend;
        
        # WebSocket 必需配置
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 其他配置
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # 超时设置（WebSocket 需要较长超时）
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
```

---

## 代理优化

### 1. 连接复用

```nginx
upstream backend {
    server 192.168.1.100:8080;
    
    # 保持连接
    keepalive 32;
    keepalive_timeout 60s;
    keepalive_requests 100;
}

server {
    location / {
        proxy_pass http://backend;
        
        # 使用 HTTP/1.1
        proxy_http_version 1.1;
        
        # 清除 Connection 头
        proxy_set_header Connection "";
    }
}
```

### 2. 禁用缓冲（实时流）

```nginx
location /stream {
    proxy_pass http://backend;
    
    # 禁用缓冲
    proxy_buffering off;
    
    # 禁用缓存
    proxy_cache off;
    
    # 立即发送
    proxy_request_buffering off;
}
```

### 3. 限流

```nginx
# http 块
http {
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    server {
        location /api/ {
            limit_req zone=api_limit burst=20 nodelay;
            proxy_pass http://backend;
        }
    }
}
```

---

## 安全配置

### 1. 隐藏后端信息

```nginx
location / {
    proxy_pass http://backend;
    
    # 隐藏后端服务器头
    proxy_hide_header X-Powered-By;
    proxy_hide_header Server;
    
    # 添加安全头
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
}
```

### 2. IP 白名单

```nginx
location /admin/ {
    # 只允许特定 IP
    allow 192.168.1.0/24;
    allow 10.0.0.1;
    deny all;
    
    proxy_pass http://backend;
}
```

### 3. 请求体大小限制

```nginx
location /upload {
    # 限制上传大小
    client_max_body_size 10m;
    
    proxy_pass http://backend;
}
```

---

## 故障排查

### 问题1：502 Bad Gateway

```bash
# 原因
1. 后端服务未启动
2. 防火墙阻止
3. SELinux 阻止
4. 超时设置太短

# 排查
# 检查后端服务
curl http://localhost:8080

# 检查 SELinux
getsebool -a | grep httpd
setsebool -P httpd_can_network_connect 1

# 查看错误日志
tail -f /var/log/nginx/error.log
```

### 问题2：504 Gateway Timeout

```bash
# 原因
后端响应太慢

# 解决
# 增加超时时间
proxy_connect_timeout 300s;
proxy_send_timeout 300s;
proxy_read_timeout 300s;
```

### 问题3：客户端 IP 丢失

```bash
# 检查配置
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

# 后端获取真实 IP
# PHP
$_SERVER['HTTP_X_REAL_IP']
$_SERVER['HTTP_X_FORWARDED_FOR']

# Node.js
req.headers['x-real-ip']
req.headers['x-forwarded-for']
```

---

## 练习题

### 基础练习

1. 配置反向代理到本地 8080 端口
2. 配置传递客户端真实 IP
3. 配置代理超时时间
4. 配置 WebSocket 代理
5. 配置自定义错误页面

### 进阶练习

1. 配置 API 网关（多个后端服务）
2. 配置前后端分离项目
3. 配置代理缓存
4. 配置连接复用优化
5. 配置限流和安全防护

---

## 总结

反向代理核心要点：
- ✅ 理解 proxy_pass 的 URI 处理
- ✅ 正确设置 proxy_set_header
- ✅ 合理配置超时和缓冲
- ✅ 掌握 WebSocket 代理
- ✅ 学会故障排查

---

## 下一步

完成反向代理学习后，继续学习：
- **04_Nginx负载均衡.md**：流量分发和高可用

反向代理是 Nginx 最重要的功能之一，务必熟练掌握！
