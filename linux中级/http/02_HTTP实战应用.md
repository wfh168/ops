# HTTP 实战应用

## 一、使用 curl 进行 HTTP 测试

### 基本请求

```bash
# GET 请求
curl http://www.example.com

# 保存到文件
curl -o index.html http://www.example.com

# 下载文件
curl -O http://www.example.com/file.zip

# 断点续传
curl -C - -O http://www.example.com/large-file.zip
```

### 查看详细信息

```bash
# 查看响应头
curl -I http://www.example.com

# 查看详细过程
curl -v http://www.example.com

# 只看响应头和状态码
curl -s -o /dev/null -w "%{http_code}" http://www.example.com
```

### POST 请求

```bash
# 表单提交
curl -X POST -d "username=admin&password=123456" http://www.example.com/login

# JSON 提交
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"123456"}' \
     http://www.example.com/api/login

# 文件上传
curl -X POST -F "file=@/path/to/file.txt" http://www.example.com/upload
```

### 设置请求头

```bash
# 自定义 User-Agent
curl -A "MyApp/1.0" http://www.example.com

# 设置 Referer
curl -e "http://google.com" http://www.example.com

# 设置 Cookie
curl -b "session=abc123" http://www.example.com

# 保存 Cookie
curl -c cookies.txt http://www.example.com

# 使用 Cookie
curl -b cookies.txt http://www.example.com

# 自定义请求头
curl -H "Authorization: Bearer token123" http://www.example.com/api
```

### 认证

```bash
# Basic 认证
curl -u username:password http://www.example.com

# Bearer Token
curl -H "Authorization: Bearer your_token" http://www.example.com/api
```

### 代理

```bash
# 使用代理
curl -x proxy.example.com:8080 http://www.example.com

# 使用 SOCKS5 代理
curl --socks5 127.0.0.1:1080 http://www.example.com
```

---

## 二、使用 wget 下载文件

### 基本下载

```bash
# 下载文件
wget http://www.example.com/file.zip

# 指定文件名
wget -O myfile.zip http://www.example.com/file.zip

# 断点续传
wget -c http://www.example.com/large-file.zip

# 后台下载
wget -b http://www.example.com/file.zip

# 限速下载
wget --limit-rate=1m http://www.example.com/file.zip
```

### 批量下载

```bash
# 从文件读取 URL
cat urls.txt
http://example.com/file1.zip
http://example.com/file2.zip

wget -i urls.txt

# 递归下载
wget -r -np http://www.example.com/files/

# 镜像网站
wget -m http://www.example.com
```

---

## 三、HTTP 性能测试

### ab（Apache Bench）

```bash
# 安装
yum install -y httpd-tools

# 基本测试
ab -n 1000 -c 10 http://www.example.com/
# -n: 总请求数
# -c: 并发数

# 带认证
ab -n 1000 -c 10 -A username:password http://www.example.com/

# POST 请求
ab -n 1000 -c 10 -p data.txt -T application/json http://www.example.com/api

# 输出结果
Requests per second:    100.00 [#/sec]
Time per request:       100.000 [ms]
Transfer rate:          50.00 [Kbytes/sec]
```

### wrk

```bash
# 安装
git clone https://github.com/wg/wrk.git
cd wrk
make
cp wrk /usr/local/bin/

# 基本测试
wrk -t4 -c100 -d30s http://www.example.com/
# -t: 线程数
# -c: 连接数
# -d: 持续时间

# 使用脚本
wrk -t4 -c100 -d30s -s script.lua http://www.example.com/
```

---

## 四、HTTP 调试工具

### tcpdump 抓包

```bash
# 抓取 HTTP 请求
tcpdump -i eth0 -A -s 0 'tcp port 80'

# 保存到文件
tcpdump -i eth0 -w http.pcap 'tcp port 80'

# 只看 GET 请求
tcpdump -i eth0 -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' | grep GET
```

### nc（netcat）测试

```bash
# 发送 HTTP 请求
echo -e "GET / HTTP/1.1\r\nHost: www.example.com\r\n\r\n" | nc www.example.com 80

# 监听端口
nc -l 8080

# 在另一个终端发送请求
curl http://localhost:8080
```

---

## 五、HTTP API 测试

### RESTful API 测试

```bash
# GET - 获取资源列表
curl http://api.example.com/users

# GET - 获取单个资源
curl http://api.example.com/users/1

# POST - 创建资源
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"name":"John","email":"john@example.com"}' \
     http://api.example.com/users

# PUT - 更新资源
curl -X PUT \
     -H "Content-Type: application/json" \
     -d '{"name":"John Smith","email":"john@example.com"}' \
     http://api.example.com/users/1

# PATCH - 部分更新
curl -X PATCH \
     -H "Content-Type: application/json" \
     -d '{"email":"newemail@example.com"}' \
     http://api.example.com/users/1

# DELETE - 删除资源
curl -X DELETE http://api.example.com/users/1
```

### 带认证的 API

```bash
# Bearer Token
curl -H "Authorization: Bearer your_token_here" \
     http://api.example.com/protected

# API Key
curl -H "X-API-Key: your_api_key_here" \
     http://api.example.com/protected

# Basic Auth
curl -u username:password \
     http://api.example.com/protected
```

---

## 六、HTTP 代理

### 正向代理

```bash
# 使用 Squid 搭建代理
yum install -y squid

# 配置
vim /etc/squid/squid.conf
http_port 3128
acl localnet src 192.168.1.0/24
http_access allow localnet

# 启动
systemctl start squid

# 客户端使用
curl -x http://proxy:3128 http://www.example.com
```

### 反向代理

```bash
# Nginx 反向代理配置
server {
    listen 80;
    server_name www.example.com;
    
    location / {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 七、HTTP 缓存实战

### 浏览器缓存

```bash
# 强缓存
Cache-Control: max-age=3600
Expires: Wed, 21 Oct 2024 07:28:00 GMT

# 协商缓存
ETag: "abc123"
Last-Modified: Wed, 21 Oct 2024 07:28:00 GMT
```

### Nginx 缓存配置

```nginx
# 配置缓存路径
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g;

server {
    location / {
        proxy_cache my_cache;
        proxy_cache_valid 200 1h;
        proxy_cache_key $uri;
        proxy_pass http://backend;
    }
}
```

---

## 八、HTTP 安全

### HTTPS 重定向

```nginx
server {
    listen 80;
    server_name www.example.com;
    return 301 https://$server_name$request_uri;
}
```

### 安全头

```nginx
# 添加安全响应头
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options "nosniff";
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=31536000";
```

---

## 九、HTTP 监控

### 监控脚本

```bash
#!/bin/bash

URL="http://www.example.com"
TIMEOUT=5

# 检查 HTTP 状态码
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT $URL)

if [ $STATUS -eq 200 ]; then
    echo "OK: $URL is up (Status: $STATUS)"
    exit 0
else
    echo "CRITICAL: $URL is down (Status: $STATUS)"
    exit 2
fi
```

### 响应时间监控

```bash
#!/bin/bash

URL="http://www.example.com"

# 测试响应时间
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" $URL)

echo "Response time: ${RESPONSE_TIME}s"

# 如果响应时间超过1秒，发送告警
if [ $(echo "$RESPONSE_TIME > 1.0" | bc) -eq 1 ]; then
    echo "WARNING: Response time is slow"
fi
```

---

## 十、实战案例

### 案例1：API 健康检查

```bash
#!/bin/bash

API_URL="http://api.example.com/health"
EXPECTED_STATUS=200

check_api() {
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" $API_URL)
    
    if [ $STATUS -eq $EXPECTED_STATUS ]; then
        echo "$(date): API is healthy"
        return 0
    else
        echo "$(date): API is unhealthy (Status: $STATUS)"
        # 发送告警
        return 1
    fi
}

# 每分钟检查一次
while true; do
    check_api
    sleep 60
done
```

### 案例2：批量测试 URL

```bash
#!/bin/bash

# URL 列表
URLS=(
    "http://www.example1.com"
    "http://www.example2.com"
    "http://www.example3.com"
)

# 测试每个 URL
for url in "${URLS[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 $url)
    TIME=$(curl -s -o /dev/null -w "%{time_total}" --max-time 5 $url)
    
    echo "$url - Status: $STATUS, Time: ${TIME}s"
done
```

---

## 练习题

1. 如何使用 curl 发送 POST 请求？
2. 如何测试 API 的性能？
3. 如何监控网站的可用性？

<details>
<summary>答案</summary>

1. `curl -X POST -d "key=value" http://example.com` 或 `curl -X POST -H "Content-Type: application/json" -d '{"key":"value"}' http://example.com`
2. 使用 ab 或 wrk 工具进行压力测试，例如 `ab -n 1000 -c 10 http://example.com/`
3. 编写脚本定期检查 HTTP 状态码和响应时间，状态码非 200 或响应时间过长时发送告警

</details>
