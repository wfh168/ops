# HTTP 协议学习指南

## 学习路线

```
01_HTTP协议基础.md    ──▶  理解 HTTP 工作原理
        │
        ▼
02_HTTP实战应用.md    ──▶  掌握 HTTP 测试和调试
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_HTTP协议基础.md | HTTP 原理、方法、状态码 | 1 天 |
| 02_HTTP实战应用.md | curl、wget、API 测试 | 1 天 |

## 核心知识点

### HTTP 基础
- 请求-响应模型
- HTTP 方法（GET、POST、PUT、DELETE）
- HTTP 状态码（2xx、3xx、4xx、5xx）
- 请求头和响应头

### HTTP 实战
- curl 命令使用
- wget 下载文件
- API 测试
- 性能测试（ab、wrk）

## 常用命令速查

### curl 基本用法

```bash
curl http://example.com                    # GET 请求
curl -I http://example.com                 # 查看响应头
curl -v http://example.com                 # 详细信息
curl -X POST -d "key=value" http://...     # POST 请求
curl -H "Header: value" http://...         # 自定义请求头
curl -u user:pass http://...               # 认证
```

### wget 基本用法

```bash
wget http://example.com/file.zip           # 下载文件
wget -c http://example.com/file.zip        # 断点续传
wget -b http://example.com/file.zip        # 后台下载
wget -i urls.txt                           # 批量下载
```

### 性能测试

```bash
ab -n 1000 -c 10 http://example.com/       # Apache Bench
wrk -t4 -c100 -d30s http://example.com/    # wrk
```

## HTTP 状态码速查

### 2xx 成功

```bash
200 OK                    # 请求成功
201 Created               # 资源创建成功
204 No Content            # 成功但无内容
```

### 3xx 重定向

```bash
301 Moved Permanently     # 永久重定向
302 Found                 # 临时重定向
304 Not Modified          # 资源未修改
```

### 4xx 客户端错误

```bash
400 Bad Request           # 请求错误
401 Unauthorized          # 未授权
403 Forbidden             # 禁止访问
404 Not Found             # 资源不存在
405 Method Not Allowed    # 方法不允许
```

### 5xx 服务器错误

```bash
500 Internal Server Error # 服务器内部错误
502 Bad Gateway           # 网关错误
503 Service Unavailable   # 服务不可用
504 Gateway Timeout       # 网关超时
```

## 实战场景

### 场景1：测试 API

```bash
# GET 请求
curl http://api.example.com/users

# POST 创建
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"name":"John"}' \
     http://api.example.com/users

# PUT 更新
curl -X PUT \
     -H "Content-Type: application/json" \
     -d '{"name":"John Smith"}' \
     http://api.example.com/users/1

# DELETE 删除
curl -X DELETE http://api.example.com/users/1
```

### 场景2：性能测试

```bash
# 测试并发性能
ab -n 10000 -c 100 http://www.example.com/

# 查看结果
Requests per second:    1000.00 [#/sec]
Time per request:       100.000 [ms]
```

### 场景3：监控网站

```bash
#!/bin/bash
URL="http://www.example.com"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" $URL)

if [ $STATUS -eq 200 ]; then
    echo "OK"
else
    echo "ERROR: Status $STATUS"
fi
```

## 最佳实践

### 1. 使用 HTTPS

```bash
# 总是使用 HTTPS
https://www.example.com

# 而不是
http://www.example.com
```

### 2. 设置超时

```bash
# 避免请求hang住
curl --max-time 10 http://example.com
```

### 3. 错误处理

```bash
# 检查返回状态
if curl -f http://example.com; then
    echo "Success"
else
    echo "Failed"
fi
```

### 4. 使用连接池

```bash
# HTTP/1.1 默认使用 keep-alive
Connection: keep-alive
```

## 常见问题

### 1. 请求超时

```bash
# 增加超时时间
curl --max-time 30 http://example.com

# 或设置连接超时
curl --connect-timeout 10 http://example.com
```

### 2. SSL 证书错误

```bash
# 忽略证书验证（仅测试用）
curl -k https://example.com

# 指定证书
curl --cacert /path/to/cert.pem https://example.com
```

### 3. 重定向问题

```bash
# 跟随重定向
curl -L http://example.com
```

## 面试常考

1. HTTP 和 HTTPS 的区别？
2. GET 和 POST 的区别？
3. 常见的 HTTP 状态码有哪些？
4. HTTP/1.1 和 HTTP/2 的区别？
5. 什么是 RESTful API？

## 下一步

完成 HTTP 协议学习后，进入 **Nginx** 模块，学习最流行的 Web 服务器。

Nginx 是基于 HTTP 协议的，理解 HTTP 是学习 Nginx 的基础。
