# 06 - Docker 私有仓库

## 📚 本节目标

- 理解 Docker Registry 原理
- 搭建 Docker Registry
- 部署 Harbor 企业级仓库
- 掌握镜像推送和拉取
- 配置仓库安全
- 实现镜像同步

---

## 1. Docker Registry 简介

### 1.1 什么是 Docker Registry

Docker Registry 是存储和分发 Docker 镜像的服务。

**公共仓库**：
- Docker Hub：官方公共仓库
- 阿里云容器镜像服务
- 腾讯云容器镜像服务

**私有仓库**：
- Docker Registry：官方开源仓库
- Harbor：企业级私有仓库
- Nexus：支持多种格式的仓库

### 1.2 为什么需要私有仓库

```
✅ 安全性：内网部署，数据不外泄
✅ 速度快：内网传输，下载快速
✅ 可控性：完全掌控镜像管理
✅ 节省成本：不受公共仓库限制
✅ 企业级功能：权限管理、审计日志
```

---

## 2. Docker Registry 搭建

### 2.1 快速部署

```bash
# 运行 Registry 容器
docker run -d \
    -p 5000:5000 \
    --name registry \
    --restart=always \
    registry:2

# 验证
curl http://localhost:5000/v2/
```

### 2.2 持久化存储

```bash
# 创建数据目录
mkdir -p /data/registry

# 运行 Registry（挂载数据卷）
docker run -d \
    -p 5000:5000 \
    --name registry \
    --restart=always \
    -v /data/registry:/var/lib/registry \
    registry:2
```

### 2.3 配置文件

**创建配置文件**：
```yaml
# config.yml
version: 0.1
log:
  level: info
  formatter: text
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

**使用配置文件**：
```bash
docker run -d \
    -p 5000:5000 \
    --name registry \
    --restart=always \
    -v /data/registry:/var/lib/registry \
    -v $(pwd)/config.yml:/etc/docker/registry/config.yml \
    registry:2
```

### 2.4 HTTPS 配置

**生成自签名证书**：
```bash
# 创建证书目录
mkdir -p /data/certs

# 生成证书
openssl req -newkey rsa:4096 -nodes -sha256 \
    -keyout /data/certs/domain.key \
    -x509 -days 365 \
    -out /data/certs/domain.crt \
    -subj "/CN=registry.example.com"
```

**运行 HTTPS Registry**：
```bash
docker run -d \
    -p 443:5000 \
    --name registry \
    --restart=always \
    -v /data/registry:/var/lib/registry \
    -v /data/certs:/certs \
    -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
    registry:2
```

### 2.5 基础认证

**创建密码文件**：
```bash
# 安装 htpasswd
yum install -y httpd-tools  # CentOS
apt-get install -y apache2-utils  # Ubuntu

# 创建认证目录
mkdir -p /data/auth

# 创建用户（admin/password）
htpasswd -Bbn admin password > /data/auth/htpasswd
```

**运行带认证的 Registry**：
```bash
docker run -d \
    -p 5000:5000 \
    --name registry \
    --restart=always \
    -v /data/registry:/var/lib/registry \
    -v /data/auth:/auth \
    -e "REGISTRY_AUTH=htpasswd" \
    -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
    -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
    registry:2
```

---

## 3. 使用私有仓库

### 3.1 推送镜像

```bash
# 1. 登录私有仓库
docker login localhost:5000
# 输入用户名和密码

# 2. 给镜像打标签
docker tag nginx:latest localhost:5000/nginx:latest

# 3. 推送镜像
docker push localhost:5000/nginx:latest

# 4. 查看推送的镜像
curl -u admin:password http://localhost:5000/v2/_catalog
```

### 3.2 拉取镜像

```bash
# 1. 登录私有仓库
docker login localhost:5000

# 2. 拉取镜像
docker pull localhost:5000/nginx:latest

# 3. 运行容器
docker run -d -p 80:80 localhost:5000/nginx:latest
```

### 3.3 配置非 HTTPS 仓库

**修改 Docker 配置**：
```bash
# 编辑 /etc/docker/daemon.json
{
  "insecure-registries": ["192.168.1.100:5000"]
}

# 重启 Docker
systemctl restart docker
```

### 3.4 查看仓库镜像

```bash
# 查看所有镜像
curl http://localhost:5000/v2/_catalog

# 查看镜像标签
curl http://localhost:5000/v2/nginx/tags/list

# 查看镜像详情
curl http://localhost:5000/v2/nginx/manifests/latest
```

### 3.5 删除镜像

```bash
# 1. 获取镜像 digest
curl -I -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    http://localhost:5000/v2/nginx/manifests/latest

# 2. 删除镜像
curl -X DELETE http://localhost:5000/v2/nginx/manifests/<digest>

# 3. 垃圾回收
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml
```

---

## 4. Harbor 企业级仓库

### 4.1 Harbor 简介

Harbor 是 VMware 开源的企业级 Docker Registry。

**核心功能**：
```
✅ 用户管理和 RBAC 权限控制
✅ 镜像复制（多仓库同步）
✅ 镜像扫描（漏洞扫描）
✅ 镜像签名（内容信任）
✅ 审计日志
✅ Web UI 管理界面
✅ RESTful API
✅ 镜像标签保留策略
```

### 4.2 Harbor 安装

**前置要求**：
- Docker 17.06+
- Docker Compose 1.18+
- 至少 2 核 CPU、4GB 内存

**下载 Harbor**：
```bash
# 下载离线安装包
wget https://github.com/goharbor/harbor/releases/download/v2.7.0/harbor-offline-installer-v2.7.0.tgz

# 解压
tar xzvf harbor-offline-installer-v2.7.0.tgz
cd harbor
```

**配置 Harbor**：
```bash
# 复制配置文件
cp harbor.yml.tmpl harbor.yml

# 编辑配置文件
vim harbor.yml
```

**harbor.yml 配置**：
```yaml
# 主机名
hostname: harbor.example.com

# HTTP 配置
http:
  port: 80

# HTTPS 配置（可选）
https:
  port: 443
  certificate: /data/cert/server.crt
  private_key: /data/cert/server.key

# Harbor 管理员密码
harbor_admin_password: Harbor12345

# 数据库配置
database:
  password: root123
  max_idle_conns: 50
  max_open_conns: 1000

# 数据存储路径
data_volume: /data

# 日志配置
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
```

**安装 Harbor**：
```bash
# 运行安装脚本
./install.sh

# 带镜像扫描功能
./install.sh --with-trivy

# 带镜像签名功能
./install.sh --with-notary
```

**访问 Harbor**：
```
URL: http://harbor.example.com
用户名: admin
密码: Harbor12345
```

### 4.3 Harbor 管理

**启动和停止**：
```bash
# 启动
docker-compose up -d

# 停止
docker-compose stop

# 重启
docker-compose restart

# 查看状态
docker-compose ps
```

**查看日志**：
```bash
# 查看所有日志
docker-compose logs

# 查看特定服务日志
docker-compose logs harbor-core
docker-compose logs harbor-jobservice
```

**备份和恢复**：
```bash
# 备份数据
tar -czf harbor-backup.tar.gz /data

# 恢复数据
tar -xzf harbor-backup.tar.gz -C /
```

### 4.4 Harbor 使用

**创建项目**：
1. 登录 Harbor Web UI
2. 点击"新建项目"
3. 输入项目名称（如 myproject）
4. 选择访问级别（公开/私有）
5. 点击"确定"

**推送镜像到 Harbor**：
```bash
# 1. 登录 Harbor
docker login harbor.example.com
# 输入用户名和密码

# 2. 给镜像打标签
docker tag nginx:latest harbor.example.com/myproject/nginx:latest

# 3. 推送镜像
docker push harbor.example.com/myproject/nginx:latest
```

**从 Harbor 拉取镜像**：
```bash
# 1. 登录 Harbor
docker login harbor.example.com

# 2. 拉取镜像
docker pull harbor.example.com/myproject/nginx:latest
```

**用户和权限管理**：
```
项目管理员：完全控制项目
开发者：推送和拉取镜像
访客：只能拉取镜像
受限访客：只能拉取公开镜像
```

### 4.5 镜像复制

**配置复制规则**：
1. 登录 Harbor
2. 进入"系统管理" → "仓库管理"
3. 点击"新建目标"
4. 输入目标仓库信息
5. 创建复制规则

**复制规则示例**：
```yaml
名称: sync-to-backup
源仓库: myproject/*
目标仓库: backup-harbor
触发模式: 手动/定时/事件驱动
```

### 4.6 镜像扫描

**启用镜像扫描**：
```bash
# 安装时启用 Trivy
./install.sh --with-trivy
```

**扫描镜像**：
1. 进入项目
2. 选择镜像
3. 点击"扫描"
4. 查看扫描结果

**自动扫描**：
- 推送时自动扫描
- 定时扫描
- 手动扫描

---

## 5. 镜像同步

### 5.1 使用 skopeo 同步

**安装 skopeo**：
```bash
# CentOS
yum install -y skopeo

# Ubuntu
apt-get install -y skopeo
```

**同步镜像**：
```bash
# 从 Docker Hub 同步到私有仓库
skopeo copy \
    docker://docker.io/nginx:latest \
    docker://harbor.example.com/myproject/nginx:latest \
    --dest-creds admin:Harbor12345

# 从一个私有仓库同步到另一个
skopeo copy \
    docker://registry1.example.com/nginx:latest \
    docker://registry2.example.com/nginx:latest
```

### 5.2 批量同步脚本

```bash
#!/bin/bash
# sync-images.sh

SOURCE_REGISTRY="docker.io"
TARGET_REGISTRY="harbor.example.com/library"
TARGET_USER="admin"
TARGET_PASS="Harbor12345"

IMAGES=(
    "nginx:latest"
    "redis:latest"
    "mysql:8.0"
    "postgres:14"
)

for image in "${IMAGES[@]}"; do
    echo "Syncing $image..."
    skopeo copy \
        docker://${SOURCE_REGISTRY}/${image} \
        docker://${TARGET_REGISTRY}/${image} \
        --dest-creds ${TARGET_USER}:${TARGET_PASS}
done

echo "Sync completed!"
```

---

## 6. 实战案例

### 案例1：企业私有仓库部署

```bash
# 1. 部署 Harbor
cd /opt
wget https://github.com/goharbor/harbor/releases/download/v2.7.0/harbor-offline-installer-v2.7.0.tgz
tar xzvf harbor-offline-installer-v2.7.0.tgz
cd harbor

# 2. 配置 Harbor
cp harbor.yml.tmpl harbor.yml
vim harbor.yml
# 修改 hostname、密码等

# 3. 安装
./install.sh --with-trivy

# 4. 配置 DNS 或 hosts
echo "192.168.1.100 harbor.example.com" >> /etc/hosts

# 5. 访问 Harbor
# http://harbor.example.com
```

### 案例2：CI/CD 集成

**GitLab CI 配置**：
```yaml
# .gitlab-ci.yml
stages:
  - build
  - push

variables:
  HARBOR_URL: harbor.example.com
  HARBOR_PROJECT: myproject
  IMAGE_NAME: myapp
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA

build:
  stage: build
  script:
    - docker build -t $IMAGE_NAME:$IMAGE_TAG .

push:
  stage: push
  script:
    - docker login -u $HARBOR_USER -p $HARBOR_PASS $HARBOR_URL
    - docker tag $IMAGE_NAME:$IMAGE_TAG $HARBOR_URL/$HARBOR_PROJECT/$IMAGE_NAME:$IMAGE_TAG
    - docker push $HARBOR_URL/$HARBOR_PROJECT/$IMAGE_NAME:$IMAGE_TAG
```

### 案例3：多环境镜像管理

```
开发环境：harbor.dev.example.com
测试环境：harbor.test.example.com
生产环境：harbor.prod.example.com

镜像命名规范：
harbor.example.com/project/app:version-env
harbor.example.com/myproject/webapp:1.0.0-dev
harbor.example.com/myproject/webapp:1.0.0-test
harbor.example.com/myproject/webapp:1.0.0-prod
```

---

## 7. 安全最佳实践

### 7.1 访问控制

```
✅ 启用 HTTPS
✅ 使用强密码
✅ 配置 RBAC 权限
✅ 定期审计日志
✅ 限制网络访问
```

### 7.2 镜像安全

```
✅ 启用镜像扫描
✅ 使用镜像签名
✅ 定期更新基础镜像
✅ 删除不必要的镜像
✅ 配置镜像保留策略
```

### 7.3 备份策略

```bash
# 定期备份脚本
#!/bin/bash
BACKUP_DIR="/backup/harbor"
DATE=$(date +%Y%m%d)

# 停止 Harbor
cd /opt/harbor
docker-compose stop

# 备份数据
tar -czf $BACKUP_DIR/harbor-$DATE.tar.gz /data

# 启动 Harbor
docker-compose start

# 删除 7 天前的备份
find $BACKUP_DIR -name "harbor-*.tar.gz" -mtime +7 -delete
```

---

## 8. 练习题

### 练习1：搭建 Registry
搭建一个带 HTTPS 和认证的 Docker Registry。

### 练习2：部署 Harbor
部署 Harbor 企业级仓库，创建项目并推送镜像。

### 练习3：镜像同步
配置 Harbor 镜像复制，实现多仓库同步。

### 练习4：CI/CD 集成
将 Harbor 集成到 CI/CD 流水线中。

---

## 📝 本节总结

### 核心要点

1. **Docker Registry**：官方开源仓库
2. **Harbor**：企业级私有仓库
3. **镜像管理**：推送、拉取、删除
4. **安全配置**：HTTPS、认证、权限
5. **镜像同步**：多仓库复制

### 最佳实践

```
✅ 使用 Harbor 企业级仓库
✅ 启用 HTTPS 和认证
✅ 配置 RBAC 权限控制
✅ 启用镜像扫描
✅ 定期备份数据
✅ 配置镜像保留策略
✅ 监控仓库状态
```

### 下一步

学习完私有仓库后，继续学习：
- Docker 实战应用
- 容器监控和日志
- Kubernetes 容器编排

---

**掌握私有仓库，构建企业级镜像管理平台！** 🚀
