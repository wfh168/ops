# Nginx 学习指南

## 学习路线

```
01_Nginx安装与基础.md    ──▶  掌握 Nginx 基本使用
        │
        ▼
02_Nginx虚拟主机.md      ──▶  配置多站点
        │
        ▼
03_Nginx反向代理.md      ──▶  代理后端应用
        │
        ▼
04_Nginx负载均衡.md      ──▶  流量分发和高可用
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_Nginx安装与基础.md | 安装、配置、location 匹配 | 1 天 |
| 02_Nginx虚拟主机.md | 多站点配置、域名管理 | 1 天 |
| 03_Nginx反向代理.md | 代理后端服务、WebSocket | 1.5 天 |
| 04_Nginx负载均衡.md | 负载均衡算法、高可用 | 1.5 天 |

## 核心知识点

### Nginx 基础
- Nginx 安装和目录结构
- 配置文件结构（全局、events、http、server、location）
- location 匹配规则
- 常用命令和日志管理
- 静态网站部署

### 虚拟主机
- 基于域名的虚拟主机
- 基于端口的虚拟主机
- 基于 IP 的虚拟主机
- server_name 匹配规则
- 域名重定向
- 子域名配置

### 反向代理
- proxy_pass 配置
- proxy_set_header 设置
- 超时和缓冲配置
- WebSocket 代理
- 代理缓存
- 错误处理

### 负载均衡
- 6 种负载均衡算法
- upstream 配置
- 健康检查
- 会话保持
- 高可用架构

## 常用命令速查

### 服务管理

```bash
nginx                                      # 启动
nginx -s stop                              # 快速停止
nginx -s quit                              # 优雅停止
nginx -s reload                            # 重新加载配置
nginx -t                                   # 测试配置
nginx -T                                   # 测试并显示配置
nginx -v                                   # 查看版本
nginx -V                                   # 查看版本和编译参数

systemctl start nginx                      # 启动服务
systemctl stop nginx                       # 停止服务
systemctl restart nginx                    # 重启服务
systemctl reload nginx                     # 重新加载
systemctl status nginx                     # 查看状态
systemctl enable nginx                     # 开机自启
```

### 进程管理

```bash
ps aux | grep nginx                        # 查看进程
netstat -tuln | grep 80                    # 查看端口
ss -tuln | grep 80                         # 查看端口（推荐）
kill -QUIT $(cat /var/run/nginx.pid)      # 优雅停止
kill -HUP $(cat /var/run/nginx.pid)       # 重新加载配置
```

### 日志管理

```bash
tail -f /var/log/nginx/access.log          # 实时查看访问日志
tail -f /var/log/nginx/error.log           # 实时查看错误日志
logrotate -f /etc/logrotate.d/nginx        # 手动切割日志
```

## 配置文件模板

### 静态网站

```nginx
server {
    listen 80;
    server_name www.example.com;
    root /data/www/example;
    index index.html index.htm;
    
    access_log /var/log/nginx/example.access.log;
    error_log /var/log/nginx/example.error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### 反向代理

```nginx
upstream backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### 负载均衡

```nginx
upstream backend {
    least_conn;
    
    server 192.168.1.101:8080 weight=3 max_fails=2 fail_timeout=30s;
    server 192.168.1.102:8080 weight=2 max_fails=2 fail_timeout=30s;
    server 192.168.1.103:8080 weight=1 max_fails=2 fail_timeout=30s;
    server 192.168.1.104:8080 backup;
    
    keepalive 32;
}

server {
    listen 80;
    server_name www.example.com;
    
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 前后端分离

```nginx
upstream api_backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

server {
    listen 80;
    server_name www.example.com;
    
    # 前端静态文件
    location / {
        root /data/www/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # 后端 API
    location /api/ {
        proxy_pass http://api_backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 静态资源缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        root /data/www/frontend/dist;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

## location 匹配规则速查

| 符号 | 说明 | 优先级 | 示例 |
|------|------|--------|------|
| = | 精确匹配 | 1（最高） | location = / { } |
| ^~ | 前缀匹配 | 2 | location ^~ /static/ { } |
| ~ | 正则（区分大小写） | 3 | location ~ \.php$ { } |
| ~* | 正则（不区分大小写） | 3 | location ~* \.(jpg\|png)$ { } |
| / | 通用匹配 | 4（最低） | location / { } |

## 负载均衡算法速查

| 算法 | 指令 | 说明 | 适用场景 |
|------|------|------|----------|
| 轮询 | 默认 | 依次分配 | 服务器性能相同 |
| 加权轮询 | weight | 按权重分配 | 服务器性能不同 |
| IP Hash | ip_hash | 同 IP 到同服务器 | 需要会话保持 |
| 最少连接 | least_conn | 连接数最少优先 | 请求处理时间差异大 |
| 哈希 | hash | 按键哈希 | 缓存场景 |
| 随机 | random | 随机选择 | 简单场景 |

## 实战场景

### 场景1：部署静态博客

```bash
# 1. 创建目录
mkdir -p /data/www/blog

# 2. 上传网站文件到 /data/www/blog

# 3. 配置 Nginx
cat > /etc/nginx/conf.d/blog.conf << 'EOF'
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/blog;
    index index.html;
    
    location ~* \.(jpg|jpeg|png|gif|css|js)$ {
        expires 30d;
    }
}
EOF

# 4. 测试并重载
nginx -t && nginx -s reload
```

### 场景2：代理 Node.js 应用

```bash
# 1. Node.js 应用运行在 3000 端口
# pm2 start app.js

# 2. 配置 Nginx
cat > /etc/nginx/conf.d/nodejs.conf << 'EOF'
server {
    listen 80;
    server_name app.example.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# 3. 测试并重载
nginx -t && nginx -s reload
```

### 场景3：负载均衡 Web 集群

```bash
cat > /etc/nginx/conf.d/lb.conf << 'EOF'
upstream web_cluster {
    least_conn;
    
    server 192.168.1.101:8080 weight=3;
    server 192.168.1.102:8080 weight=2;
    server 192.168.1.103:8080 weight=1;
    server 192.168.1.104:8080 backup;
    
    keepalive 32;
}

server {
    listen 80;
    server_name www.example.com;
    
    location / {
        proxy_pass http://web_cluster;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

nginx -t && nginx -s reload
```

## 性能优化建议

### 1. 工作进程优化

```nginx
# 自动设置为 CPU 核心数
worker_processes auto;

# 绑定到 CPU
worker_cpu_affinity auto;

# 单个进程最大连接数
events {
    worker_connections 10240;
    use epoll;
}
```

### 2. 连接优化

```nginx
http {
    # 长连接
    keepalive_timeout 65;
    keepalive_requests 100;
    
    # TCP 优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
}
```

### 3. 缓存优化

```nginx
# 静态文件缓存
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}

# 代理缓存
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;

location / {
    proxy_cache my_cache;
    proxy_cache_valid 200 10m;
}
```

### 4. 压缩优化

```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
```

## 安全配置

### 1. 隐藏版本号

```nginx
http {
    server_tokens off;
}
```

### 2. 限制请求方法

```nginx
if ($request_method !~ ^(GET|POST|HEAD)$) {
    return 405;
}
```

### 3. 防止 DDoS

```nginx
# 限制连接数
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
limit_conn conn_limit 10;

# 限制请求速率
limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;
limit_req zone=req_limit burst=20 nodelay;
```

### 4. 安全头

```nginx
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options "nosniff";
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=31536000";
```

## 故障排查

### 常见问题

```bash
# 1. 配置测试失败
nginx -t
# 查看具体错误信息

# 2. 502 Bad Gateway
# 检查后端服务是否运行
curl http://localhost:8080
# 检查 SELinux
setsebool -P httpd_can_network_connect 1

# 3. 504 Gateway Timeout
# 增加超时时间
proxy_connect_timeout 300s;
proxy_read_timeout 300s;

# 4. 403 Forbidden
# 检查文件权限
ls -la /data/www/
chmod 755 /data/www/
chown -R nginx:nginx /data/www/

# 5. 查看日志
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

## 练习题

### 基础练习

1. 安装 Nginx 并部署静态网站
2. 配置 3 个基于域名的虚拟主机
3. 配置反向代理到本地 8080 端口
4. 配置 3 台服务器的负载均衡
5. 配置静态文件缓存

### 进阶练习

1. 配置前后端分离项目
2. 配置 API 网关（多个后端服务）
3. 配置动静分离 + 负载均衡
4. 配置 WebSocket 代理
5. 配置代理缓存
6. 配置限流和安全防护
7. 搭建 Nginx + Keepalived 高可用

## 面试常考

1. Nginx 和 Apache 的区别？
2. Nginx 的工作原理？
3. location 匹配规则和优先级？
4. 如何配置反向代理？
5. 负载均衡有哪些算法？
6. 如何实现会话保持？
7. 如何优化 Nginx 性能？
8. 502 和 504 错误的区别和解决方法？
9. 如何实现灰度发布？
10. 如何搭建 Nginx 高可用架构？

## 学习建议

### 1. 实践为主

- 搭建测试环境（虚拟机或云服务器）
- 每个配置都要亲自操作
- 记录遇到的问题和解决方法

### 2. 循序渐进

- 先掌握基础配置
- 再学习反向代理
- 最后学习负载均衡和高可用

### 3. 项目驱动

- 部署实际项目（博客、API、Web 应用）
- 模拟生产环境
- 解决实际问题

### 4. 阅读文档

- 官方文档是最好的学习资料
- 理解每个指令的作用
- 学习最佳实践

## 推荐资源

### 官方文档

- [Nginx 官方文档](http://nginx.org/en/docs/)
- [Nginx 中文文档](https://www.nginx.cn/doc/)

### 推荐书籍

- 《Nginx 高性能 Web 服务器详解》
- 《深入理解 Nginx》
- 《Nginx HTTP Server》

### 在线资源

- [Nginx 配置生成器](https://nginxconfig.io/)
- [Nginx 测试工具](https://github.com/lebinh/ngxtop)
- DigitalOcean Nginx 教程

## 下一步

完成 Nginx 学习后，继续学习：
- **HTTPS 加密**：SSL/TLS 证书配置
- **Rewrite 重写**：URL 重写规则
- **Nginx 性能优化**：深度调优

Nginx 是运维工程师的核心技能，也是面试的重点，务必熟练掌握！

加油！💪
