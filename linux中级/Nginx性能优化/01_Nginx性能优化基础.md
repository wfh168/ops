# Nginx 性能优化基础

## 性能优化概述

Nginx 性能优化是一个系统工程，涉及多个方面：

```
性能优化
    │
    ├─ 系统层面（操作系统、内核参数）
    ├─ Nginx 配置（工作进程、连接数、缓存）
    ├─ 网络层面（TCP、HTTP/2）
    └─ 应用层面（静态资源、压缩、CDN）
```

---

## 性能指标

### 关键指标

```
1. QPS（Queries Per Second）
   每秒查询数，衡量并发处理能力

2. 响应时间（Response Time）
   请求到响应的时间

3. 并发连接数（Concurrent Connections）
   同时处理的连接数

4. 吞吐量（Throughput）
   单位时间内传输的数据量

5. CPU 使用率
   处理器负载

6. 内存使用率
   内存占用情况
```

### 性能测试工具

```bash
# Apache Bench（ab）
ab -n 10000 -c 100 http://example.com/

# wrk（推荐）
wrk -t4 -c100 -d30s http://example.com/

# siege
siege -c 100 -t 30s http://example.com/

# 查看实时连接
watch -n 1 'netstat -an | grep :80 | wc -l'
```

---

## 工作进程优化

### worker_processes

```nginx
# 自动设置为 CPU 核心数（推荐）
worker_processes auto;

# 或手动设置
worker_processes 4;

# 查看 CPU 核心数
grep processor /proc/cpuinfo | wc -l
```

### worker_cpu_affinity

```nginx
# 绑定工作进程到 CPU 核心
# 4 核 CPU
worker_processes 4;
worker_cpu_affinity 0001 0010 0100 1000;

# 8 核 CPU
worker_processes 8;
worker_cpu_affinity 00000001 00000010 00000100 00001000 00010000 00100000 01000000 10000000;

# 自动绑定（推荐）
worker_cpu_affinity auto;
```

### worker_priority

```nginx
# 设置工作进程优先级（-20 到 19，越小优先级越高）
worker_priority -10;

# 默认值为 0
```

### worker_rlimit_nofile

```nginx
# 单个工作进程可以打开的最大文件描述符数
worker_rlimit_nofile 65535;

# 应该大于 worker_connections
```

---

## 连接优化

### events 块配置

```nginx
events {
    # 使用 epoll 事件模型（Linux 推荐）
    use epoll;
    
    # 单个工作进程的最大连接数
    worker_connections 10240;
    
    # 允许同时接受多个连接
    multi_accept on;
    
    # 接受连接的互斥锁
    accept_mutex off;
}

# 理论最大并发连接数
# max_clients = worker_processes * worker_connections
```

### 连接超时

```nginx
http {
    # 客户端连接超时
    keepalive_timeout 65;
    
    # 客户端请求头超时
    client_header_timeout 60;
    
    # 客户端请求体超时
    client_body_timeout 60;
    
    # 发送响应超时
    send_timeout 60;
    
    # 长连接请求数
    keepalive_requests 100;
}
```

---

## 缓冲区优化

### 客户端缓冲区

```nginx
http {
    # 客户端请求头缓冲区
    client_header_buffer_size 4k;
    large_client_header_buffers 4 8k;
    
    # 客户端请求体缓冲区
    client_body_buffer_size 128k;
    
    # 客户端最大请求体大小
    client_max_body_size 10m;
}
```

### 代理缓冲区

```nginx
http {
    # 启用代理缓冲
    proxy_buffering on;
    
    # 代理缓冲区大小
    proxy_buffer_size 4k;
    proxy_buffers 8 4k;
    proxy_busy_buffers_size 8k;
    
    # 临时文件
    proxy_temp_file_write_size 8k;
    proxy_max_temp_file_size 1024m;
}
```

### FastCGI 缓冲区

```nginx
http {
    # FastCGI 缓冲
    fastcgi_buffering on;
    
    # 缓冲区大小
    fastcgi_buffer_size 4k;
    fastcgi_buffers 8 4k;
    fastcgi_busy_buffers_size 8k;
    
    # 临时文件
    fastcgi_temp_file_write_size 8k;
    fastcgi_max_temp_file_size 1024m;
}
```

---

## TCP 优化

### sendfile

```nginx
http {
    # 启用 sendfile（零拷贝）
    sendfile on;
    
    # 在一个数据包中发送响应头
    tcp_nopush on;
    
    # 禁用 Nagle 算法
    tcp_nodelay on;
}
```

### 工作原理

```
传统方式：
磁盘 → 内核缓冲区 → 用户空间 → 内核缓冲区 → 网卡
（4 次拷贝，2 次上下文切换）

sendfile：
磁盘 → 内核缓冲区 → 网卡
（2 次拷贝，无上下文切换）
```

---

## 压缩优化

### Gzip 压缩

```nginx
http {
    # 启用 gzip
    gzip on;
    
    # 压缩级别（1-9，推荐 5-6）
    gzip_comp_level 6;
    
    # 最小压缩文件大小
    gzip_min_length 1024;
    
    # 压缩类型
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/rss+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;
    
    # 为代理请求启用压缩
    gzip_proxied any;
    
    # 添加 Vary: Accept-Encoding 头
    gzip_vary on;
    
    # 禁用 IE6 的 gzip
    gzip_disable "msie6";
    
    # 压缩缓冲区
    gzip_buffers 16 8k;
    
    # HTTP 版本
    gzip_http_version 1.1;
}
```

### Gzip 静态压缩

```nginx
http {
    # 启用预压缩文件
    gzip_static on;
}

# 预先压缩文件
# style.css → style.css.gz
# script.js → script.js.gz

# Nginx 会自动查找 .gz 文件
```

---

## 缓存优化

### 静态文件缓存

```nginx
server {
    # 图片缓存
    location ~* \.(jpg|jpeg|png|gif|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # CSS/JS 缓存
    location ~* \.(css|js)$ {
        expires 7d;
        add_header Cache-Control "public";
    }
    
    # 字体缓存
    location ~* \.(woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 代理缓存

```nginx
http {
    # 缓存路径配置
    proxy_cache_path /var/cache/nginx/proxy
                     levels=1:2
                     keys_zone=my_cache:10m
                     max_size=1g
                     inactive=60m
                     use_temp_path=off;
    
    server {
        location / {
            proxy_pass http://backend;
            
            # 启用缓存
            proxy_cache my_cache;
            
            # 缓存有效期
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
    }
}
```

### FastCGI 缓存

```nginx
http {
    # FastCGI 缓存路径
    fastcgi_cache_path /var/cache/nginx/fastcgi
                       levels=1:2
                       keys_zone=php_cache:10m
                       max_size=1g
                       inactive=60m;
    
    server {
        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            
            # 启用缓存
            fastcgi_cache php_cache;
            
            # 缓存有效期
            fastcgi_cache_valid 200 10m;
            
            # 缓存键
            fastcgi_cache_key $scheme$request_method$host$request_uri;
            
            # 添加缓存状态头
            add_header X-Cache-Status $upstream_cache_status;
            
            # 跳过缓存条件
            set $skip_cache 0;
            
            if ($request_method = POST) {
                set $skip_cache 1;
            }
            
            if ($query_string != "") {
                set $skip_cache 1;
            }
            
            fastcgi_cache_bypass $skip_cache;
            fastcgi_no_cache $skip_cache;
        }
    }
}
```

---

## open_file_cache

### 文件描述符缓存

```nginx
http {
    # 启用文件缓存
    open_file_cache max=10000 inactive=60s;
    
    # 验证缓存有效性的时间间隔
    open_file_cache_valid 30s;
    
    # 最小访问次数
    open_file_cache_min_uses 2;
    
    # 缓存错误
    open_file_cache_errors on;
}
```

### 参数说明

```
max=10000        # 最大缓存数量
inactive=60s     # 60 秒内未访问的缓存将被清除
valid=30s        # 30 秒后验证缓存是否有效
min_uses=2       # 访问 2 次以上才缓存
errors=on        # 缓存文件查找错误
```

---

## 日志优化

### 访问日志优化

```nginx
http {
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    # 日志缓冲
    access_log /var/log/nginx/access.log main buffer=32k flush=5s;
    
    # 静态文件不记录日志
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        access_log off;
    }
    
    # 健康检查不记录日志
    location /health {
        access_log off;
        return 200 "OK\n";
    }
}
```

### 错误日志优化

```nginx
# 只记录 error 级别以上的日志
error_log /var/log/nginx/error.log error;

# 日志级别：debug | info | notice | warn | error | crit | alert | emerg
```

---

## 限流和限速

### 限制请求速率

```nginx
http {
    # 定义限流区域
    limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;
    
    server {
        location /api/ {
            # 应用限流
            limit_req zone=req_limit burst=20 nodelay;
            
            proxy_pass http://backend;
        }
    }
}
```

### 限制连接数

```nginx
http {
    # 定义限连区域
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
    
    server {
        # 限制每个 IP 的连接数
        limit_conn conn_limit 10;
        
        location /download/ {
            # 限制下载速度
            limit_rate 1m;
            
            # 下载 10MB 后开始限速
            limit_rate_after 10m;
        }
    }
}
```

---

## 完整优化配置示例

```nginx
# 全局配置
user nginx;
worker_processes auto;
worker_cpu_affinity auto;
worker_priority -10;
worker_rlimit_nofile 65535;

error_log /var/log/nginx/error.log error;
pid /var/run/nginx.pid;

# 事件配置
events {
    use epoll;
    worker_connections 10240;
    multi_accept on;
    accept_mutex off;
}

# HTTP 配置
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main buffer=32k flush=5s;
    
    # TCP 优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    
    # 连接优化
    keepalive_timeout 65;
    keepalive_requests 100;
    
    # 缓冲区优化
    client_header_buffer_size 4k;
    large_client_header_buffers 4 8k;
    client_body_buffer_size 128k;
    client_max_body_size 10m;
    
    # Gzip 压缩
    gzip on;
    gzip_comp_level 6;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_vary on;
    gzip_disable "msie6";
    
    # 文件缓存
    open_file_cache max=10000 inactive=60s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
    
    # 代理缓存
    proxy_cache_path /var/cache/nginx/proxy levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;
    
    # 限流
    limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
    
    # 隐藏版本号
    server_tokens off;
    
    # 包含虚拟主机配置
    include /etc/nginx/conf.d/*.conf;
}
```

---

## 性能测试

### 测试前准备

```bash
# 1. 确保系统资源充足
free -h
df -h

# 2. 调整系统参数
ulimit -n 65535

# 3. 重启 Nginx
nginx -t && nginx -s reload
```

### 使用 ab 测试

```bash
# 基本测试
ab -n 10000 -c 100 http://example.com/

# 参数说明
-n 10000    # 总请求数
-c 100      # 并发数
-t 30       # 测试时间（秒）
-k          # 启用 KeepAlive

# 查看结果
Requests per second:    1000.00 [#/sec]    # QPS
Time per request:       100.000 [ms]       # 平均响应时间
```

### 使用 wrk 测试

```bash
# 基本测试
wrk -t4 -c100 -d30s http://example.com/

# 参数说明
-t4         # 4 个线程
-c100       # 100 个连接
-d30s       # 持续 30 秒

# 查看结果
Requests/sec:   10000.00    # QPS
Latency:        10.00ms     # 延迟
```

---

## 监控指标

### stub_status 模块

```nginx
server {
    listen 80;
    server_name status.example.com;
    
    location /nginx_status {
        stub_status on;
        access_log off;
        
        allow 127.0.0.1;
        allow 192.168.1.0/24;
        deny all;
    }
}
```

### 访问监控页面

```bash
curl http://localhost/nginx_status

# 输出
Active connections: 291
server accepts handled requests
 16630948 16630948 31070465
Reading: 6 Writing: 179 Waiting: 106

# 说明
Active connections  # 当前活动连接数
accepts            # 已接受的连接数
handled            # 已处理的连接数
requests           # 总请求数
Reading            # 正在读取请求头的连接数
Writing            # 正在写入响应的连接数
Waiting            # 空闲连接数（keepalive）
```

---

## 练习题

### 基础练习

1. 配置工作进程数为 CPU 核心数
2. 启用 sendfile 和 tcp_nopush
3. 配置 gzip 压缩
4. 配置静态文件缓存
5. 启用 stub_status 监控

### 进阶练习

1. 配置完整的性能优化参数
2. 配置代理缓存
3. 配置限流和限速
4. 使用 ab 或 wrk 进行压力测试
5. 分析性能瓶颈并优化

---

## 总结

Nginx 性能优化要点：
- ✅ 优化工作进程和连接数
- ✅ 启用 sendfile 和 TCP 优化
- ✅ 配置 gzip 压缩
- ✅ 启用静态文件缓存
- ✅ 配置代理缓存
- ✅ 优化缓冲区大小
- ✅ 配置限流和限速
- ✅ 监控性能指标

---

## 下一步

完成性能优化基础后，继续学习：
- **02_系统层面优化.md**：操作系统和内核参数优化
- **03_高级优化技巧.md**：HTTP/2、CDN、负载均衡优化

性能优化是一个持续的过程，需要根据实际情况不断调整！
