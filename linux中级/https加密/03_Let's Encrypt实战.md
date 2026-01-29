# Let's Encrypt 实战

## 什么是 Let's Encrypt？

Let's Encrypt 是一个免费、自动化、开放的证书颁发机构（CA），由非营利组织 Internet Security Research Group（ISRG）运营。

### Let's Encrypt 的特点

```
✅ 完全免费
✅ 自动化签发和续期
✅ 支持通配符证书
✅ 被所有主流浏览器信任
✅ 开源透明

⚠️ 限制
- 证书有效期 90 天
- 仅支持 DV（域名验证）证书
- 不支持 OV/EV 证书
```

---

## Certbot 工具

Certbot 是 Let's Encrypt 官方推荐的客户端工具。

### 安装 Certbot

#### CentOS/RHEL 7

```bash
# 安装 EPEL 仓库
yum install epel-release -y

# 安装 Certbot
yum install certbot python2-certbot-nginx -y
```

#### CentOS/RHEL 8

```bash
# 安装 Certbot
dnf install certbot python3-certbot-nginx -y
```

#### Ubuntu/Debian

```bash
# 更新包列表
apt update

# 安装 Certbot
apt install certbot python3-certbot-nginx -y
```

#### 使用 Snap（推荐）

```bash
# 安装 Snap
yum install snapd -y  # CentOS
apt install snapd -y  # Ubuntu

# 启动 Snap
systemctl enable --now snapd.socket
ln -s /var/lib/snapd/snap /snap

# 安装 Certbot
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
```

---

## 获取证书

### 方法1：自动配置（推荐）

Certbot 自动修改 Nginx 配置。

```bash
# 为域名获取证书并自动配置 Nginx
certbot --nginx -d example.com -d www.example.com

# 交互式过程
# 1. 输入邮箱
# 2. 同意服务条款
# 3. 选择是否重定向 HTTP 到 HTTPS（推荐选择 2）
```

### 方法2：仅获取证书

只获取证书，手动配置 Nginx。

```bash
# 使用 webroot 插件
certbot certonly --webroot \
  -w /data/www/example \
  -d example.com \
  -d www.example.com

# 使用 standalone 插件（需要停止 Nginx）
certbot certonly --standalone \
  -d example.com \
  -d www.example.com

# 使用 nginx 插件
certbot certonly --nginx \
  -d example.com \
  -d www.example.com
```

### 方法3：通配符证书

```bash
# 通配符证书需要 DNS 验证
certbot certonly --manual \
  --preferred-challenges dns \
  -d example.com \
  -d *.example.com

# 按提示添加 DNS TXT 记录
# _acme-challenge.example.com TXT "验证字符串"

# 验证 DNS 记录
dig -t txt _acme-challenge.example.com

# 确认后继续
```

---

## 证书文件位置

### 证书目录结构

```bash
/etc/letsencrypt/
├── live/
│   └── example.com/
│       ├── cert.pem          # 服务器证书
│       ├── chain.pem         # 证书链
│       ├── fullchain.pem     # 完整证书链（推荐使用）
│       └── privkey.pem       # 私钥
├── archive/
│   └── example.com/
│       ├── cert1.pem
│       ├── chain1.pem
│       ├── fullchain1.pem
│       └── privkey1.pem
└── renewal/
    └── example.com.conf      # 续期配置
```

### 证书文件说明

```bash
cert.pem        # 服务器证书（不包含中间证书）
chain.pem       # 中间证书链
fullchain.pem   # 完整证书链（cert.pem + chain.pem）
privkey.pem     # 私钥

# Nginx 配置使用
ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
```

---

## Nginx 配置

### 手动配置 HTTPS

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;
    
    # Let's Encrypt 证书
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers on;
    
    # SSL 会话缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 网站配置
    root /data/www/example;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    # Let's Encrypt 验证
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
    }
    
    # 重定向到 HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}
```

### 测试配置

```bash
# 测试 Nginx 配置
nginx -t

# 重新加载 Nginx
nginx -s reload

# 测试 HTTPS
curl -I https://example.com
```

---

## 证书续期

### 自动续期

Let's Encrypt 证书有效期 90 天，需要定期续期。

```bash
# 测试续期（不实际续期）
certbot renew --dry-run

# 手动续期
certbot renew

# 续期特定证书
certbot renew --cert-name example.com

# 强制续期
certbot renew --force-renewal
```

### 配置自动续期

#### 方法1：使用 Cron

```bash
# 编辑 crontab
crontab -e

# 添加定时任务（每天凌晨 2 点检查续期）
0 2 * * * certbot renew --quiet --post-hook "nginx -s reload"

# 或每周一凌晨 2 点
0 2 * * 1 certbot renew --quiet --post-hook "nginx -s reload"
```

#### 方法2：使用 Systemd Timer

```bash
# 查看 Certbot timer
systemctl list-timers | grep certbot

# 启用自动续期
systemctl enable certbot-renew.timer
systemctl start certbot-renew.timer

# 查看状态
systemctl status certbot-renew.timer
```

### 续期钩子

```bash
# 续期前执行
--pre-hook "command"

# 续期后执行
--post-hook "nginx -s reload"

# 续期成功后执行
--deploy-hook "command"

# 示例
certbot renew \
  --pre-hook "nginx -s stop" \
  --post-hook "nginx -s start" \
  --deploy-hook "echo 'Certificate renewed' | mail -s 'SSL Renewed' admin@example.com"
```

---

## 实战案例

### 案例1：单域名网站

```bash
# 1. 准备网站
mkdir -p /data/www/example
echo "<h1>Example Site</h1>" > /data/www/example/index.html

# 2. 配置 Nginx（HTTP）
cat > /etc/nginx/conf.d/example.conf << 'EOF'
server {
    listen 80;
    server_name example.com www.example.com;
    root /data/www/example;
    index index.html;
}
EOF

# 3. 测试并重载
nginx -t && nginx -s reload

# 4. 获取证书
certbot --nginx -d example.com -d www.example.com

# 5. 测试 HTTPS
curl -I https://example.com
```

### 案例2：多域名网站

```bash
# 为多个域名获取证书
certbot --nginx \
  -d example.com -d www.example.com \
  -d blog.example.com \
  -d api.example.com

# 或分别获取
certbot --nginx -d example.com -d www.example.com
certbot --nginx -d blog.example.com
certbot --nginx -d api.example.com
```

### 案例3：通配符证书

```bash
# 1. 获取通配符证书
certbot certonly --manual \
  --preferred-challenges dns \
  -d example.com \
  -d *.example.com

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

# 5. 测试
nginx -t && nginx -s reload
```

### 案例4：反向代理 HTTPS

```bash
# 1. 配置后端应用（运行在 8080 端口）

# 2. 配置 Nginx
cat > /etc/nginx/conf.d/api.conf << 'EOF'
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://localhost:8080;
    }
}
EOF

# 3. 获取证书
certbot --nginx -d api.example.com

# 4. Certbot 会自动配置 HTTPS 和反向代理
```

---

## 证书管理

### 查看证书

```bash
# 列出所有证书
certbot certificates

# 输出示例
Certificate Name: example.com
  Domains: example.com www.example.com
  Expiry Date: 2024-03-15 12:00:00+00:00 (VALID: 89 days)
  Certificate Path: /etc/letsencrypt/live/example.com/fullchain.pem
  Private Key Path: /etc/letsencrypt/live/example.com/privkey.pem
```

### 删除证书

```bash
# 删除证书
certbot delete --cert-name example.com

# 确认删除
```

### 撤销证书

```bash
# 撤销证书
certbot revoke --cert-path /etc/letsencrypt/live/example.com/cert.pem

# 撤销并删除
certbot revoke --cert-path /etc/letsencrypt/live/example.com/cert.pem --delete-after-revoke
```

### 更新证书域名

```bash
# 添加域名
certbot certonly --nginx \
  --cert-name example.com \
  -d example.com -d www.example.com -d blog.example.com

# 删除域名（重新签发，不包含要删除的域名）
certbot certonly --nginx \
  --cert-name example.com \
  -d example.com -d www.example.com
```

---

## DNS 验证（自动化）

### 使用 DNS 插件

#### Cloudflare

```bash
# 安装插件
pip install certbot-dns-cloudflare

# 创建 API Token 配置文件
cat > /root/.secrets/cloudflare.ini << EOF
dns_cloudflare_api_token = YOUR_API_TOKEN
EOF

chmod 600 /root/.secrets/cloudflare.ini

# 获取证书
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
  -d example.com \
  -d *.example.com
```

#### 阿里云

```bash
# 安装插件
pip install certbot-dns-aliyun

# 创建配置文件
cat > /root/.secrets/aliyun.ini << EOF
dns_aliyun_access_key = YOUR_ACCESS_KEY
dns_aliyun_access_key_secret = YOUR_SECRET_KEY
EOF

chmod 600 /root/.secrets/aliyun.ini

# 获取证书
certbot certonly \
  --dns-aliyun \
  --dns-aliyun-credentials /root/.secrets/aliyun.ini \
  -d example.com \
  -d *.example.com
```

---

## 故障排查

### 问题1：验证失败

```bash
# 原因
1. 域名未解析到服务器
2. 防火墙阻止 80 端口
3. Nginx 未运行
4. webroot 路径错误

# 排查
# 检查域名解析
dig example.com
nslookup example.com

# 检查端口
netstat -tuln | grep :80

# 检查防火墙
firewall-cmd --list-all

# 测试 HTTP 访问
curl http://example.com/.well-known/acme-challenge/test
```

### 问题2：续期失败

```bash
# 查看续期日志
cat /var/log/letsencrypt/letsencrypt.log

# 测试续期
certbot renew --dry-run

# 常见原因
1. 域名解析变更
2. Nginx 配置错误
3. 防火墙规则变更
4. webroot 路径变更
```

### 问题3：证书不被信任

```bash
# 原因
使用了 cert.pem 而不是 fullchain.pem

# 解决
# 使用完整证书链
ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
```

### 问题4：速率限制

```bash
# Let's Encrypt 速率限制
- 每个域名每周最多 50 个证书
- 每个账户每 3 小时最多 300 个待处理授权
- 每个 IP 每 3 小时最多 10 个账户

# 解决
- 使用 --dry-run 测试
- 避免频繁申请
- 使用通配符证书
```

---

## 最佳实践

### 1. 使用 webroot 插件

```bash
# 不需要停止 Nginx
certbot certonly --webroot \
  -w /data/www/example \
  -d example.com
```

### 2. 配置自动续期

```bash
# 使用 cron 或 systemd timer
0 2 * * * certbot renew --quiet --post-hook "nginx -s reload"
```

### 3. 监控证书过期

```bash
# 创建监控脚本
cat > /usr/local/bin/check-ssl-expiry.sh << 'EOF'
#!/bin/bash
DOMAIN="example.com"
DAYS=30

EXPIRY=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

if [ $DAYS_LEFT -lt $DAYS ]; then
    echo "SSL certificate for $DOMAIN expires in $DAYS_LEFT days!"
    # 发送告警邮件
fi
EOF

chmod +x /usr/local/bin/check-ssl-expiry.sh

# 添加到 cron
0 8 * * * /usr/local/bin/check-ssl-expiry.sh
```

### 4. 备份证书

```bash
# 定期备份证书
tar -czf letsencrypt-backup-$(date +%Y%m%d).tar.gz /etc/letsencrypt/

# 或使用 rsync
rsync -av /etc/letsencrypt/ backup-server:/backup/letsencrypt/
```

### 5. 使用 DNS 验证

```bash
# 对于无法通过 HTTP 验证的情况
# 使用 DNS 验证更可靠
certbot certonly --manual --preferred-challenges dns -d example.com
```

---

## 练习题

### 基础练习

1. 安装 Certbot
2. 为单个域名获取 Let's Encrypt 证书
3. 配置 Nginx 使用证书
4. 配置 HTTP 到 HTTPS 重定向
5. 测试证书续期

### 进阶练习

1. 为多个域名获取证书
2. 获取通配符证书
3. 配置自动续期
4. 配置续期钩子
5. 使用 DNS 插件自动验证
6. 监控证书过期时间

---

## 总结

Let's Encrypt 实战要点：
- ✅ 使用 Certbot 自动获取证书
- ✅ 配置 Nginx 使用证书
- ✅ 设置自动续期
- ✅ 使用 fullchain.pem
- ✅ 监控证书有效期
- ✅ 定期备份证书

---

## 参考资源

- [Let's Encrypt 官网](https://letsencrypt.org/)
- [Certbot 官网](https://certbot.eff.org/)
- [Let's Encrypt 文档](https://letsencrypt.org/docs/)
- [速率限制说明](https://letsencrypt.org/docs/rate-limits/)

Let's Encrypt 让 HTTPS 变得简单免费，是个人和小型网站的最佳选择！
