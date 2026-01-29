# Rewrite 实战案例

## 常见 CMS 和框架的 Rewrite 规则

### 1. WordPress

```nginx
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/wordpress;
    index index.php;
    
    # 方法1：使用 try_files（推荐）
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    # 方法2：使用 rewrite
    location / {
        if (!-e $request_filename) {
            rewrite ^(.*)$ /index.php?s=$1 last;
        }
    }
    
    # PHP 处理
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
}
```

### 2. Typecho

```nginx
server {
    listen 80;
    server_name blog.example.com;
    root /data/www/typecho;
    index index.php;
    
    location / {
        if (!-e $request_filename) {
            rewrite ^(.*)$ /index.php$1 last;
        }
    }
    
    location ~ .*\.php(\/.*)*$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        set $real_script_name $fastcgi_script_name;
        if ($fastcgi_script_name ~ "^(.+?\.php)(/.+)$") {
            set $real_script_name $1;
        }
        fastcgi_param SCRIPT_FILENAME $document_root$real_script_name;
        fastcgi_param SCRIPT_NAME $real_script_name;
    }
}
```

### 3. Discuz 论坛

```nginx
server {
    listen 80;
    server_name forum.example.com;
    root /data/www/discuz;
    index index.php;
    
    location / {
        # 主题
        rewrite ^([^\.]*)/topic-(.+)\.html$ $1/portal.php?mod=topic&topic=$2 last;
        
        # 文章
        rewrite ^([^\.]*)/article-([0-9]+)-([0-9]+)\.html$ $1/portal.php?mod=view&aid=$2&page=$3 last;
        
        # 版块
        rewrite ^([^\.]*)/forum-(\w+)-([0-9]+)\.html$ $1/forum.php?mod=forumdisplay&fid=$2&page=$3 last;
        
        # 帖子
        rewrite ^([^\.]*)/thread-([0-9]+)-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=viewthread&tid=$2&extra=page%3D$4&page=$3 last;
        
        # 空间
        rewrite ^([^\.]*)/space-(username|uid)-(.+)\.html$ $1/home.php?mod=space&$2=$3 last;
        
        # 标签
        rewrite ^([^\.]*)/tag-(.+)\.html$ $1/tag.php?name=$2 last;
    }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
```

### 4. ThinkPHP 5/6

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
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### 5. Laravel

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
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

### 6. Yii2

```nginx
server {
    listen 80;
    server_name yii.example.com;
    root /data/www/yii2/web;
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
```

### 7. CodeIgniter

```nginx
server {
    listen 80;
    server_name ci.example.com;
    root /data/www/codeigniter;
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

### 8. Drupal

```nginx
server {
    listen 80;
    server_name drupal.example.com;
    root /data/www/drupal;
    index index.php;
    
    location / {
        try_files $uri /index.php?$query_string;
    }
    
    location @rewrite {
        rewrite ^/(.*)$ /index.php?q=$1;
    }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
```

---

## 前端框架 SPA 路由

### Vue.js / React / Angular

```nginx
server {
    listen 80;
    server_name app.example.com;
    root /data/www/spa/dist;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API 代理
    location /api/ {
        proxy_pass http://backend:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## SEO 优化案例

### 案例1：去除 index.php

```nginx
server {
    listen 80;
    server_name example.com;
    
    # /index.php/page → /page
    if ($request_uri ~* "^/index\.php(.*)") {
        return 301 $1;
    }
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
}
```

### 案例2：去除尾部斜杠

```nginx
server {
    listen 80;
    server_name example.com;
    
    # /page/ → /page
    rewrite ^/(.*)/$ /$1 permanent;
}
```

### 案例3：添加尾部斜杠

```nginx
server {
    listen 80;
    server_name example.com;
    
    # /page → /page/
    rewrite ^([^.]*[^/])$ $1/ permanent;
}
```

### 案例4：小写 URL

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 将大写 URL 重定向到小写
    location ~ [A-Z] {
        rewrite ^(.*)$ $scheme://$host$uri permanent;
    }
}
```

---

## 域名和协议重定向

### 案例1：多域名统一

```nginx
server {
    listen 80;
    server_name example.com www.example.com old-domain.com www.old-domain.com;
    
    # 统一到 www.example.com
    if ($host != "www.example.com") {
        return 301 https://www.example.com$request_uri;
    }
}
```

### 案例2：强制 HTTPS

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    
    # HTTP → HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL 配置...
}
```

### 案例3：去除 www 并强制 HTTPS

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name www.example.com;
    
    # www.example.com → example.com (HTTPS)
    return 301 https://example.com$request_uri;
}

server {
    listen 80;
    server_name example.com;
    
    # HTTP → HTTPS
    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;
    
    # 主站配置...
}
```

---

## 移动端适配

### 案例1：自动跳转移动站

```nginx
server {
    listen 80;
    server_name www.example.com;
    root /data/www/pc;
    
    # 检测移动设备
    set $mobile_rewrite do_not_perform;
    
    if ($http_user_agent ~* "(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino") {
        set $mobile_rewrite perform;
    }
    
    if ($http_user_agent ~* "^(1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-)") {
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
```

### 案例2：响应式设计（同一套代码）

```nginx
server {
    listen 80;
    server_name www.example.com;
    root /data/www/responsive;
    
    # 根据设备类型设置变量
    set $device "desktop";
    
    if ($http_user_agent ~* "(android|iphone|ipad|phone|mobile)") {
        set $device "mobile";
    }
    
    # 可以在应用中使用 $device 变量
    location / {
        add_header X-Device-Type $device;
        try_files $uri $uri/ /index.html;
    }
}
```

---

## 防盗链

### 案例1：图片防盗链

```nginx
server {
    listen 80;
    server_name example.com;
    
    location ~* \.(jpg|jpeg|png|gif|bmp)$ {
        valid_referers none blocked example.com *.example.com;
        
        if ($invalid_referer) {
            return 403;
            # 或返回防盗链图片
            # rewrite ^/ /images/hotlink.jpg break;
        }
        
        expires 30d;
    }
}
```

### 案例2：文件下载防盗链

```nginx
server {
    listen 80;
    server_name download.example.com;
    
    location ~* \.(zip|rar|7z|tar|gz)$ {
        valid_referers none blocked download.example.com;
        
        if ($invalid_referer) {
            return 403 "Forbidden: Direct download not allowed";
        }
        
        # 限速
        limit_rate 1m;
    }
}
```

---

## 访问控制

### 案例1：IP 白名单

```nginx
server {
    listen 80;
    server_name admin.example.com;
    
    location /admin/ {
        allow 192.168.1.0/24;
        allow 10.0.0.1;
        deny all;
        
        try_files $uri $uri/ /index.php?$args;
    }
}
```

### 案例2：时间段访问控制

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 只允许工作时间访问（9:00-18:00）
    if ($time_iso8601 ~ "T(0[0-8]|1[89]|2[0-3])") {
        return 403 "Access denied outside business hours";
    }
}
```

### 案例3：User-Agent 过滤

```nginx
server {
    listen 80;
    server_name example.com;
    
    # 禁止爬虫
    if ($http_user_agent ~* (scrapy|curl|wget|python|java|httpclient)) {
        return 403;
    }
    
    # 禁止特定爬虫
    if ($http_user_agent ~* (Baiduspider|Googlebot|bingbot)) {
        return 403;
    }
}
```

---

## 性能优化案例

### 案例1：静态资源版本控制

```nginx
server {
    listen 80;
    server_name static.example.com;
    root /data/www/static;
    
    # /css/style.v123.css → /css/style.css
    location ~* ^(.+)\.(v\d+)\.(js|css|png|jpg|jpeg|gif|ico)$ {
        try_files $uri $1.$3;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 案例2：WebP 图片自动转换

```nginx
server {
    listen 80;
    server_name img.example.com;
    root /data/www/images;
    
    location ~* \.(jpg|jpeg|png)$ {
        # 如果浏览器支持 WebP
        if ($http_accept ~* "webp") {
            rewrite ^(.*)$ $1.webp break;
        }
        
        expires 30d;
    }
}
```

---

## 多语言网站

### 案例1：子域名多语言

```nginx
# 中文站
server {
    listen 80;
    server_name cn.example.com;
    root /data/www/cn;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
}

# 英文站
server {
    listen 80;
    server_name en.example.com;
    root /data/www/en;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
}

# 主站重定向
server {
    listen 80;
    server_name example.com;
    
    # 根据浏览器语言重定向
    set $lang "en";
    
    if ($http_accept_language ~* "zh") {
        set $lang "cn";
    }
    
    return 302 http://$lang.example.com$request_uri;
}
```

### 案例2：路径多语言

```nginx
server {
    listen 80;
    server_name example.com;
    root /data/www;
    
    # /cn/page → /cn/index.php?page=page
    location ~* ^/(cn|en|jp)/(.*)$ {
        set $lang $1;
        set $path $2;
        
        try_files /$lang/$path /$lang/index.php?page=$path;
    }
    
    # 默认语言
    location / {
        set $lang "en";
        
        if ($http_accept_language ~* "zh") {
            set $lang "cn";
        }
        
        rewrite ^(.*)$ /$lang$1 redirect;
    }
}
```

---

## 练习题

### 基础练习

1. 配置 WordPress 伪静态
2. 配置域名重定向（www → 非 www）
3. 配置 HTTP 到 HTTPS 重定向
4. 配置移动端自动跳转
5. 配置图片防盗链

### 进阶练习

1. 配置 Laravel 框架路由
2. 配置 Vue SPA 应用路由
3. 配置多语言网站
4. 配置静态资源版本控制
5. 配置 WebP 图片自动转换
6. 配置访问控制（IP、时间、User-Agent）

---

## 总结

Rewrite 实战要点：
- ✅ 掌握常见 CMS 和框架的规则
- ✅ 学会 SEO 优化技巧
- ✅ 实现移动端适配
- ✅ 配置防盗链和访问控制
- ✅ 优化静态资源加载
- ✅ 支持多语言网站

Rewrite 是 Nginx 的强大功能，灵活运用可以解决很多实际问题！
