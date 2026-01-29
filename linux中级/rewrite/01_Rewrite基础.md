# Rewrite 基础

## 什么是 Rewrite？

Rewrite（重写）是 Nginx 的一个强大功能，用于修改请求的 URI，实现 URL 重定向、伪静态等功能。

### Rewrite 的作用

- **URL 美化**：将动态 URL 转换为静态 URL
- **SEO 优化**：友好的 URL 更利于搜索引擎收录
- **重定向**：实现 301/302 跳转
- **隐藏真实路径**：保护后端结构
- **兼容性**：支持旧 URL 访问新资源

---

## Rewrite 指令

### 基本语法

```nginx
rewrite regex replacement [flag];
```

### 参数说明

```
regex       # 正则表达式，匹配 URI
replacement # 替换后的 URI
flag        # 标志位（可选）
```

### 标志位（Flag）

| Flag | 说明 | 行为 |
|------|------|------|
| last | 停止处理当前 rewrite，重新搜索 location | 内部重定向 |
| break | 停止处理当前 rewrite，不再匹配 | 停止处理 |
| redirect | 返回 302 临时重定向 | 外部重定向 |
| permanent | 返回 301 永久重定向 | 外部重定向 |

---

## 基本示例

### 示例1：简单重定向

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 将 /old 重定向到 /new
    rewrite ^/old$ /new permanent;
    
    # 访问 /old → 301 重定向到 /new
}
```

### 示例2：带参数的重定向

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 将 /user/123 重定向到 /profile?id=123
    rewrite ^/user/(\d+)$ /profile?id=$1 last;
    
    # 访问 /user/123 → 内部重定向到 /profile?id=123
}
```

### 示例3：域名重定向

```nginx
server {
    listen 80;
    server_name old-domain.com;
    
    # 将整个域名重定向到新域名
    rewrite ^(.*)$ http://new-domain.com$1 permanent;
    
    # 访问 http://old-domain.com/page → 301 到 http://new-domain.com/page
}
```

---

## Flag 详解

### last vs break

```nginx
server {
    listen 80;
    server_name example.com;
    root /data/www;
    
    # 使用 last
    location /test1/ {
        rewrite ^/test1/(.*)$ /new/$1 last;
        # 重新搜索 location，会匹配到下面的 location /new/
    }
    
    location /new/ {
        return 200 "Matched /new/\n";
    }
    
    # 使用 break
    location /test2/ {
        rewrite ^/test2/(.*)$ /new/$1 break;
        # 停止处理，直接使用 root 查找文件
    }
}

# 访问 /test1/abc → 返回 "Matched /new/"
# 访问 /test2/abc → 查找 /data/www/new/abc 文件
```

### redirect vs permanent

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 302 临时重定向
    rewrite ^/temp$ /new redirect;
    
    # 301 永久重定向
    rewrite ^/old$ /new permanent;
}

# 区别：
# 302：浏览器不会缓存，每次都请求服务器
# 301：浏览器会缓存，直接访问新地址
```

---

## 正则表达式

### 常用元字符

| 符号 | 说明 | 示例 |
|------|------|------|
| ^ | 匹配开头 | ^/api |
| $ | 匹配结尾 | \.html$ |
| . | 匹配任意字符 | a.c 匹配 abc、adc |
| * | 匹配 0 次或多次 | a* 匹配 、a、aa |
| + | 匹配 1 次或多次 | a+ 匹配 a、aa |
| ? | 匹配 0 次或 1 次 | a? 匹配 、a |
| \d | 匹配数字 | \d+ 匹配 123 |
| \w | 匹配字母数字下划线 | \w+ 匹配 abc_123 |
| [abc] | 匹配 a 或 b 或 c | [0-9] 匹配数字 |
| (abc) | 捕获组 | (\d+) 捕获数字 |
| \| | 或 | jpg\|png 匹配 jpg 或 png |

### 转义字符

```nginx
# 需要转义的特殊字符
. ? + * ^ $ [ ] ( ) { } | \

# 转义方法：使用反斜杠 \
rewrite ^/test\.html$ /new.html last;  # 匹配 /test.html
rewrite ^/\$price$ /price last;        # 匹配 /$price
```

### 捕获组

```nginx
# 使用 () 捕获，使用 $1、$2 引用
rewrite ^/user/(\d+)/post/(\d+)$ /article?uid=$1&pid=$2 last;

# 访问 /user/123/post/456
# 重写为 /article?uid=123&pid=456
# $1 = 123
# $2 = 456
```

---

## 常用 Rewrite 规则

### 1. 去除 www

```nginx
server {
    listen 80;
    server_name www.example.com;
    
    # www.example.com → example.com
    rewrite ^(.*)$ http://example.com$1 permanent;
}

server {
    listen 80;
    server_name example.com;
    root /data/www;
}
```

### 2. 添加 www

```nginx
server {
    listen 80;
    server_name example.com;
    
    # example.com → www.example.com
    rewrite ^(.*)$ http://www.example.com$1 permanent;
}

server {
    listen 80;
    server_name www.example.com;
    root /data/www;
}
```

### 3. HTTP 重定向到 HTTPS

```nginx
server {
    listen 80;
    server_name example.com;
    
    # HTTP → HTTPS
    rewrite ^(.*)$ https://$server_name$1 permanent;
}

server {
    listen 443 ssl;
    server_name example.com;
    # SSL 配置...
}
```

### 4. 目录重定向

```nginx
server {
    listen 80;
    server_name example.com;
    
    # /old-dir/ → /new-dir/
    rewrite ^/old-dir/(.*)$ /new-dir/$1 permanent;
}
```

### 5. 文件扩展名重写

```nginx
server {
    listen 80;
    server_name example.com;
    
    # /page.php → /page.html
    rewrite ^/(.*)\.php$ /$1.html permanent;
}
```

---

## if 指令

### 基本语法

```nginx
if (condition) {
    # 执行的指令
}
```

### 条件判断

```nginx
# 1. 变量判断
if ($request_method = POST) {
    return 405;
}

# 2. 正则匹配
if ($http_user_agent ~* "MSIE") {
    rewrite ^(.*)$ /ie/$1 break;
}

# 3. 文件判断
if (!-f $request_filename) {
    rewrite ^(.*)$ /index.php last;
}

# 4. 目录判断
if (!-d $request_filename) {
    return 404;
}

# 5. 文件或目录判断
if (!-e $request_filename) {
    rewrite ^(.*)$ /index.php last;
}
```

### 判断符号

| 符号 | 说明 |
|------|------|
| = | 等于 |
| != | 不等于 |
| ~ | 正则匹配（区分大小写） |
| ~* | 正则匹配（不区分大小写） |
| !~ | 正则不匹配（区分大小写） |
| !~* | 正则不匹配（不区分大小写） |
| -f | 文件存在 |
| !-f | 文件不存在 |
| -d | 目录存在 |
| !-d | 目录不存在 |
| -e | 文件或目录存在 |
| !-e | 文件或目录不存在 |
| -x | 文件可执行 |
| !-x | 文件不可执行 |

---

## return 指令

### 基本语法

```nginx
return code [text];
return code URL;
return URL;
```

### 常用示例

```nginx
# 返回状态码
location /forbidden {
    return 403;
}

# 返回状态码和文本
location /api {
    return 200 "API is working\n";
}

# 返回重定向
location /old {
    return 301 http://example.com/new;
}

# 返回 JSON
location /json {
    default_type application/json;
    return 200 '{"status":"ok"}';
}
```

---

## 实战案例

### 案例1：WordPress 伪静态

```nginx
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/wordpress;
    index index.php;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    # 或使用 rewrite
    location / {
        if (!-e $request_filename) {
            rewrite ^(.*)$ /index.php?s=$1 last;
        }
    }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
```

### 案例2：Discuz 论坛伪静态

```nginx
server {
    listen 80;
    server_name forum.example.com;
    root /data/www/discuz;
    
    location / {
        rewrite ^([^\.]*)/topic-(.+)\.html$ $1/portal.php?mod=topic&topic=$2 last;
        rewrite ^([^\.]*)/article-([0-9]+)-([0-9]+)\.html$ $1/portal.php?mod=view&aid=$2&page=$3 last;
        rewrite ^([^\.]*)/forum-(\w+)-([0-9]+)\.html$ $1/forum.php?mod=forumdisplay&fid=$2&page=$3 last;
        rewrite ^([^\.]*)/thread-([0-9]+)-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=viewthread&tid=$2&extra=page%3D$4&page=$3 last;
    }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
    }
}
```

### 案例3：ThinkPHP 框架

```nginx
server {
    listen 80;
    server_name app.example.com;
    root /data/www/thinkphp/public;
    index index.php;
    
    location / {
        if (!-e $request_filename) {
            rewrite ^(.*)$ /index.php?s=$1 last;
        }
    }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
```

### 案例4：Laravel 框架

```nginx
server {
    listen 80;
    server_name laravel.example.com;
    root /data/www/laravel/public;
    index index.php;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
```

### 案例5：移动端适配

```nginx
server {
    listen 80;
    server_name www.example.com;
    root /data/www/pc;
    
    # 移动端重定向
    set $mobile_rewrite do_not_perform;
    
    if ($http_user_agent ~* "(android|iphone|ipad|phone|mobile)") {
        set $mobile_rewrite perform;
    }
    
    if ($mobile_rewrite = perform) {
        rewrite ^(.*)$ http://m.example.com$1 permanent;
    }
}

server {
    listen 80;
    server_name m.example.com;
    root /data/www/mobile;
}
```

---

## try_files 指令

### 基本语法

```nginx
try_files file1 file2 ... uri;
try_files file1 file2 ... =code;
```

### 工作原理

```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}

# 处理流程：
# 1. 尝试访问 $uri（请求的文件）
# 2. 如果不存在，尝试 $uri/（目录）
# 3. 如果还不存在，重写到 /index.php?$args
```

### 常用示例

```nginx
# 静态文件优先
location / {
    try_files $uri $uri/ /index.html;
}

# 前端路由（SPA）
location / {
    try_files $uri $uri/ /index.html;
}

# PHP 框架
location / {
    try_files $uri $uri/ /index.php?$query_string;
}

# 返回 404
location / {
    try_files $uri $uri/ =404;
}

# 代理到后端
location / {
    try_files $uri @backend;
}

location @backend {
    proxy_pass http://backend_server;
}
```

---

## 调试 Rewrite

### 开启 Rewrite 日志

```nginx
# 在 http、server 或 location 块中
rewrite_log on;
error_log /var/log/nginx/error.log notice;
```

### 查看日志

```bash
# 实时查看
tail -f /var/log/nginx/error.log

# 日志示例
2024/01/01 12:00:00 [notice] 1234#0: *1 "^/old$" matches "/old", client: 192.168.1.1
2024/01/01 12:00:00 [notice] 1234#0: *1 rewritten data: "/new", args: ""
```

### 测试 Rewrite

```bash
# 使用 curl 测试
curl -I http://example.com/old

# 查看响应头
HTTP/1.1 301 Moved Permanently
Location: http://example.com/new

# 测试不跟随重定向
curl -I --max-redirs 0 http://example.com/old
```

---

## 常见错误

### 错误1：重写循环

```nginx
# 错误示例
location / {
    rewrite ^(.*)$ /index.php last;
}

location ~ \.php$ {
    rewrite ^(.*)$ /index.php last;
}

# 结果：无限循环

# 正确写法
location / {
    try_files $uri $uri/ /index.php?$args;
}
```

### 错误2：正则错误

```nginx
# 错误：未转义特殊字符
rewrite ^/test.html$ /new.html last;  # . 匹配任意字符

# 正确：转义特殊字符
rewrite ^/test\.html$ /new.html last;
```

### 错误3：flag 使用错误

```nginx
# 错误：在 location 外使用 break
server {
    rewrite ^/old$ /new break;  # break 在 server 块中无效
}

# 正确
server {
    rewrite ^/old$ /new last;
}
```

---

## 性能优化

### 1. 避免过多 if

```nginx
# 不推荐
if ($request_uri ~* "^/api") {
    set $flag 1;
}
if ($request_method = POST) {
    set $flag "${flag}2";
}
if ($flag = "12") {
    return 403;
}

# 推荐：使用 map
map $request_uri $is_api {
    ~^/api 1;
    default 0;
}

server {
    if ($is_api) {
        return 403;
    }
}
```

### 2. 使用 try_files 代替 if

```nginx
# 不推荐
if (!-f $request_filename) {
    rewrite ^(.*)$ /index.php last;
}

# 推荐
try_files $uri $uri/ /index.php?$args;
```

### 3. 减少 rewrite 规则

```nginx
# 不推荐：多条规则
rewrite ^/page1$ /new1 permanent;
rewrite ^/page2$ /new2 permanent;
rewrite ^/page3$ /new3 permanent;

# 推荐：合并规则
location ~* ^/(page1|page2|page3)$ {
    rewrite ^/page1$ /new1 permanent;
    rewrite ^/page2$ /new2 permanent;
    rewrite ^/page3$ /new3 permanent;
}
```

---

## 练习题

### 基础练习

1. 将 /old 重定向到 /new（301）
2. 将 www.example.com 重定向到 example.com
3. 将 HTTP 重定向到 HTTPS
4. 将 /user/123 重写为 /profile?id=123
5. 去除 URL 中的 .html 后缀

### 进阶练习

1. 配置 WordPress 伪静态
2. 配置移动端自动跳转
3. 配置前端 SPA 路由
4. 配置多条件判断重定向
5. 使用 try_files 优化配置

---

## 总结

Rewrite 核心要点：
- ✅ 理解 rewrite 指令和 flag
- ✅ 掌握正则表达式
- ✅ 学会使用 if 和 try_files
- ✅ 了解常见框架的伪静态规则
- ✅ 避免重写循环
- ✅ 优化性能

---

## 下一步

完成 Rewrite 基础学习后，继续学习：
- **02_Rewrite实战案例.md**：更多实战案例和技巧

Rewrite 是 Nginx 的重要功能，掌握它能让你的网站更加灵活和友好！
