# HTTPS 基础与原理

## 什么是 HTTPS？

HTTPS（HyperText Transfer Protocol Secure）是 HTTP 的安全版本，通过 SSL/TLS 协议对数据进行加密传输。

### HTTP vs HTTPS

```
HTTP（明文传输）
客户端 ──────────────▶ 服务器
       明文数据
       容易被窃听、篡改

HTTPS（加密传输）
客户端 ──────────────▶ 服务器
       加密数据
       安全、可信
```

### HTTPS 的优势

- **数据加密**：防止数据被窃听
- **数据完整性**：防止数据被篡改
- **身份认证**：确认服务器身份
- **SEO 优化**：搜索引擎优先收录
- **用户信任**：浏览器显示安全标识
- **合规要求**：某些行业必须使用

---

## SSL/TLS 协议

### SSL 和 TLS 的关系

```
SSL 1.0  →  未发布
SSL 2.0  →  1995年（已废弃）
SSL 3.0  →  1996年（已废弃）
TLS 1.0  →  1999年（不推荐）
TLS 1.1  →  2006年（不推荐）
TLS 1.2  →  2008年（推荐）✅
TLS 1.3  →  2018年（最推荐）✅
```

**注意**：现在说的 SSL 通常指 TLS，但习惯上仍称为 SSL 证书。

### TLS 握手过程

```
客户端                                    服务器
  │                                        │
  ├──────── 1. Client Hello ──────────────▶│
  │        （支持的加密套件）                │
  │                                        │
  │◀─────── 2. Server Hello ───────────────┤
  │        （选择的加密套件）                │
  │◀─────── 3. Certificate ────────────────┤
  │        （服务器证书）                    │
  │◀─────── 4. Server Hello Done ──────────┤
  │                                        │
  ├──────── 5. Client Key Exchange ───────▶│
  │        （预主密钥）                      │
  ├──────── 6. Change Cipher Spec ────────▶│
  ├──────── 7. Finished ──────────────────▶│
  │                                        │
  │◀─────── 8. Change Cipher Spec ─────────┤
  │◀─────── 9. Finished ───────────────────┤
  │                                        │
  └──────── 10. 加密通信 ─────────────────▶│
```

### 加密方式

#### 1. 对称加密

使用相同的密钥加密和解密。

```
加密：明文 + 密钥 → 密文
解密：密文 + 密钥 → 明文

优点：速度快
缺点：密钥传输不安全

常见算法：AES、DES、3DES
```

#### 2. 非对称加密

使用公钥加密，私钥解密。

```
加密：明文 + 公钥 → 密文
解密：密文 + 私钥 → 明文

优点：密钥传输安全
缺点：速度慢

常见算法：RSA、ECC
```

#### 3. 混合加密（HTTPS 使用）

```
1. 使用非对称加密传输对称密钥
2. 使用对称加密传输实际数据

兼顾安全性和性能
```

---

## SSL 证书

### 证书的作用

- **身份认证**：证明服务器身份
- **加密通信**：提供公钥用于加密
- **防止中间人攻击**：CA 签名验证

### 证书类型

#### 按验证级别分类

| 类型 | 验证内容 | 价格 | 适用场景 |
|------|----------|------|----------|
| DV（域名验证） | 仅验证域名所有权 | 免费-低 | 个人网站、博客 |
| OV（组织验证） | 验证域名+组织信息 | 中 | 企业网站 |
| EV（扩展验证） | 严格验证组织身份 | 高 | 金融、电商 |

#### 按域名数量分类

| 类型 | 说明 | 示例 |
|------|------|------|
| 单域名证书 | 保护一个域名 | www.example.com |
| 多域名证书 | 保护多个域名 | example.com, blog.com |
| 通配符证书 | 保护主域名和所有子域名 | *.example.com |

### 证书内容

```
证书包含：
- 域名信息
- 组织信息
- 公钥
- 证书有效期
- 证书颁发机构（CA）
- CA 数字签名
```

### 证书链

```
根证书（Root CA）
    │
    ├─ 中间证书（Intermediate CA）
    │       │
    │       ├─ 服务器证书（Server Certificate）
    │       │
    │       └─ 服务器证书（Server Certificate）
    │
    └─ 中间证书（Intermediate CA）
```

---

## 证书颁发机构（CA）

### 知名 CA

#### 商业 CA

- **DigiCert**：全球最大的 CA
- **GlobalSign**：老牌 CA
- **GeoTrust**：性价比高
- **Comodo**：市场份额大
- **Symantec**：已被 DigiCert 收购

#### 免费 CA

- **Let's Encrypt**：最流行的免费 CA ✅
- **ZeroSSL**：免费 SSL 证书
- **Cloudflare**：提供免费证书

### Let's Encrypt

```
特点：
✅ 完全免费
✅ 自动化签发
✅ 90 天有效期（自动续期）
✅ 支持通配符证书
✅ 被所有主流浏览器信任

限制：
❌ 仅支持 DV 证书
❌ 不支持 OV/EV 证书
❌ 需要定期续期
```

---

## 证书格式

### 常见格式

| 格式 | 扩展名 | 说明 | 用途 |
|------|--------|------|------|
| PEM | .pem, .crt, .cer | Base64 编码 | Nginx、Apache |
| DER | .der, .cer | 二进制编码 | Java |
| PKCS#12 | .pfx, .p12 | 包含私钥和证书 | Windows、IIS |
| PKCS#7 | .p7b, .p7c | 证书链 | Windows |

### PEM 格式（最常用）

```bash
# 证书文件（.crt 或 .pem）
-----BEGIN CERTIFICATE-----
MIIFXzCCBEegAwIBAgISA...
（Base64 编码的证书内容）
-----END CERTIFICATE-----

# 私钥文件（.key）
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0...
（Base64 编码的私钥内容）
-----END PRIVATE KEY-----

# 证书链文件（.pem）
-----BEGIN CERTIFICATE-----
（服务器证书）
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
（中间证书）
-----END CERTIFICATE-----
```

### 格式转换

```bash
# PEM 转 DER
openssl x509 -in cert.pem -outform der -out cert.der

# DER 转 PEM
openssl x509 -in cert.der -inform der -out cert.pem

# PEM 转 PKCS#12
openssl pkcs12 -export -in cert.pem -inkey key.pem -out cert.pfx

# PKCS#12 转 PEM
openssl pkcs12 -in cert.pfx -out cert.pem -nodes
```

---

## 自签名证书

### 什么是自签名证书？

自己签发的证书，不被浏览器信任，仅用于测试。

### 生成自签名证书

```bash
# 方法1：一步生成
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout selfsigned.key \
  -out selfsigned.crt \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=MyCompany/CN=example.com"

# 方法2：分步生成
# 1. 生成私钥
openssl genrsa -out selfsigned.key 2048

# 2. 生成证书签名请求（CSR）
openssl req -new -key selfsigned.key -out selfsigned.csr \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=MyCompany/CN=example.com"

# 3. 自签名生成证书
openssl x509 -req -days 365 -in selfsigned.csr \
  -signkey selfsigned.key -out selfsigned.crt
```

### 参数说明

```bash
-x509           # 生成自签名证书
-nodes          # 不加密私钥
-days 365       # 有效期 365 天
-newkey rsa:2048  # 生成 2048 位 RSA 密钥
-keyout         # 私钥输出文件
-out            # 证书输出文件
-subj           # 证书主题信息

# 主题信息字段
C   # 国家（Country）
ST  # 省份（State）
L   # 城市（Locality）
O   # 组织（Organization）
OU  # 部门（Organizational Unit）
CN  # 通用名称（Common Name）- 域名
```

---

## 证书查看和验证

### 查看证书信息

```bash
# 查看证书详细信息
openssl x509 -in cert.crt -text -noout

# 查看证书有效期
openssl x509 -in cert.crt -noout -dates

# 查看证书主题
openssl x509 -in cert.crt -noout -subject

# 查看证书颁发者
openssl x509 -in cert.crt -noout -issuer

# 查看证书指纹
openssl x509 -in cert.crt -noout -fingerprint
```

### 验证证书

```bash
# 验证证书和私钥是否匹配
openssl x509 -noout -modulus -in cert.crt | openssl md5
openssl rsa -noout -modulus -in key.key | openssl md5
# 两个 MD5 值应该相同

# 验证证书链
openssl verify -CAfile ca-bundle.crt cert.crt

# 测试 HTTPS 连接
openssl s_client -connect example.com:443 -servername example.com

# 查看网站证书
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
```

---

## HTTPS 工作流程

### 完整流程

```
1. 客户端发起 HTTPS 请求
   ↓
2. 服务器返回证书
   ↓
3. 客户端验证证书
   - 检查证书是否过期
   - 检查证书域名是否匹配
   - 检查证书是否被 CA 签名
   - 检查证书是否被吊销
   ↓
4. 客户端生成随机密钥
   ↓
5. 使用服务器公钥加密随机密钥
   ↓
6. 服务器使用私钥解密获得随机密钥
   ↓
7. 双方使用随机密钥进行对称加密通信
```

### 浏览器验证

```
✅ 证书有效
   - 绿色锁图标
   - 显示 "安全" 或 "Secure"

⚠️ 证书警告
   - 自签名证书
   - 证书过期
   - 域名不匹配
   - 证书被吊销

❌ 不安全
   - HTTP 连接
   - 显示 "不安全" 或 "Not Secure"
```

---

## HTTPS 性能影响

### 性能开销

```
1. TLS 握手开销
   - 增加 1-2 个 RTT（往返时间）
   - 首次连接较慢

2. 加密解密开销
   - CPU 计算增加
   - 现代硬件影响很小

3. 证书验证开销
   - 客户端验证证书
   - 可以缓存
```

### 优化方法

```
1. 使用 HTTP/2
   - 多路复用
   - 头部压缩

2. 启用 Session 复用
   - Session ID
   - Session Ticket

3. 启用 OCSP Stapling
   - 减少证书验证时间

4. 使用 CDN
   - 就近访问
   - 减少延迟

5. 硬件加速
   - 使用支持 AES-NI 的 CPU
```

---

## 常见问题

### 1. 为什么需要 HTTPS？

```
安全性：
- 防止数据被窃听（密码、信用卡等）
- 防止数据被篡改
- 防止中间人攻击

信任度：
- 浏览器显示安全标识
- 用户更信任

SEO：
- Google 优先收录 HTTPS 网站
- 排名更高

合规：
- 某些行业要求（金融、医疗）
- 隐私法规要求
```

### 2. HTTP 和 HTTPS 可以共存吗？

```
可以，但不推荐。

推荐做法：
1. 全站使用 HTTPS
2. HTTP 自动重定向到 HTTPS
3. 启用 HSTS 强制 HTTPS
```

### 3. 免费证书和付费证书的区别？

```
技术上：
- 加密强度相同
- 安全性相同

区别：
- 验证级别（DV vs OV/EV）
- 保险赔付
- 技术支持
- 品牌信任度

个人/小型网站：Let's Encrypt 足够
企业/电商网站：考虑 OV/EV 证书
```

---

## 安全建议

### 1. 使用强加密

```nginx
# 只使用 TLS 1.2 和 1.3
ssl_protocols TLSv1.2 TLSv1.3;

# 使用强加密套件
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';

# 优先使用服务器加密套件
ssl_prefer_server_ciphers on;
```

### 2. 定期更新证书

```bash
# Let's Encrypt 证书 90 天有效期
# 建议 60 天时续期
# 使用 certbot 自动续期

# 检查证书有效期
openssl x509 -in cert.crt -noout -dates
```

### 3. 保护私钥

```bash
# 私钥权限设置为 600
chmod 600 /path/to/private.key

# 私钥不要上传到版本控制
echo "*.key" >> .gitignore

# 定期更换证书和私钥
```

### 4. 启用 HSTS

```nginx
# 强制浏览器使用 HTTPS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

---

## 练习题

### 基础练习

1. 解释 HTTP 和 HTTPS 的区别
2. 说明 TLS 握手过程
3. 生成自签名证书
4. 查看证书的有效期和主题信息
5. 验证证书和私钥是否匹配

### 进阶练习

1. 解释对称加密和非对称加密的区别
2. 说明证书链的作用
3. 比较 DV、OV、EV 证书的区别
4. 转换证书格式（PEM、DER、PKCS#12）
5. 测试网站的 HTTPS 配置

---

## 总结

HTTPS 核心要点：
- ✅ 理解 HTTPS 工作原理
- ✅ 掌握 SSL/TLS 握手过程
- ✅ 了解证书类型和格式
- ✅ 学会生成和验证证书
- ✅ 知道如何优化 HTTPS 性能

---

## 下一步

完成 HTTPS 基础学习后，继续学习：
- **02_Nginx配置HTTPS.md**：在 Nginx 中配置 HTTPS
- **03_Let's Encrypt实战.md**：使用免费证书

HTTPS 是现代网站的标配，务必熟练掌握！
