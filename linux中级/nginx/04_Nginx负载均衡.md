# Nginx 负载均衡

## 什么是负载均衡？

负载均衡（Load Balancing）是将请求分发到多台服务器，以提高性能、可用性和可扩展性。

### 负载均衡的优势

- **提高性能**：分散请求压力
- **高可用性**：单台故障不影响服务
- **可扩展性**：轻松添加服务器
- **灵活维护**：可以逐台维护服务器

---

## upstream 模块

### 基本语法

```nginx
upstream backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}

server {
    listen 80;
    server_name example.com;
    
    location / {
        proxy_pass http://backend;
    }
}
```

---

## 负载均衡算法

### 1. 轮询（Round Robin）- 默认

按顺序依次分配请求。

```nginx
upstream backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}

# 请求分配：
# 请求1 → 101
# 请求2 → 102
# 请求3 → 103
# 请求4 → 101
# ...
```

### 2. 加权轮询（Weighted Round Robin）

根据权重分配请求。

```nginx
upstream backend {
    server 192.168.1.101:8080 weight=3;
    server 192.168.1.102:8080 weight=2;
    server 192.168.1.103:8080 weight=1;
}

# 权重比例：3:2:1
# 6 个请求分配：
# 101 收到 3 个
# 102 收到 2 个
# 103 收到 1 个
```

### 3. IP 哈希（IP Hash）

根据客户端 IP 分配，同一 IP 总是访问同一服务器。

```nginx
upstream backend {
    ip_hash;
    
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}

# 用途：保持会话（Session）
# 客户端 A → 总是访问 101
# 客户端 B → 总是访问 102
```

### 4. 最少连接（Least Connections）

分配给连接数最少的服务器。

```nginx
upstream backend {
    least_conn;
    
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}

# 动态选择连接数最少的服务器
```

### 5. 哈希（Hash）

根据指定的键进行哈希分配。

```nginx
upstream backend {
    hash $request_uri consistent;
    
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}

# 根据 URI 哈希
# /api/users → 总是访问同一服务器
# /api/orders → 总是访问同一服务器
```

### 6. 随机（Random）

随机选择服务器。

```nginx
upstream backend {
    random;
    
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}

# 或带权重的随机
upstream backend {
    random two least_conn;
    
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}
```

---

## 服务器参数

### 常用参数

```nginx
upstream backend {
    server 192.168.1.101:8080 weight=3 max_fails=2 fail_timeout=30s;
    server 192.168.1.102:8080 weight=2 max_fails=2 fail_timeout=30s;
    server 192.168.1.103:8080 weight=1 backup;
    server 192.168.1.104:8080 down;
}
```

### 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| weight | 权重（默认 1） | weight=3 |
| max_fails | 最大失败次数（默认 1） | max_fails=3 |
| fail_timeout | 失败超时时间（默认 10s） | fail_timeout=30s |
| backup | 备份服务器 | backup |
| down | 标记服务器不可用 | down |
| max_conns | 最大连接数 | max_conns=100 |
| slow_start | 慢启动时间 | slow_start=30s |

### 参数详解

```nginx
upstream backend {
    # 主服务器1
    server 192.168.1.101:8080
        weight=3              # 权重 3
        max_fails=2           # 2 次失败后标记不可用
        fail_timeout=30s;     # 30 秒后重新尝试
    
    # 主服务器2
    server 192.168.1.102:8080
        weight=2
        max_fails=2
        fail_timeout=30s
        max_conns=100;        # 最大 100 个连接
    
    # 备份服务器（所有主服务器都不可用时使用）
    server 192.168.1.103:8080
        backup;
    
    # 临时下线的服务器
    server 192.168.1.104:8080
        down;
}
```

---

## 健康检查

### 被动健康检查（默认）

```nginx
upstream backend {
    server 192.168.1.101:8080 max_fails=3 fail_timeout=30s;
    server 192.168.1.102:8080 max_fails=3 fail_timeout=30s;
}

# 工作原理：
# 1. 请求失败 3 次后，标记服务器不可用
# 2. 30 秒后重新尝试
# 3. 如果成功，恢复服务器状态
```

### 主动健康检查（Nginx Plus）

```nginx
# 需要 Nginx Plus 商业版
upstream backend {
    zone backend 64k;
    
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

server {
    location / {
        proxy_pass http://backend;
        health_check interval=5s fails=3 passes=2;
    }
}
```

### 自定义健康检查（开源方案）

```nginx
# 使用第三方模块 nginx_upstream_check_module
upstream backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    
    check interval=3000 rise=2 fall=3 timeout=1000 type=http;
    check_http_send "HEAD / HTTP/1.0\r\n\r\n";
    check_http_expect_alive http_2xx http_3xx;
}

# 健康检查状态页面
server {
    location /status {
        check_status;
        access_log off;
    }
}
```

---

## 会话保持

### 方法1：IP Hash

```nginx
upstream backend {
    ip_hash;
    
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

# 优点：配置简单
# 缺点：IP 变化会导致会话丢失
```

### 方法2：Cookie

```nginx
upstream backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    
    sticky cookie srv_id expires=1h domain=.example.com path=/;
}

# 需要 nginx-sticky-module 模块
```

### 方法3：共享 Session

```nginx
# 后端应用使用 Redis/Memcached 存储 Session
# Nginx 使用任意负载均衡算法

upstream backend {
    least_conn;
    
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

# 推荐方案：最灵活
```

---

## 实战案例

### 案例1：Web 应用负载均衡

```nginx
upstream web_backend {
    least_conn;
    
    server 192.168.1.101:8080 weight=3 max_fails=2 fail_timeout=30s;
    server 192.168.1.102:8080 weight=3 max_fails=2 fail_timeout=30s;
    server 192.168.1.103:8080 weight=2 max_fails=2 fail_timeout=30s;
    server 192.168.1.104:8080 backup;
    
    keepalive 32;
}

server {
    listen 80;
    server_name www.example.com;
    
    location / {
        proxy_pass http://web_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### 案例2：API 网关负载均衡

```nginx
# 用户服务
upstream user_service {
    least_conn;
    server 192.168.1.101:8001;
    server 192.168.1.102:8001;
    server 192.168.1.103:8001;
}

# 订单服务
upstream order_service {
    least_conn;
    server 192.168.1.101:8002;
    server 192.168.1.102:8002;
    server 192.168.1.103:8002;
}

# 支付服务
upstream payment_service {
    least_conn;
    server 192.168.1.101:8003;
    server 192.168.1.102:8003;
}

server {
    listen 80;
    server_name api.example.com;
    
    location /api/users/ {
        proxy_pass http://user_service/;
    }
    
    location /api/orders/ {
        proxy_pass http://order_service/;
    }
    
    location /api/payment/ {
        proxy_pass http://payment_service/;
    }
}
```

### 案例3：动静分离 + 负载均衡

```nginx
# 动态内容后端
upstream dynamic_backend {
    least_conn;
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    server 192.168.1.103:8080;
}

server {
    listen 80;
    server_name www.example.com;
    
    # 静态文件
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        root /data/www/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # 动态内容
    location / {
        proxy_pass http://dynamic_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 案例4：灰度发布

```nginx
# 生产环境
upstream prod_backend {
    server 192.168.1.101:8080 weight=9;
    server 192.168.1.102:8080 weight=9;
}

# 灰度环境
upstream gray_backend {
    server 192.168.1.201:8080;
}

server {
    listen 80;
    server_name www.example.com;
    
    location / {
        # 10% 流量到灰度环境
        if ($request_id ~* "^[0-9]$") {
            proxy_pass http://gray_backend;
            break;
        }
        
        # 90% 流量到生产环境
        proxy_pass http://prod_backend;
    }
}
```

### 案例5：按地域负载均衡

```nginx
# 华北服务器
upstream north_backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
}

# 华南服务器
upstream south_backend {
    server 192.168.2.101:8080;
    server 192.168.2.102:8080;
}

# GeoIP 模块配置
geo $region {
    default south;
    
    # 北京、天津、河北等
    1.0.0.0/8 north;
    2.0.0.0/8 north;
}

server {
    listen 80;
    server_name www.example.com;
    
    location / {
        if ($region = "north") {
            proxy_pass http://north_backend;
            break;
        }
        
        proxy_pass http://south_backend;
    }
}
```

---

## 负载均衡优化

### 1. 连接复用

```nginx
upstream backend {
    server 192.168.1.101:8080;
    server 192.168.1.102:8080;
    
    # 保持连接
    keepalive 32;
    keepalive_timeout 60s;
    keepalive_requests 100;
}

server {
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

### 2. 慢启动

```nginx
upstream backend {
    server 192.168.1.101:8080 slow_start=30s;
    server 192.168.1.102:8080 slow_start=30s;
    
    zone backend 64k;
}

# 新服务器或恢复的服务器逐渐增加权重
```

### 3. 限制连接数

```nginx
upstream backend {
    server 192.168.1.101:8080 max_conns=100;
    server 192.168.1.102:8080 max_conns=100;
    
    queue 200 timeout=30s;
}

# 超过最大连接数的请求进入队列
```

---

## 监控和管理

### 1. 状态监控

```nginx
# 编译时添加 --with-http_stub_status_module

server {
    listen 80;
    server_name status.example.com;
    
    location /nginx_status {
        stub_status on;
        access_log off;
        
        allow 192.168.1.0/24;
        deny all;
    }
}

# 访问 http://status.example.com/nginx_status
# 输出：
# Active connections: 291
# server accepts handled requests
#  16630948 16630948 31070465
# Reading: 6 Writing: 179 Waiting: 106
```

### 2. upstream 状态（Nginx Plus）

```nginx
server {
    location /api {
        api write=on;
        allow 192.168.1.0/24;
        deny all;
    }
    
    location = /dashboard.html {
        root /usr/share/nginx/html;
    }
}

# 访问 /dashboard.html 查看可视化监控
```

### 3. 日志分析

```bash
# 统计后端服务器响应时间
awk '{print $NF}' access.log | sort -n | uniq -c

# 统计状态码
awk '{print $9}' access.log | sort | uniq -c

# 统计请求最多的 URL
awk '{print $7}' access.log | sort | uniq -c | sort -rn | head -10
```

---

## 高可用架构

### 方案1：Nginx + Keepalived

```
        VIP (192.168.1.100)
             │
      ┌──────┴──────┐
      │             │
   Nginx1        Nginx2
   (Master)      (Backup)
      │             │
      └──────┬──────┘
             │
      ┌──────┴──────┬──────┐
      │             │      │
   Backend1     Backend2  Backend3
```

```bash
# Keepalived 配置（Master）
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    
    virtual_ipaddress {
        192.168.1.100
    }
}

# Keepalived 配置（Backup）
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    
    virtual_ipaddress {
        192.168.1.100
    }
}
```

### 方案2：DNS 轮询

```
DNS 解析 www.example.com
    │
    ├─ 192.168.1.101 (Nginx1)
    ├─ 192.168.1.102 (Nginx2)
    └─ 192.168.1.103 (Nginx3)
```

---

## 故障排查

### 问题1：负载不均衡

```bash
# 检查权重配置
grep -A 10 "upstream" /etc/nginx/conf.d/*.conf

# 检查连接数
netstat -an | grep :8080 | wc -l

# 查看日志
tail -f /var/log/nginx/access.log | awk '{print $1}'
```

### 问题2：某台服务器一直不可用

```bash
# 检查健康检查配置
grep "max_fails\|fail_timeout" /etc/nginx/conf.d/*.conf

# 手动测试后端
curl http://192.168.1.101:8080

# 查看错误日志
tail -f /var/log/nginx/error.log
```

### 问题3：会话丢失

```bash
# 检查是否使用 ip_hash
grep "ip_hash" /etc/nginx/conf.d/*.conf

# 或使用共享 Session
# 后端应用配置 Redis Session
```

---

## 练习题

### 基础练习

1. 配置 3 台服务器的轮询负载均衡
2. 配置加权轮询（权重 3:2:1）
3. 配置 IP Hash 保持会话
4. 配置最少连接算法
5. 配置备份服务器

### 进阶练习

1. 配置健康检查（max_fails、fail_timeout）
2. 配置动静分离 + 负载均衡
3. 配置 API 网关负载均衡
4. 配置灰度发布（10% 流量）
5. 配置连接复用优化
6. 搭建 Nginx + Keepalived 高可用

---

## 总结

负载均衡核心要点：
- ✅ 掌握 6 种负载均衡算法
- ✅ 理解服务器参数配置
- ✅ 配置健康检查
- ✅ 实现会话保持
- ✅ 优化性能和高可用

---

## 下一步

完成 Nginx 负载均衡学习后，继续学习：
- **HTTPS 加密**：SSL/TLS 配置
- **Nginx 性能优化**：调优参数

负载均衡是高可用架构的核心，务必熟练掌握！
