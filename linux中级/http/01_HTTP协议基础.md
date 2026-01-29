# HTTP 协议基础

## 什么是 HTTP

HTTP（HyperText Transfer Protocol）超文本传输协议，是互联网上应用最广泛的协议。

```
客户端（浏览器）  ←──── HTTP ────→  服务器（Web Server）
```

---

## 一、HTTP 工作原理

### 请求-响应模型

```
1. 客户端发送 HTTP 请求
   ↓
2. 服务器接收请求
   ↓
3. 服务器处理请求
   ↓
4. 服务器返回 HTTP 响应
   ↓
5. 客户端接收响应
```

### HTTP 特点

| 特点 | 说明 |
|------|------|
| 无连接 | 每次请求后断开连接（HTTP/1.0） |
| 无状态 | 不保存客户端信息 |
| 简单快速 | 请求方法简单 |
| 灵活 | 可传输任意类型数据 |

---

## 二、HTTP 请求

### 请求格式

```
请求行
请求头
空行
请求体
```

### 请求示例

```http
GET /index.html HTTP/1.1
Host: www.example.com
User-Agent: Mozilla/5.0
Accept: text/html
Connection: keep-alive

```

### 请求行

```
方法 URL 协议版本
GET /index.html HTTP/1.1
```

---

## 三、HTTP 方法

### 常用方法

| 方法 | 说明 | 幂等性 |
|------|------|--------|
| GET | 获取资源 | ✅ |
| POST | 提交数据 | ❌ |
| PUT | 更新资源 | ✅ |
| DELETE | 删除资源 | ✅ |
| HEAD | 获取响应头 | ✅ |
| OPTIONS | 查询支持的方法 | ✅ |
| PATCH | 部分更新 | ❌ |

### GET vs POST

| 特性 | GET | POST |
|------|-----|------|
| 参数位置 | URL | 请求体 |
| 参数长度 | 有限制（2KB） | 无限制 |
| 安全性 | 参数可见 | 参数不可见 |
| 缓存 | 可缓存 | 不可缓存 |
| 书签 | 可收藏 | 不可收藏 |
| 幂等性 | 是 | 否 |

### 方法示例

```bash
# GET 请求
curl http://www.example.com/api/users

# POST 请求
curl -X POST -d "name=John&age=30" http://www.example.com/api/users

# PUT 请求
curl -X PUT -d "name=John&age=31" http://www.example.com/api/users/1

# DELETE 请求
curl -X DELETE http://www.example.com/api/users/1
```

---

## 四、HTTP 响应

### 响应格式

```
状态行
响应头
空行
响应体
```

### 响应示例

```http
HTTP/1.1 200 OK
Server: nginx/1.18.0
Content-Type: text/html
Content-Length: 1024
Connection: keep-alive

<!DOCTYPE html>
<html>
<body>Hello World</body>
</html>
```

### 状态行

```
协议版本 状态码 状态描述
HTTP/1.1 200 OK
```

---

## 五、HTTP 状态码

### 状态码分类

| 类别 | 说明 |
|------|------|
| 1xx | 信息性状态码 |
| 2xx | 成功状态码 |
| 3xx | 重定向状态码 |
| 4xx | 客户端错误 |
| 5xx | 服务器错误 |

### 常见状态码

#### 2xx 成功

| 状态码 | 说明 |
|--------|------|
| 200 | OK - 请求成功 |
| 201 | Created - 资源创建成功 |
| 204 | No Content - 成功但无内容 |

#### 3xx 重定向

| 状态码 | 说明 |
|--------|------|
| 301 | Moved Permanently - 永久重定向 |
| 302 | Found - 临时重定向 |
| 304 | Not Modified - 资源未修改 |

#### 4xx 客户端错误

| 状态码 | 说明 |
|--------|------|
| 400 | Bad Request - 请求错误 |
| 401 | Unauthorized - 未授权 |
| 403 | Forbidden - 禁止访问 |
| 404 | Not Found - 资源不存在 |
| 405 | Method Not Allowed - 方法不允许 |

#### 5xx 服务器错误

| 状态码 | 说明 |
|--------|------|
| 500 | Internal Server Error - 服务器内部错误 |
| 502 | Bad Gateway - 网关错误 |
| 503 | Service Unavailable - 服务不可用 |
| 504 | Gateway Timeout - 网关超时 |

---

## 六、HTTP 请求头

### 常用请求头

| 请求头 | 说明 | 示例 |
|--------|------|------|
| Host | 目标主机 | Host: www.example.com |
| User-Agent | 客户端信息 | User-Agent: Mozilla/5.0 |
| Accept | 可接受的内容类型 | Accept: text/html |
| Accept-Encoding | 可接受的编码 | Accept-Encoding: gzip |
| Accept-Language | 可接受的语言 | Accept-Language: zh-CN |
| Connection | 连接类型 | Connection: keep-alive |
| Cookie | Cookie 信息 | Cookie: session=abc123 |
| Referer | 来源页面 | Referer: http://google.com |
| Authorization | 认证信息 | Authorization: Bearer token |

---

## 七、HTTP 响应头

### 常用响应头

| 响应头 | 说明 | 示例 |
|--------|------|------|
| Server | 服务器信息 | Server: nginx/1.18.0 |
| Content-Type | 内容类型 | Content-Type: text/html |
| Content-Length | 内容长度 | Content-Length: 1024 |
| Content-Encoding | 内容编码 | Content-Encoding: gzip |
| Set-Cookie | 设置 Cookie | Set-Cookie: session=abc123 |
| Cache-Control | 缓存控制 | Cache-Control: max-age=3600 |
| Expires | 过期时间 | Expires: Wed, 21 Oct 2024 |
| Location | 重定向地址 | Location: /new-page |
| ETag | 资源标识 | ETag: "abc123" |

---

## 八、Content-Type

### 常见 MIME 类型

| Content-Type | 说明 |
|--------------|------|
| text/html | HTML 文档 |
| text/plain | 纯文本 |
| text/css | CSS 样式表 |
| text/javascript | JavaScript |
| application/json | JSON 数据 |
| application/xml | XML 数据 |
| application/pdf | PDF 文档 |
| image/jpeg | JPEG 图片 |
| image/png | PNG 图片 |
| image/gif | GIF 图片 |
| video/mp4 | MP4 视频 |
| audio/mpeg | MP3 音频 |

---

## 九、HTTP 版本

### HTTP/1.0

```bash
# 特点
- 每次请求都要建立新连接
- 无法复用连接
- 性能较差
```

### HTTP/1.1

```bash
# 特点
- 持久连接（keep-alive）
- 管道化（pipelining）
- 支持分块传输
- 增加 Host 头

# 改进
- 减少连接建立次数
- 提高传输效率
```

### HTTP/2

```bash
# 特点
- 二进制协议
- 多路复用
- 头部压缩
- 服务器推送

# 优势
- 更快的页面加载
- 更少的网络延迟
```

---

## 十、实战演示

### 使用 curl 测试

```bash
# 基本请求
curl http://www.example.com

# 查看响应头
curl -I http://www.example.com

# 详细信息
curl -v http://www.example.com

# POST 请求
curl -X POST -d "name=John" http://www.example.com/api

# 设置请求头
curl -H "Content-Type: application/json" http://www.example.com

# 发送 JSON
curl -X POST -H "Content-Type: application/json" \
     -d '{"name":"John","age":30}' \
     http://www.example.com/api/users
```

### 使用 telnet 测试

```bash
# 连接服务器
telnet www.example.com 80

# 发送请求
GET / HTTP/1.1
Host: www.example.com
[回车两次]
```

### 使用 nc 测试

```bash
# 发送 HTTP 请求
echo -e "GET / HTTP/1.1\r\nHost: www.example.com\r\n\r\n" | nc www.example.com 80
```

---

## 十一、HTTP 会话保持

### Cookie

```bash
# 服务器设置 Cookie
Set-Cookie: session=abc123; Path=/; HttpOnly

# 客户端发送 Cookie
Cookie: session=abc123
```

### Session

```bash
# 工作流程
1. 客户端首次访问
2. 服务器创建 Session
3. 返回 Session ID（通过 Cookie）
4. 客户端后续请求携带 Session ID
5. 服务器根据 Session ID 识别用户
```

---

## 十二、HTTP 缓存

### 缓存控制

```bash
# 强缓存
Cache-Control: max-age=3600        # 缓存1小时
Expires: Wed, 21 Oct 2024 07:28:00 GMT

# 协商缓存
ETag: "abc123"                     # 资源标识
Last-Modified: Wed, 21 Oct 2024    # 最后修改时间
```

### 缓存流程

```
1. 客户端请求资源
2. 检查本地缓存
3. 如果缓存有效，直接使用
4. 如果缓存过期，向服务器验证
5. 服务器返回 304（未修改）或 200（新内容）
```

---

## 练习题

1. HTTP 请求由哪几部分组成？
2. GET 和 POST 的主要区别是什么？
3. 常见的 HTTP 状态码有哪些？

<details>
<summary>答案</summary>

1. 请求行、请求头、空行、请求体
2. GET 参数在 URL 中，POST 在请求体中；GET 可缓存，POST 不可缓存；GET 幂等，POST 不幂等
3. 200（成功）、301/302（重定向）、404（未找到）、500（服务器错误）、502（网关错误）、503（服务不可用）

</details>
