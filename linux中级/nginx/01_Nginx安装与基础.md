# Nginx 安装与基础

## 什么是 Nginx？

Nginx（发音：engine-x）是一个高性能的 HTTP 和反向代理服务器，也是一个 IMAP/POP3/SMTP 代理服务器。

### Nginx 的特点

- **高性能**：单机支持 10 万+ 并发连接
- **低资源消耗**：内存占用少，CPU 使用率低
- **高可靠性**：稳定运行，很少崩溃
- **热部署**：不停机更新配置
- **模块化设计**：功能丰富，易于扩展

### Nginx vs Apache

| 特性 | Nginx | Apache |
|------|-------|--------|
| 架构 | 异步非阻塞 | 同步阻塞 |
| 并发性能 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 静态文件 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 动态内容 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| 配置 | 简洁 | 复杂 |
| 模块 | 编译时加载 | 动态加载 |
| 内存消耗 | 低 | 高 |

---

## Nginx 安装

### 方法1：YUM 安装（推荐）

```bash
# CentOS/RHEL
# 添加官方仓库
cat > /etc/yum.repos.d/nginx.repo << EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

# 安装
yum install nginx -y

# 启动
systemctl start nginx
systemctl enable nginx

# 查看版本
nginx -v

# 查看编译参数
nginx -V
```

### 方法2：编译安装

```bash
# 安装依赖
yum install -y gcc gcc-c++ make pcre-devel zlib-devel openssl-devel

# 下载源码
cd /usr/local/src
wget http://nginx.org/download/nginx-1.24.0.tar.gz
tar -zxvf nginx-1.24.0.tar.gz
cd nginx-1.24.0

# 配置编译选项
./configure \
  --prefix=/usr/local/nginx \
  --user=nginx \
  --group=nginx \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-http_stub_status_module \
  --with-http_gzip_static_module \
  --with-pcre \
  --with-stream \
  --with-stream_ssl_module

# 编译安装
make && make install

# 创建用户
useradd -s /sbin/nologin -M nginx

# 创建软链接
ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

# 启动
nginx
```

### 方法3：Docker 安装

```bash
# 拉取镜像
docker pull nginx:latest

# 运行容器
docker run -d \
  --name nginx \
  -p 80:80 \
  -v /data/nginx/html:/usr/share/nginx/html \
  -v /data/nginx/conf:/etc/nginx \
  nginx:latest
```

---

## Nginx 目录结构

### YUM 安装的目录结构

```bash
/etc/nginx/                    # 配置文件目录
├── nginx.conf                 # 主配置文件
├── conf.d/                    # 子配置文件目录
│   └── default.conf           # 默认虚拟主机配置
├── mime.types                 # MIME 类型配置
├── fastcgi_params             # FastCGI 参数
├── scgi_params                # SCGI 参数
└── uwsgi_params               # uWSGI 参数

/usr/share/nginx/html/         # 默认网站根目录
├── index.html                 # 默认首页
└── 50x.html                   # 错误页面

/var/log/nginx/                # 日志目录
├── access.log                 # 访问日志
└── error.log                  # 错误日志

/usr/sbin/nginx                # 主程序
/var/cache/nginx/              # 缓存目录
/var/run/nginx.pid             # PID 文件
```

### 编译安装的目录结构

```bash
/usr/local/nginx/
├── conf/                      # 配置文件
│   ├── nginx.conf
│   └── ...
├── html/                      # 网站根目录
│   ├── index.html
│   └── 50x.html
├── logs/                      # 日志目录
│   ├── access.log
│   └── error.log
└── sbin/                      # 可执行文件
    └── nginx
```

---

## Nginx 配置文件结构

### 主配置文件（nginx.conf）

```nginx
# 全局块：影响整个 Nginx 服务器
user nginx;                              # 运行用户
worker_processes auto;                   # 工作进程数
error_log /var/log/nginx/error.log;      # 错误日志
pid /var/run/nginx.pid;                  # PID 文件

# events 块：影响 Nginx 与用户的网络连接
events {
    worker_connections 1024;             # 单个进程最大连接数
    use epoll;                           # 事件驱动模型
}

# http 块：配置 HTTP 服务器
http {
    # http 全局块
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # 日志格式
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log  /var/log/nginx/access.log  main;
    
    # 性能优化
    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;
    types_hash_max_size 2048;
    
    # gzip 压缩
    gzip  on;
    gzip_types text/plain text/css application/json application/javascript;
    
    # server 块：配置虚拟主机
    server {
        listen       80;                 # 监听端口
        server_name  localhost;          # 域名
        
        # location 块：配置请求路由
        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }
        
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
    
    # 包含其他配置文件
    include /etc/nginx/conf.d/*.conf;
}
```

### 配置文件层级关系

```
全局块
  │
  ├─ events 块
  │
  └─ http 块
      │
      ├─ http 全局块
      │
      └─ server 块（虚拟主机）
          │
          ├─ server 全局块
          │
          └─ location 块（路由匹配）
```

---

## Nginx 基本命令

### 服务管理

```bash
# 启动
nginx
systemctl start nginx

# 停止
nginx -s stop                  # 快速停止
nginx -s quit                  # 优雅停止
systemctl stop nginx

# 重启
systemctl restart nginx

# 重新加载配置（不停机）
nginx -s reload
systemctl reload nginx

# 查看状态
systemctl status nginx

# 开机自启
systemctl enable nginx
```

### 配置测试

```bash
# 测试配置文件语法
nginx -t

# 测试并显示配置
nginx -T

# 指定配置文件测试
nginx -t -c /etc/nginx/nginx.conf
```

### 进程管理

```bash
# 查看进程
ps aux | grep nginx

# 查看端口
netstat -tuln | grep 80
ss -tuln | grep 80

# 查看 PID
cat /var/run/nginx.pid

# 发送信号
kill -QUIT $(cat /var/run/nginx.pid)    # 优雅停止
kill -HUP $(cat /var/run/nginx.pid)     # 重新加载配置
```

---

## 第一个网站

### 创建简单网站

```bash
# 创建网站目录
mkdir -p /data/www/mysite

# 创建首页
cat > /data/www/mysite/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>我的第一个 Nginx 网站</title>
</head>
<body>
    <h1>欢迎来到 Nginx！</h1>
    <p>这是我的第一个 Nginx 网站。</p>
</body>
</html>
EOF

# 配置 Nginx
cat > /etc/nginx/conf.d/mysite.conf << EOF
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /data/www/mysite;
        index index.html;
    }
}
EOF

# 测试配置
nginx -t

# 重新加载
nginx -s reload

# 访问测试
curl http://localhost
```

---

## location 匹配规则

### 匹配语法

```nginx
location [ = | ~ | ~* | ^~ ] uri {
    ...
}
```

### 匹配类型

| 符号 | 说明 | 优先级 |
|------|------|--------|
| = | 精确匹配 | 1（最高） |
| ^~ | 前缀匹配 | 2 |
| ~ | 正则匹配（区分大小写） | 3 |
| ~* | 正则匹配（不区分大小写） | 3 |
| / | 通用匹配 | 4（最低） |

### 匹配示例

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 精确匹配
    location = / {
        return 200 "精确匹配根路径\n";
    }
    
    # 前缀匹配
    location ^~ /static/ {
        root /data/www;
    }
    
    # 正则匹配（区分大小写）
    location ~ \.(jpg|png|gif)$ {
        root /data/images;
    }
    
    # 正则匹配（不区分大小写）
    location ~* \.(JPG|PNG|GIF)$ {
        root /data/images;
    }
    
    # 通用匹配
    location / {
        root /data/www;
        index index.html;
    }
}
```

### 匹配顺序

```
1. 精确匹配 =
2. 前缀匹配 ^~
3. 正则匹配 ~ 和 ~*（按配置文件顺序）
4. 通用匹配 /
```

---

## 常用配置示例

### 静态网站

```nginx
server {
    listen 80;
    server_name www.example.com;
    root /data/www/example;
    index index.html index.htm;
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
```

### 目录浏览

```nginx
server {
    listen 80;
    server_name files.example.com;
    
    location / {
        root /data/files;
        autoindex on;                    # 开启目录浏览
        autoindex_exact_size off;        # 显示文件大小（KB/MB）
        autoindex_localtime on;          # 显示本地时间
    }
}
```

### 访问控制

```nginx
server {
    listen 80;
    server_name admin.example.com;
    
    # IP 白名单
    location /admin/ {
        allow 192.168.1.0/24;
        allow 10.0.0.1;
        deny all;
        
        root /data/www;
    }
    
    # 基本认证
    location /secret/ {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        root /data/www;
    }
}
```

### 错误页面

```nginx
server {
    listen 80;
    server_name www.example.com;
    
    # 自定义错误页面
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /404.html {
        root /data/www/errors;
        internal;
    }
    
    location = /50x.html {
        root /data/www/errors;
        internal;
    }
}
```

---

## Nginx 变量

### 常用内置变量

```nginx
$remote_addr          # 客户端 IP
$remote_port          # 客户端端口
$remote_user          # 认证用户名
$request              # 完整请求行
$request_method       # 请求方法（GET、POST）
$request_uri          # 完整请求 URI
$uri                  # 当前 URI（不含参数）
$args                 # 请求参数
$query_string         # 同 $args
$host                 # 请求的主机名
$server_name          # 服务器名称
$server_addr          # 服务器 IP
$server_port          # 服务器端口
$scheme               # 协议（http/https）
$status               # 响应状态码
$body_bytes_sent      # 发送的字节数
$http_user_agent      # User-Agent
$http_referer         # Referer
$http_cookie          # Cookie
$time_local           # 本地时间
```

### 变量使用示例

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 记录详细日志
    access_log /var/log/nginx/access.log combined;
    
    location / {
        # 添加自定义响应头
        add_header X-Client-IP $remote_addr;
        add_header X-Request-Time $time_local;
        
        # 根据变量返回内容
        return 200 "Your IP: $remote_addr\nMethod: $request_method\n";
    }
    
    # 根据 User-Agent 判断
    location /mobile {
        if ($http_user_agent ~* "mobile|android|iphone") {
            return 200 "Mobile Device\n";
        }
        return 200 "Desktop Device\n";
    }
}
```

---

## 日志管理

### 访问日志

```nginx
http {
    # 定义日志格式
    log_format main '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent"';
    
    # 全局访问日志
    access_log /var/log/nginx/access.log main;
    
    server {
        # 虚拟主机日志
        access_log /var/log/nginx/example.com.access.log main;
        
        location /api/ {
            # 特定 location 日志
            access_log /var/log/nginx/api.access.log main;
        }
        
        location /static/ {
            # 禁用日志
            access_log off;
        }
    }
}
```

### 错误日志

```nginx
# 全局错误日志
error_log /var/log/nginx/error.log warn;

# 日志级别：debug | info | notice | warn | error | crit | alert | emerg

server {
    # 虚拟主机错误日志
    error_log /var/log/nginx/example.com.error.log error;
}
```

### 日志切割

```bash
# 创建日志切割脚本
cat > /etc/logrotate.d/nginx << EOF
/var/log/nginx/*.log {
    daily                    # 每天切割
    rotate 30                # 保留 30 天
    missingok                # 日志丢失不报错
    notifempty               # 空文件不切割
    compress                 # 压缩旧日志
    delaycompress            # 延迟压缩
    sharedscripts            # 共享脚本
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 \$(cat /var/run/nginx.pid)
        fi
    endscript
}
EOF

# 手动执行切割
logrotate -f /etc/logrotate.d/nginx
```

---

## 实战案例

### 案例1：部署静态博客

```bash
# 1. 创建目录
mkdir -p /data/www/blog

# 2. 上传网站文件
# （假设已上传到 /data/www/blog）

# 3. 配置 Nginx
cat > /etc/nginx/conf.d/blog.conf << EOF
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/blog;
    index index.html;
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # 404 页面
    error_page 404 /404.html;
    
    # 访问日志
    access_log /var/log/nginx/blog.access.log;
    error_log /var/log/nginx/blog.error.log;
}
EOF

# 4. 测试并重载
nginx -t && nginx -s reload
```

### 案例2：文件下载站

```bash
# 配置
cat > /etc/nginx/conf.d/download.conf << EOF
server {
    listen 80;
    server_name download.example.com;
    
    location / {
        root /data/downloads;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        
        # 限速 1MB/s
        limit_rate 1m;
        
        # 下载后限速
        limit_rate_after 10m;
    }
}
EOF

nginx -t && nginx -s reload
```

---

## 练习题

### 基础练习

1. 安装 Nginx 并启动服务
2. 创建一个简单的 HTML 页面
3. 配置虚拟主机访问该页面
4. 测试不同的 location 匹配规则
5. 配置自定义错误页面

### 进阶练习

1. 配置目录浏览功能
2. 配置 IP 访问控制
3. 配置基本认证
4. 配置日志格式和日志切割
5. 配置静态文件缓存

---

## 下一步

完成 Nginx 基础学习后，继续学习：
- **02_Nginx虚拟主机.md**：多站点配置
- **03_Nginx反向代理.md**：代理后端服务
- **04_Nginx负载均衡.md**：分发流量

Nginx 是运维工程师的核心技能，务必熟练掌握！
