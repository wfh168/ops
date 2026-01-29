# Rewrite 重写学习指南

## 学习路线

```
01_Rewrite基础.md       ──▶  掌握 Rewrite 基本语法
        │
        ▼
02_Rewrite实战案例.md   ──▶  常见框架和场景配置
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_Rewrite基础.md | rewrite 指令、正则表达式、if 和 try_files | 1 天 |
| 02_Rewrite实战案例.md | CMS、框架、SEO、移动端适配 | 1 天 |

## 核心知识点

### Rewrite 基础
- rewrite 指令语法
- Flag 标志位（last、break、redirect、permanent）
- 正则表达式
- if 条件判断
- try_files 指令
- return 指令

### 实战应用
- WordPress、Discuz 等 CMS 伪静态
- Laravel、ThinkPHP 等框架路由
- Vue/React SPA 路由
- SEO 优化
- 移动端适配
- 防盗链
- 多语言网站

## 常用命令速查

### rewrite 指令

```nginx
# 基本语法
rewrite regex replacement [flag];

# 示例
rewrite ^/old$ /new permanent;                    # 永久重定向
rewrite ^/user/(\d+)$ /profile?id=$1 last;       # 内部重写
rewrite ^(.*)$ https://$server_name$1 permanent; # HTTP → HTTPS
```

### Flag 标志位

| Flag | 说明 | 使用场景 |
|------|------|----------|
| last | 停止处理，重新搜索 location | 内部重写 |
| break | 停止处理，不再匹配 | 停止重写 |
| redirect | 302 临时重定向 | 临时跳转 |
| permanent | 301 永久重定向 | 永久跳转 |

### try_files 指令

```nginx
# 基本语法
try_files file1 file2 ... uri;

# 常用示例
try_files $uri $uri/ /index.php?$args;           # PHP 框架
try_files $uri $uri/ /index.html;                # SPA 应用
try_files $uri $uri/ =404;                       # 返回 404
```

### if 指令

```nginx
# 变量判断
if ($request_method = POST) {
    return 405;
}

# 正则匹配
if ($http_user_agent ~* "mobile") {
    rewrite ^(.*)$ http://m.example.com$1 redirect;
}

# 文件判断
if (!-f $request_filename) {
    rewrite ^(.*)$ /index.php last;
}
```

## 正则表达式速查

### 常用元字符

| 符号 | 说明 | 示例 |
|------|------|------|
| ^ | 开头 | ^/api |
| $ | 结尾 | \.html$ |
| . | 任意字符 | a.c |
| * | 0次或多次 | a* |
| + | 1次或多次 | \d+ |
| ? | 0次或1次 | a? |
| \d | 数字 | \d+ |
| \w | 字母数字下划线 | \w+ |
| [abc] | a或b或c | [0-9] |
| (abc) | 捕获组 | (\d+) |
| \| | 或 | jpg\|png |

### 捕获和引用

```nginx
# 使用 () 捕获，使用 $1、$2 引用
rewrite ^/user/(\d+)/post/(\d+)$ /article?uid=$1&pid=$2 last;

# 访问 /user/123/post/456
# 重写为 /article?uid=123&pid=456
```

## 配置模板

### WordPress

```nginx
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/wordpress;
    index index.php;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
```

### Laravel

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

### Vue/React SPA

```nginx
server {
    listen 80;
    server_name app.example.com;
    root /data/www/spa/dist;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://backend:8080/;
    }
}
```

### 域名重定向

```nginx
# www → 非 www
server {
    listen 80;
    server_name www.example.com;
    return 301 http://example.com$request_uri;
}

# HTTP → HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://example.com$request_uri;
}

# 旧域名 → 新域名
server {
    listen 80;
    server_name old-domain.com;
    return 301 http://new-domain.com$request_uri;
}
```

## 实战场景

### 场景1：配置 WordPress 伪静态

```bash
# 1. 配置 Nginx
cat > /etc/nginx/conf.d/wordpress.conf << 'EOF'
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/wordpress;
    index index.php;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# 2. 测试并重载
nginx -t && nginx -s reload

# 3. WordPress 后台设置固定链接
# 设置 → 固定链接 → 选择"文章名"或自定义
```

### 场景2：移动端自动跳转

```bash
cat > /etc/nginx/conf.d/mobile.conf << 'EOF'
server {
    listen 80;
    server_name www.example.com;
    root /data/www/pc;
    
    set $mobile_rewrite do_not_perform;
    
    if ($http_user_agent ~* "(android|iphone|ipad|phone|mobile)") {
        set $mobile_rewrite perform;
    }
    
    if ($mobile_rewrite = perform) {
        return 302 http://m.example.com$request_uri;
    }
}

server {
    listen 80;
    server_name m.example.com;
    root /data/www/mobile;
}
EOF

nginx -t && nginx -s reload
```

### 场景3：图片防盗链

```bash
cat > /etc/nginx/conf.d/hotlink.conf << 'EOF'
server {
    listen 80;
    server_name img.example.com;
    root /data/www/images;
    
    location ~* \.(jpg|jpeg|png|gif)$ {
        valid_referers none blocked example.com *.example.com;
        
        if ($invalid_referer) {
            return 403;
        }
        
        expires 30d;
    }
}
EOF

nginx -t && nginx -s reload
```

### 场景4：SEO 优化（去除 www）

```bash
cat > /etc/nginx/conf.d/seo.conf << 'EOF'
server {
    listen 80;
    server_name www.example.com;
    return 301 http://example.com$request_uri;
}

server {
    listen 80;
    server_name example.com;
    root /data/www/example;
    index index.html;
}
EOF

nginx -t && nginx -s reload
```

## 常见问题

### 问题1：重写循环

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

location ~ \.php$ {
    fastcgi_pass 127.0.0.1:9000;
    include fastcgi_params;
}
```

### 问题2：正则未转义

```nginx
# 错误：. 匹配任意字符
rewrite ^/test.html$ /new.html last;

# 正确：转义 .
rewrite ^/test\.html$ /new.html last;
```

### 问题3：flag 使用错误

```nginx
# last vs break
location /test1/ {
    rewrite ^/test1/(.*)$ /new/$1 last;   # 重新搜索 location
}

location /test2/ {
    rewrite ^/test2/(.*)$ /new/$1 break;  # 停止处理
}

# redirect vs permanent
rewrite ^/temp$ /new redirect;    # 302 临时
rewrite ^/old$ /new permanent;    # 301 永久
```

### 问题4：if 判断失效

```nginx
# 错误：多个条件需要组合
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
```

## 调试技巧

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

# 过滤 rewrite 日志
tail -f /var/log/nginx/error.log | grep rewrite
```

### 测试重定向

```bash
# 查看重定向
curl -I http://example.com/old

# 不跟随重定向
curl -I --max-redirs 0 http://example.com/old

# 查看完整请求
curl -v http://example.com/old
```

## 性能优化

### 1. 使用 try_files 代替 if

```nginx
# 不推荐
if (!-f $request_filename) {
    rewrite ^(.*)$ /index.php last;
}

# 推荐
try_files $uri $uri/ /index.php?$args;
```

### 2. 减少 rewrite 规则

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

### 3. 避免过多 if

```nginx
# 不推荐
if ($condition1) { }
if ($condition2) { }
if ($condition3) { }

# 推荐：使用 map
map $condition $result {
    default 0;
    ~pattern1 1;
    ~pattern2 2;
}
```

## 练习题

### 基础练习

1. 配置 /old 到 /new 的 301 重定向
2. 配置 www 到非 www 的重定向
3. 配置 HTTP 到 HTTPS 的重定向
4. 配置 /user/123 重写为 /profile?id=123
5. 配置去除 URL 中的 .html 后缀

### 进阶练习

1. 配置 WordPress 伪静态
2. 配置 Laravel 框架路由
3. 配置 Vue SPA 应用路由
4. 配置移动端自动跳转
5. 配置图片防盗链
6. 配置多语言网站
7. 配置静态资源版本控制

## 面试常考

1. rewrite 指令的语法和 flag 有哪些？
2. last 和 break 的区别？
3. redirect 和 permanent 的区别？
4. if 指令有哪些判断条件？
5. try_files 的工作原理？
6. 如何配置 WordPress 伪静态？
7. 如何实现移动端自动跳转？
8. 如何配置防盗链？
9. 如何避免重写循环？
10. 如何优化 rewrite 性能？

## 学习建议

### 1. 理解原理

- 先理解 rewrite 的工作流程
- 掌握正则表达式
- 理解 flag 的作用

### 2. 实践为主

- 搭建测试环境
- 尝试不同的配置
- 查看日志调试

### 3. 参考案例

- 学习常见框架的配置
- 参考官方文档
- 借鉴优秀案例

### 4. 性能优化

- 优先使用 try_files
- 减少 if 判断
- 合并重写规则

## 推荐资源

### 官方文档

- [Nginx Rewrite 模块](http://nginx.org/en/docs/http/ngx_http_rewrite_module.html)
- [Nginx If 指令](http://nginx.org/en/docs/http/ngx_http_rewrite_module.html#if)

### 正则表达式

- [正则表达式在线测试](https://regex101.com/)
- [正则表达式教程](https://www.regular-expressions.info/)

### 配置生成器

- [Nginx 配置生成器](https://nginxconfig.io/)

## 下一步

完成 Rewrite 学习后，继续学习：
- **Nginx 性能优化**：深度调优参数
- **NFS**：网络文件系统

Rewrite 是 Nginx 的核心功能，掌握它能让你的网站更加灵活和友好！

加油！💪
