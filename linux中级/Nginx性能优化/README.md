# Nginx 性能优化学习指南

## 学习路线

```
01_Nginx性能优化基础.md  ──▶  Nginx 配置层面优化
        │
        ▼
02_系统层面优化.md       ──▶  操作系统和内核优化
        │
        ▼
03_高级优化技巧.md       ──▶  HTTP/2、CDN、微服务
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_Nginx性能优化基础.md | 工作进程、连接、缓存、压缩 | 1 天 |
| 02_系统层面优化.md | 内核参数、BBR、磁盘I/O | 1 天 |
| 03_高级优化技巧.md | HTTP/2、CDN、负载均衡、微服务 | 1 天 |

## 核心知识点

### Nginx 配置优化
- 工作进程和 CPU 绑定
- 连接数和超时设置
- 缓冲区优化
- TCP 优化（sendfile、tcp_nopush）
- Gzip 压缩
- 静态文件缓存
- 代理缓存
- 限流和限速

### 系统层面优化
- 文件描述符限制
- TCP 内核参数
- BBR 拥塞控制算法
- 磁盘 I/O 优化
- 内存优化
- 网卡优化
- 防火墙优化

### 高级优化
- HTTP/2 和 Server Push
- CDN 加速
- 负载均衡优化
- 多级缓存
- 安全防护
- 动静分离
- 微服务架构
- 容器化部署

## 性能指标

### 关键指标

```
QPS（每秒查询数）
响应时间
并发连接数
吞吐量
CPU 使用率
内存使用率
```

### 测试工具

```bash
# Apache Bench
ab -n 10000 -c 100 http://example.com/

# wrk（推荐）
wrk -t4 -c100 -d30s http://example.com/

# siege
siege -c 100 -t 30s http://example.com/
```

## 优化配置速查

### 工作进程优化

```nginx
worker_processes auto;
worker_cpu_affinity auto;
worker_priority -10;
worker_rlimit_nofile 65535;

events {
    use epoll;
    worker_connections 10240;
    multi_accept on;
}
```

### 连接优化

```nginx
http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    
    keepalive_timeout 65;
    keepalive_requests 100;
}
```

### 缓冲区优化

```nginx
http {
    client_header_buffer_size 4k;
    large_client_header_buffers 4 8k;
    client_body_buffer_size 128k;
    client_max_body_size 10m;
    
    proxy_buffer_size 4k;
    proxy_buffers 8 4k;
    proxy_busy_buffers_size 8k;
}
```

### Gzip 压缩

```nginx
http {
    gzip on;
    gzip_comp_level 6;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_vary on;
}
```

### 静态文件缓存

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
    access_log off;
}
```

### 代理缓存

```nginx
http {
    proxy_cache_path /var/cache/nginx/proxy
                     levels=1:2
                     keys_zone=my_cache:10m
                     max_size=1g
                     inactive=60m;
    
    server {
        location / {
            proxy_cache my_cache;
            proxy_cache_valid 200 10m;
            proxy_pass http://backend;
        }
    }
}
```

## 系统优化速查

### 文件描述符

```bash
# /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
```

### TCP 内核参数

```bash
# /etc/sysctl.conf
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# 应用配置
sysctl -p
```

### BBR 拥塞控制

```bash
# /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# 应用配置
sysctl -p

# 验证
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr
```

### 禁用透明大页

```bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
```

## 完整优化配置

### Nginx 配置

```nginx
user nginx;
worker_processes auto;
worker_cpu_affinity auto;
worker_priority -10;
worker_rlimit_nofile 65535;

error_log /var/log/nginx/error.log error;
pid /var/run/nginx.pid;

events {
    use epoll;
    worker_connections 10240;
    multi_accept on;
    accept_mutex off;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent"';
    
    access_log /var/log/nginx/access.log main buffer=32k flush=5s;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    
    keepalive_timeout 65;
    keepalive_requests 100;
    
    client_header_buffer_size 4k;
    large_client_header_buffers 4 8k;
    client_body_buffer_size 128k;
    client_max_body_size 10m;
    
    gzip on;
    gzip_comp_level 6;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_vary on;
    
    open_file_cache max=10000 inactive=60s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
    
    proxy_cache_path /var/cache/nginx/proxy levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;
    
    limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
    
    server_tokens off;
    
    include /etc/nginx/conf.d/*.conf;
}
```

### 系统优化脚本

```bash
#!/bin/bash
# nginx_optimize.sh

# 文件描述符
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

# 内核参数
cat >> /etc/sysctl.conf << EOF
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 10
fs.file-max = 2097152
EOF

sysctl -p

# 禁用 THP
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

echo "优化完成！建议重启系统。"
```

## 性能测试

### 测试前准备

```bash
# 1. 应用优化配置
nginx -t && nginx -s reload

# 2. 调整系统限制
ulimit -n 65535

# 3. 清理缓存
sync
echo 3 > /proc/sys/vm/drop_caches
```

### 压力测试

```bash
# wrk 测试
wrk -t4 -c100 -d30s --latency http://example.com/

# ab 测试
ab -n 10000 -c 100 -k http://example.com/

# siege 测试
siege -c 100 -t 30s http://example.com/
```

### 性能对比

```
优化前：
Requests/sec:    500.00
Latency:         200.00ms

优化后：
Requests/sec:    2000.00
Latency:         50.00ms

性能提升：4 倍
```

## 监控和分析

### 实时监控

```bash
# Nginx 状态
curl http://localhost/nginx_status

# 连接数
netstat -an | grep :80 | wc -l
ss -s

# 系统资源
top
htop
vmstat 1
iostat -x 1
```

### 日志分析

```bash
# 统计 QPS
tail -f /var/log/nginx/access.log | pv -l -i 1 -r

# 统计状态码
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c

# Top 10 IP
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Top 10 URL
awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10
```

## 常见问题

### 问题1：连接数不够

```bash
# 检查限制
ulimit -n

# 增加限制
ulimit -n 65535

# 永久修改
# /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
```

### 问题2：性能提升不明显

```bash
# 检查瓶颈
# CPU
top

# 内存
free -h

# 磁盘 I/O
iostat -x 1

# 网络
iftop
```

### 问题3：缓存不生效

```bash
# 检查缓存目录权限
ls -la /var/cache/nginx/

# 检查缓存配置
nginx -T | grep cache

# 查看缓存状态
curl -I http://example.com/ | grep X-Cache-Status
```

## 练习题

### 基础练习

1. 配置工作进程优化
2. 启用 sendfile 和 tcp_nopush
3. 配置 gzip 压缩
4. 配置静态文件缓存
5. 优化 TCP 内核参数

### 进阶练习

1. 配置完整的性能优化参数
2. 启用 BBR 拥塞控制算法
3. 配置代理缓存
4. 配置限流和限速
5. 进行压力测试并分析结果
6. 启用 HTTP/2
7. 配置 CDN 回源

## 面试常考

1. Nginx 性能优化有哪些方面？
2. 如何优化 Nginx 工作进程？
3. sendfile 的作用是什么？
4. 如何配置 gzip 压缩？
5. 什么是 BBR 拥塞控制算法？
6. 如何优化 TCP 内核参数？
7. 如何配置 Nginx 缓存？
8. 如何进行性能测试？
9. HTTP/2 相比 HTTP/1.1 有哪些优势？
10. 如何监控 Nginx 性能？

## 学习建议

### 1. 循序渐进

- 先优化 Nginx 配置
- 再优化系统参数
- 最后学习高级技巧

### 2. 实践为主

- 搭建测试环境
- 进行压力测试
- 对比优化效果

### 3. 监控分析

- 实时监控性能
- 分析瓶颈
- 针对性优化

### 4. 持续优化

- 性能优化是持续的过程
- 根据实际情况调整
- 定期review和改进

## 推荐资源

### 官方文档

- [Nginx 官方文档](http://nginx.org/en/docs/)
- [Nginx 性能调优](http://nginx.org/en/docs/http/ngx_http_core_module.html)

### 性能测试工具

- [Apache Bench](https://httpd.apache.org/docs/2.4/programs/ab.html)
- [wrk](https://github.com/wg/wrk)
- [siege](https://www.joedog.org/siege-home/)

### 监控工具

- [GoAccess](https://goaccess.io/)
- [Prometheus + Grafana](https://prometheus.io/)
- [Nginx Amplify](https://www.nginx.com/products/nginx-amplify/)

## 下一步

完成 Nginx 性能优化后，继续学习：
- **NFS**：网络文件系统
- **Rsync**：文件同步
- **iptables**：防火墙配置

性能优化是运维工程师的核心技能，务必熟练掌握！

加油！💪
