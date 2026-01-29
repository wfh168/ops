# GitLab 安装与配置

## 一、GitLab 简介

### 1.1 什么是 GitLab

GitLab 是一个基于 Git 的完整 DevOps 平台，提供代码托管、CI/CD、项目管理等功能。

**核心功能**：
- 代码仓库管理
- 分支和合并请求
- CI/CD Pipeline
- Issue 跟踪
- Wiki 文档
- 容器镜像仓库
- 安全扫描

**版本对比**：

| 版本 | 说明 | 适用场景 |
|------|------|----------|
| **GitLab CE** | 社区版，免费 | 中小团队 ⭐ |
| **GitLab EE** | 企业版，付费 | 大型企业 |
| **GitLab.com** | SaaS 服务 | 快速开始 |

### 1.2 GitLab 架构

```
                    GitLab 架构
                        |
        +---------------+---------------+
        |               |               |
    [Nginx]         [GitLab]        [PostgreSQL]
    (Web服务器)      (核心服务)       (数据库)
        |               |               |
        +-------+-------+-------+-------+
                |               |
            [Redis]         [Sidekiq]
            (缓存)          (后台任务)
                |
            [Gitaly]
            (Git存储)
```

**组件说明**：
- **Nginx**：Web 服务器和反向代理
- **GitLab Workhorse**：处理大文件上传
- **GitLab Shell**：处理 Git SSH 请求
- **PostgreSQL**：主数据库
- **Redis**：缓存和队列
- **Sidekiq**：后台任务处理
- **Gitaly**：Git 仓库存储服务

---

## 二、系统要求

### 2.1 硬件要求

**最小配置**（100 用户以下）：
- CPU：2核
- 内存：4GB
- 硬盘：50GB

**推荐配置**（500 用户）：
- CPU：4核
- 内存：8GB
- 硬盘：100GB SSD

**大型部署**（1000+ 用户）：
- CPU：8核+
- 内存：16GB+
- 硬盘：500GB+ SSD

### 2.2 软件要求

- 操作系统：CentOS 7/8、Ubuntu 18.04/20.04
- Ruby：2.7+
- Go：1.17+
- Git：2.33+
- Node.js：14.x
- PostgreSQL：12+
- Redis：6.0+

---

## 三、安装 GitLab

### 3.1 使用官方包安装（推荐）

#### CentOS/RHEL

```bash
# 1. 安装依赖
sudo yum install -y curl policycoreutils-python openssh-server perl

# 2. 启动 SSH 服务
sudo systemctl enable sshd
sudo systemctl start sshd

# 3. 配置防火墙
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo systemctl reload firewalld

# 4. 添加 GitLab 仓库
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash

# 5. 安装 GitLab
sudo EXTERNAL_URL="http://gitlab.example.com" yum install -y gitlab-ce

# 6. 配置并启动
sudo gitlab-ctl reconfigure
```

#### Ubuntu/Debian

```bash
# 1. 安装依赖
sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl

# 2. 添加 GitLab 仓库
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

# 3. 安装 GitLab
sudo EXTERNAL_URL="http://gitlab.example.com" apt-get install gitlab-ce

# 4. 配置并启动
sudo gitlab-ctl reconfigure
```

### 3.2 使用 Docker 安装

```bash
# 1. 创建数据目录
sudo mkdir -p /srv/gitlab/{config,logs,data}

# 2. 运行 GitLab 容器
sudo docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume /srv/gitlab/config:/etc/gitlab \
  --volume /srv/gitlab/logs:/var/log/gitlab \
  --volume /srv/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest

# 3. 查看日志
sudo docker logs -f gitlab
```

### 3.3 验证安装

```bash
# 检查服务状态
sudo gitlab-ctl status

# 输出示例：
# run: gitaly: (pid 1234) 123s; run: log: (pid 5678) 123s
# run: gitlab-workhorse: (pid 1235) 123s; run: log: (pid 5679) 123s
# run: logrotate: (pid 1236) 123s; run: log: (pid 5680) 123s
# run: nginx: (pid 1237) 123s; run: log: (pid 5681) 123s
# run: postgresql: (pid 1238) 123s; run: log: (pid 5682) 123s
# run: redis: (pid 1239) 123s; run: log: (pid 5683) 123s
# run: sidekiq: (pid 1240) 123s; run: log: (pid 5684) 123s

# 访问 GitLab
# 浏览器打开：http://gitlab.example.com
```

---

## 四、基础配置

### 4.1 配置文件

GitLab 的主配置文件：`/etc/gitlab/gitlab.rb`

```bash
# 编辑配置文件
sudo vim /etc/gitlab/gitlab.rb
```

### 4.2 配置外部 URL

```ruby
# 修改外部访问 URL
external_url 'http://gitlab.example.com'

# 或使用 IP 地址
external_url 'http://192.168.1.100'
```

### 4.3 配置时区

```ruby
# 设置时区
gitlab_rails['time_zone'] = 'Asia/Shanghai'
```

### 4.4 配置数据存储路径

```ruby
# Git 数据存储路径
git_data_dirs({
  "default" => {
    "path" => "/var/opt/gitlab/git-data"
  }
})

# 备份路径
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
```

### 4.5 应用配置

```bash
# 重新配置 GitLab
sudo gitlab-ctl reconfigure

# 重启服务
sudo gitlab-ctl restart
```

---

## 五、HTTPS 配置

### 5.1 使用 Let's Encrypt（推荐）

```ruby
# 编辑配置文件
sudo vim /etc/gitlab/gitlab.rb

# 配置 HTTPS
external_url 'https://gitlab.example.com'

# 启用 Let's Encrypt
letsencrypt['enable'] = true
letsencrypt['contact_emails'] = ['admin@example.com']
letsencrypt['auto_renew'] = true
```

```bash
# 应用配置
sudo gitlab-ctl reconfigure
```

### 5.2 使用自签名证书

```bash
# 1. 创建证书目录
sudo mkdir -p /etc/gitlab/ssl
sudo chmod 755 /etc/gitlab/ssl

# 2. 生成自签名证书
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/gitlab/ssl/gitlab.example.com.key \
  -out /etc/gitlab/ssl/gitlab.example.com.crt

# 3. 配置 GitLab
sudo vim /etc/gitlab/gitlab.rb
```

```ruby
external_url 'https://gitlab.example.com'

nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.example.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.example.com.key"
```

```bash
# 应用配置
sudo gitlab-ctl reconfigure
```

### 5.3 使用已有证书

```bash
# 复制证书文件
sudo cp your-cert.crt /etc/gitlab/ssl/gitlab.example.com.crt
sudo cp your-key.key /etc/gitlab/ssl/gitlab.example.com.key
sudo chmod 600 /etc/gitlab/ssl/*
```

---

## 六、邮件配置

### 6.1 使用 SMTP

```ruby
# 编辑配置文件
sudo vim /etc/gitlab/gitlab.rb

# SMTP 配置
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.example.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "gitlab@example.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true

# 发件人信息
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_email_display_name'] = 'GitLab'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
```

### 6.2 使用 Gmail

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "your-email@gmail.com"
gitlab_rails['smtp_password'] = "your-app-password"
gitlab_rails['smtp_domain'] = "smtp.gmail.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab_rails['gitlab_email_from'] = 'your-email@gmail.com'
```

### 6.3 测试邮件

```bash
# 应用配置
sudo gitlab-ctl reconfigure

# 进入 Rails 控制台
sudo gitlab-rails console

# 发送测试邮件
Notify.test_email('test@example.com', 'Test Subject', 'Test Body').deliver_now

# 退出控制台
exit
```

---

## 七、初始化设置

### 7.1 首次登录

1. 访问 GitLab：`http://gitlab.example.com`
2. 首次访问会要求设置 root 密码
3. 设置密码后使用 root 账号登录

### 7.2 获取初始密码

```bash
# 查看初始 root 密码
sudo cat /etc/gitlab/initial_root_password

# 注意：此文件在首次配置后 24 小时会自动删除
```

### 7.3 修改 root 密码

```bash
# 方法1：通过 Web 界面
# 登录后：User Settings → Password

# 方法2：通过命令行
sudo gitlab-rails console

# 在控制台中执行
user = User.find_by(username: 'root')
user.password = 'new_password'
user.password_confirmation = 'new_password'
user.save!
exit
```

---

## 八、常用管理命令

### 8.1 服务管理

```bash
# 查看所有服务状态
sudo gitlab-ctl status

# 启动所有服务
sudo gitlab-ctl start

# 停止所有服务
sudo gitlab-ctl stop

# 重启所有服务
sudo gitlab-ctl restart

# 重新配置
sudo gitlab-ctl reconfigure

# 查看日志
sudo gitlab-ctl tail

# 查看特定服务日志
sudo gitlab-ctl tail nginx
sudo gitlab-ctl tail postgresql
```

### 8.2 备份和恢复

```bash
# 创建备份
sudo gitlab-backup create

# 备份文件位置
ls -lh /var/opt/gitlab/backups/

# 恢复备份
sudo gitlab-backup restore BACKUP=1640000000_2024_01_29_15.8.0

# 恢复后重新配置
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

### 8.3 检查和修复

```bash
# 检查 GitLab 配置
sudo gitlab-rake gitlab:check

# 检查环境
sudo gitlab-rake gitlab:env:info

# 清理缓存
sudo gitlab-rake cache:clear
```

---

## 九、性能优化

### 9.1 调整 Unicorn/Puma 工作进程

```ruby
# 编辑配置文件
sudo vim /etc/gitlab/gitlab.rb

# Puma 配置（GitLab 13.0+）
puma['worker_processes'] = 4
puma['min_threads'] = 4
puma['max_threads'] = 4

# 或 Unicorn 配置（旧版本）
unicorn['worker_processes'] = 4
unicorn['worker_timeout'] = 60
```

### 9.2 调整 PostgreSQL

```ruby
# PostgreSQL 配置
postgresql['shared_buffers'] = "256MB"
postgresql['max_connections'] = 200
postgresql['work_mem'] = "16MB"
```

### 9.3 调整 Sidekiq

```ruby
# Sidekiq 并发数
sidekiq['concurrency'] = 25
```

### 9.4 应用优化配置

```bash
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

---

## 十、故障排查

### 10.1 常见问题

#### 问题1：502 错误

```bash
# 检查服务状态
sudo gitlab-ctl status

# 查看日志
sudo gitlab-ctl tail nginx
sudo gitlab-ctl tail unicorn

# 重启服务
sudo gitlab-ctl restart
```

#### 问题2：内存不足

```bash
# 检查内存使用
free -h

# 减少工作进程
sudo vim /etc/gitlab/gitlab.rb
# 设置：puma['worker_processes'] = 2

sudo gitlab-ctl reconfigure
```

#### 问题3：磁盘空间不足

```bash
# 检查磁盘使用
df -h

# 清理旧备份
sudo find /var/opt/gitlab/backups -type f -mtime +7 -delete

# 清理 Docker 镜像（如果使用 Container Registry）
sudo gitlab-ctl registry-garbage-collect
```

### 10.2 日志位置

```bash
# 主要日志文件
/var/log/gitlab/nginx/
/var/log/gitlab/gitlab-rails/
/var/log/gitlab/postgresql/
/var/log/gitlab/redis/
/var/log/gitlab/sidekiq/
```

---

## 十一、实战练习

### 练习1：安装 GitLab

1. 准备一台服务器（4GB 内存）
2. 安装 GitLab CE
3. 配置 HTTPS
4. 配置邮件服务
5. 创建第一个项目

### 练习2：配置优化

1. 调整工作进程数
2. 配置备份策略
3. 设置自动备份
4. 测试恢复流程

### 练习3：故障排查

1. 模拟 502 错误
2. 查看日志定位问题
3. 解决问题并恢复服务

---

## 十二、总结

本节学习了：

✅ GitLab 架构和组件  
✅ GitLab 安装方法  
✅ 基础配置  
✅ HTTPS 配置  
✅ 邮件配置  
✅ 常用管理命令  
✅ 性能优化  
✅ 故障排查  

**下一节**：学习用户和权限管理。

---

## 参考资料

- [GitLab 官方文档](https://docs.gitlab.com/)
- [GitLab 安装指南](https://about.gitlab.com/install/)
- [GitLab 配置参考](https://docs.gitlab.com/omnibus/settings/)
