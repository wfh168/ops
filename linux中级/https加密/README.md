# HTTPS 加密学习指南

## 学习路线

```
01_HTTPS基础与原理.md    ──▶  理解 HTTPS 工作原理
        │
        ▼
02_Nginx配置HTTPS.md     ──▶  在 Nginx 中配置 HTTPS
        │
        ▼
03_Let's Encrypt实战.md  ──▶  使用免费证书
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_HTTPS基础与原理.md | HTTPS 原理、SSL/TLS、证书 | 0.5 天 |
| 02_Nginx配置HTTPS.md | Nginx HTTPS 配置、优化 | 1 天 |
| 03_Let's Encrypt实战.md | 免费证书申请和自动续期 | 0.5 天 |

## 核心知识点

### HTTPS 基础
- HTTP vs HTTPS
- SSL/TLS 协议
- TLS 握手过程
- 对称加密和非对称加密
- SSL 证书类型和格式
- 证书颁发机构（CA）

### Nginx HTTPS
- SSL 证书配置
- SSL 协议和加密套件
- SSL 会话缓存
- OCSP Stapling
- HTTP/2 配置
- 安全头配置
- 性能优化

### Let's Encrypt
- Certbot 工具使用
- 证书申请和续期
- 通配符证书
- DNS 验证
- 自动化续期

## 常用命令速查

### OpenSSL 命令

```bash
# 生成自签名证书
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout selfsigned.key -out selfsigned.crt

# 查看证书信息
openssl x509 -in cert.crt -text -noout

# 查看证书有效期
openssl x509 -in cert.crt -noout -dates

# 验证证书和私钥匹配
openssl x509 -noout -modulus -in cert.crt | openssl md5
openssl rsa -noout -modulus -in cert.key | openssl md5

# 测试 HTTPS 连接
openssl s_client -connect example.com:443 -servername example.com

# 格式转换
openssl x509 -in cert.pem -outform der -out cert.der
openssl pkcs12 -export -in cert.pem -inkey key.pem -out cert.pfx
```

### Certbot 命令

```bash
# 安装 Certbot
yum install certbot python2-certbot-nginx -y

# 自动配置
certbot --nginx -d example.com -d www.example.com

# 仅获取证书
certbot certonly --webroot -w /data/www/example -d example.com

# 通配符证书
certbot certonly --manual --preferred-challenges dns \
  -d example.com -d *.example.com

# 查看证书
certbot certificates

# 续期测试
certbot renew --dry-run

# 手动续期
certbot renew

# 删除证书
certbot delete --cert-name example.com
```

## Nginx HTTPS 配置模板

### 基本配置

```nginx
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    ssl_certificate /etc/nginx/ssl/cert.crt;
    ssl_certificate_key /etc/nginx/ssl/cert.key;
    
    root /data/www/example;
    index index.html;
}

server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}
```

### 完整配置（推荐）

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL 证书
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # SSL 协议和加密套件
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers on;
    
    # SSL 会话缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # DH 参数
    ssl_dhparam /etc/nginx/ssl/dhparam.pem;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    root /data/www/example;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}
```

## 实战场景

### 场景1：为现有网站添加 HTTPS

```bash
# 1. 确保网站可以通过 HTTP 访问
curl http://example.com

# 2. 使用 Certbot 获取证书
certbot --nginx -d example.com -d www.example.com

# 3. 选择重定向 HTTP 到 HTTPS（选项 2）

# 4. 测试 HTTPS
curl -I https://example.com

# 5. 测试 SSL 评级
# 访问 https://www.ssllabs.com/ssltest/
```

### 场景2：配置通配符证书

```bash
# 1. 获取通配符证书
certbot certonly --manual --preferred-challenges dns \
  -d example.com -d *.example.com

# 2. 添加 DNS TXT 记录
# _acme-challenge.example.com TXT "验证字符串"

# 3. 验证 DNS
dig -t txt _acme-challenge.example.com

# 4. 配置 Nginx
cat > /etc/nginx/conf.d/wildcard.conf << 'EOF'
server {
    listen 443 ssl http2;
    server_name *.example.com;
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    root /data/www/$host;
    index index.html;
}
EOF

# 5. 测试并重载
nginx -t && nginx -s reload
```

### 场景3：配置自动续期

```bash
# 1. 测试续期
certbot renew --dry-run

# 2. 配置 cron 自动续期
crontab -e

# 添加
0 2 * * * certbot renew --quiet --post-hook "nginx -s reload"

# 3. 或使用 systemd timer
systemctl enable certbot-renew.timer
systemctl start certbot-renew.timer
```

### 场景4：多域名 HTTPS

```bash
# 方法1：一个证书多个域名
certbot --nginx \
  -d example.com -d www.example.com \
  -d blog.example.com -d api.example.com

# 方法2：每个域名单独证书
certbot --nginx -d example.com -d www.example.com
certbot --nginx -d blog.example.com
certbot --nginx -d api.example.com
```

## SSL 安全配置检查清单

### 必须配置

```
✅ 使用 TLS 1.2 和 1.3
✅ 使用强加密套件
✅ 配置完整证书链（fullchain.pem）
✅ HTTP 重定向到 HTTPS
✅ 配置 HSTS 头
```

### 推荐配置

```
✅ 启用 HTTP/2
✅ 配置 SSL 会话缓存
✅ 启用 OCSP Stapling
✅ 生成 DH 参数
✅ 配置其他安全头
✅ 定期更新证书
```

### 性能优化

```
✅ 启用 SSL 会话复用
✅ 启用 HTTP/2
✅ 启用 OCSP Stapling
✅ 使用 CDN
✅ 启用 Gzip 压缩
```

## 证书类型选择

### 个人网站/博客

```
推荐：Let's Encrypt（免费 DV 证书）

优点：
- 完全免费
- 自动化
- 足够安全

缺点：
- 90 天有效期
- 需要自动续期
```

### 企业网站

```
推荐：商业 OV 证书

优点：
- 显示组织信息
- 更高信任度
- 技术支持

价格：几百到几千元/年
```

### 电商/金融网站

```
推荐：EV 证书

优点：
- 最高信任度
- 地址栏显示公司名
- 保险赔付

价格：几千到上万元/年
```

## 故障排查

### 常见问题

```bash
# 1. 证书不被信任
# 原因：使用 cert.pem 而不是 fullchain.pem
# 解决：使用完整证书链
ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;

# 2. 证书和私钥不匹配
# 验证
openssl x509 -noout -modulus -in cert.crt | openssl md5
openssl rsa -noout -modulus -in cert.key | openssl md5

# 3. Mixed Content 警告
# 解决：所有资源使用 HTTPS 或协议相对 URL
<script src="https://example.com/script.js"></script>
<script src="//example.com/script.js"></script>

# 4. Let's Encrypt 验证失败
# 检查域名解析
dig example.com
# 检查防火墙
firewall-cmd --list-all
# 检查 webroot 路径
ls -la /data/www/example/.well-known/acme-challenge/

# 5. 续期失败
# 查看日志
cat /var/log/letsencrypt/letsencrypt.log
# 测试续期
certbot renew --dry-run
```

## 测试工具

### 在线测试

```
SSL Labs（最权威）
https://www.ssllabs.com/ssltest/

目标：A+ 评级

其他工具：
https://www.sslshopper.com/ssl-checker.html
https://www.digicert.com/help/
https://securityheaders.com/
```

### 命令行测试

```bash
# 测试 HTTPS 连接
curl -I https://example.com

# 详细信息
curl -v https://example.com

# 测试 SSL
openssl s_client -connect example.com:443 -servername example.com

# 测试 TLS 版本
openssl s_client -connect example.com:443 -tls1_2
openssl s_client -connect example.com:443 -tls1_3

# 测试 OCSP Stapling
openssl s_client -connect example.com:443 -status
```

## 练习题

### 基础练习

1. 生成自签名证书并配置 Nginx
2. 使用 Let's Encrypt 获取免费证书
3. 配置 HTTP 到 HTTPS 重定向
4. 配置 HSTS 头
5. 测试网站的 SSL 评级

### 进阶练习

1. 配置完整的 SSL 安全参数
2. 启用 HTTP/2
3. 配置 OCSP Stapling
4. 获取通配符证书
5. 配置自动续期
6. 优化 SSL 性能
7. 配置多域名 HTTPS
8. 使用 DNS 插件自动验证

## 面试常考

1. HTTP 和 HTTPS 的区别？
2. HTTPS 的工作原理？
3. 对称加密和非对称加密的区别？
4. SSL/TLS 握手过程？
5. 证书的作用是什么？
6. DV、OV、EV 证书的区别？
7. 如何在 Nginx 中配置 HTTPS？
8. 什么是 HSTS？
9. 如何优化 HTTPS 性能？
10. Let's Encrypt 的优缺点？

## 学习建议

### 1. 理论结合实践

- 先理解 HTTPS 原理
- 再动手配置
- 遇到问题查日志

### 2. 从简单到复杂

- 先用自签名证书测试
- 再使用 Let's Encrypt
- 最后优化配置

### 3. 关注安全

- 使用强加密
- 定期更新证书
- 监控证书有效期
- 配置安全头

### 4. 性能优化

- 启用会话复用
- 启用 HTTP/2
- 启用 OCSP Stapling
- 使用 CDN

## 推荐资源

### 官方文档

- [Let's Encrypt 官网](https://letsencrypt.org/)
- [Certbot 文档](https://certbot.eff.org/docs/)
- [Mozilla SSL 配置生成器](https://ssl-config.mozilla.org/)

### 在线工具

- [SSL Labs 测试](https://www.ssllabs.com/ssltest/)
- [Security Headers 测试](https://securityheaders.com/)
- [SSL Checker](https://www.sslshopper.com/ssl-checker.html)

### 推荐阅读

- 《HTTPS 权威指南》
- 《图解密码技术》
- Mozilla SSL/TLS 最佳实践

## 下一步

完成 HTTPS 学习后，继续学习：
- **Rewrite 重写**：URL 重写规则
- **Nginx 性能优化**：深度调优

HTTPS 是现代网站的标配，也是 SEO 和用户信任的基础，务必熟练掌握！

加油！💪
