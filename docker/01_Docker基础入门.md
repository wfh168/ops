# 01 - Docker 基础入门

## 📚 本节目标

- 理解 Docker 和容器技术
- 掌握 Docker 安装配置
- 了解 Docker 架构
- 掌握基础命令
- 理解镜像和容器概念

---

## 1. Docker 简介

### 1.1 什么是 Docker

Docker 是一个开源的容器化平台，可以将应用及其依赖打包到一个轻量级、可移植的容器中。

**核心概念**：
```
应用 + 依赖 + 配置 = Docker 镜像
Docker 镜像 → 运行 → Docker 容器
```

### 1.2 容器 vs 虚拟机

| 特性 | 容器 | 虚拟机 |
|------|------|--------|
| 启动速度 | 秒级 | 分钟级 |
| 资源占用 | MB 级 | GB 级 |
| 性能 | 接近原生 | 有损耗 |
| 隔离性 | 进程级 | 系统级 |
| 可移植性 | 强 | 一般 |

**架构对比**：
```
虚拟机架构：
┌─────────────────────────────────┐
│  App A  │  App B  │  App C      │
├─────────┼─────────┼─────────────┤
│  Bins/Libs │ Bins/Libs │ Bins/Libs│
├─────────┼─────────┼─────────────┤
│ Guest OS│ Guest OS│ Guest OS    │
├─────────┴─────────┴─────────────┤
│        Hypervisor               │
├─────────────────────────────────┤
│        Host OS                  │
├─────────────────────────────────┤
│        Infrastructure           │
└─────────────────────────────────┘

容器架构：
┌─────────────────────────────────┐
│  App A  │  App B  │  App C      │
├─────────┼─────────┼─────────────┤
│  Bins/Libs │ Bins/Libs │ Bins/Libs│
├─────────┴─────────┴─────────────┤
│        Docker Engine            │
├─────────────────────────────────┤
│        Host OS                  │
├─────────────────────────────────┤
│        Infrastructure           │
└─────────────────────────────────┘
```

### 1.3 Docker 的优势

```
✅ 快速部署：秒级启动
✅ 环境一致：开发、测试、生产环境完全一致
✅ 资源高效：共享主机内核，占用资源少
✅ 易于迁移：一次构建，到处运行
✅ 版本管理：镜像版本控制
✅ 微服务：天然支持微服务架构
```

---

## 2. Docker 架构

### 2.1 核心组件

```
┌──────────────────────────────────────┐
│         Docker Client                │
│    (docker命令行工具)                 │
└──────────────┬───────────────────────┘
               │ REST API
┌──────────────↓───────────────────────┐
│         Docker Daemon                │
│    (dockerd 守护进程)                 │
│  ┌────────────────────────────────┐  │
│  │  Images (镜像)                  │  │
│  ├────────────────────────────────┤  │
│  │  Containers (容器)              │  │
│  ├────────────────────────────────┤  │
│  │  Networks (网络)                │  │
│  ├────────────────────────────────┤  │
│  │  Volumes (数据卷)               │  │
│  └────────────────────────────────┘  │
└──────────────┬───────────────────────┘
               │
┌──────────────↓───────────────────────┐
│         Docker Registry              │
│    (镜像仓库，如 Docker Hub)          │
└──────────────────────────────────────┘
```

**组件说明**：
- **Docker Client**：用户与 Docker 交互的接口
- **Docker Daemon**：Docker 守护进程，管理容器
- **Docker Registry**：存储和分发镜像的仓库
- **Images**：只读模板，用于创建容器
- **Containers**：镜像的运行实例

### 2.2 工作流程

```
1. 用户执行 docker run 命令
2. Docker Client 发送请求到 Docker Daemon
3. Docker Daemon 检查本地是否有镜像
4. 如果没有，从 Registry 拉取镜像
5. Docker Daemon 创建容器
6. 分配文件系统和网络
7. 启动容器进程
8. 返回容器 ID
```

---

## 3. Docker 安装

### 3.1 CentOS 安装

```bash
# 1. 卸载旧版本
sudo yum remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine

# 2. 安装依赖
sudo yum install -y yum-utils \
    device-mapper-persistent-data \
    lvm2

# 3. 添加 Docker 仓库
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# 或使用阿里云镜像（国内推荐）
sudo yum-config-manager \
    --add-repo \
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 4. 安装 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# 5. 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 6. 验证安装
docker --version
sudo docker run hello-world
```

### 3.2 Ubuntu 安装

```bash
# 1. 更新软件包
sudo apt-get update

# 2. 安装依赖
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. 添加 Docker GPG 密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 4. 添加 Docker 仓库
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 6. 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 7. 验证安装
docker --version
sudo docker run hello-world
```

### 3.3 配置 Docker

**配置镜像加速器（国内推荐）**：
```bash
# 创建配置目录
sudo mkdir -p /etc/docker

# 配置镜像加速器
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker-0.unsee.tech",
    "https://docker.m.daocloud.io",
    "https://xuanyuan.cloud"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 验证配置
docker info
```

**添加用户到 docker 组**：
```bash
# 添加当前用户到 docker 组
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker

# 验证（无需 sudo）
docker ps
```

---

## 4. Docker 基础命令

### 4.1 镜像命令

```bash
# 搜索镜像
docker search nginx

# 拉取镜像
docker pull nginx
docker pull nginx:1.21  # 指定版本

# 查看本地镜像
docker images
docker image ls

# 删除镜像
docker rmi nginx
docker rmi nginx:1.21

# 查看镜像详细信息
docker inspect nginx

# 查看镜像历史
docker history nginx
```

### 4.2 容器命令

```bash
# 运行容器
docker run nginx
docker run -d nginx  # 后台运行
docker run -d --name mynginx nginx  # 指定名称
docker run -d -p 80:80 nginx  # 端口映射

# 查看运行中的容器
docker ps

# 查看所有容器（包括停止的）
docker ps -a

# 停止容器
docker stop mynginx
docker stop <container_id>

# 启动容器
docker start mynginx

# 重启容器
docker restart mynginx

# 删除容器
docker rm mynginx
docker rm -f mynginx  # 强制删除运行中的容器

# 查看容器日志
docker logs mynginx
docker logs -f mynginx  # 实时查看

# 进入容器
docker exec -it mynginx bash
docker exec -it mynginx sh

# 查看容器详细信息
docker inspect mynginx

# 查看容器资源使用
docker stats mynginx
```

### 4.3 系统命令

```bash
# 查看 Docker 信息
docker info

# 查看 Docker 版本
docker version

# 查看磁盘使用
docker system df

# 清理未使用的资源
docker system prune  # 清理停止的容器、未使用的网络等
docker system prune -a  # 清理所有未使用的镜像

# 查看 Docker 事件
docker events
```

---

## 5. 第一个容器

### 5.1 运行 Nginx 容器

```bash
# 1. 拉取 Nginx 镜像
docker pull nginx

# 2. 运行 Nginx 容器
docker run -d \
    --name mynginx \
    -p 8080:80 \
    nginx

# 3. 查看容器
docker ps

# 4. 访问 Nginx
curl http://localhost:8080

# 5. 查看日志
docker logs mynginx

# 6. 进入容器
docker exec -it mynginx bash

# 7. 在容器内查看 Nginx 配置
cat /etc/nginx/nginx.conf

# 8. 退出容器
exit

# 9. 停止容器
docker stop mynginx

# 10. 删除容器
docker rm mynginx
```

### 5.2 运行 MySQL 容器

```bash
# 运行 MySQL 容器
docker run -d \
    --name mysql \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=123456 \
    mysql:8.0

# 查看容器
docker ps

# 进入 MySQL 容器
docker exec -it mysql bash

# 连接 MySQL
mysql -u root -p123456

# 创建数据库
CREATE DATABASE testdb;
SHOW DATABASES;

# 退出
exit
exit

# 从主机连接 MySQL
mysql -h 127.0.0.1 -P 3306 -u root -p123456
```

### 5.3 运行 Redis 容器

```bash
# 运行 Redis 容器
docker run -d \
    --name redis \
    -p 6379:6379 \
    redis

# 进入 Redis 容器
docker exec -it redis redis-cli

# 测试 Redis
SET name "Docker"
GET name

# 退出
exit

# 从主机连接 Redis
redis-cli -h 127.0.0.1 -p 6379
```

---

## 6. 容器生命周期

### 6.1 容器状态

```
Created（已创建）
    ↓
Running（运行中）
    ↓
Paused（暂停）
    ↓
Stopped（停止）
    ↓
Deleted（删除）
```

### 6.2 状态转换命令

```bash
# 创建容器（不启动）
docker create --name mynginx nginx

# 启动容器
docker start mynginx

# 暂停容器
docker pause mynginx

# 恢复容器
docker unpause mynginx

# 停止容器
docker stop mynginx

# 杀死容器
docker kill mynginx

# 重启容器
docker restart mynginx

# 删除容器
docker rm mynginx
```

### 6.3 容器自动重启

```bash
# 总是重启
docker run -d --restart=always nginx

# 失败时重启
docker run -d --restart=on-failure nginx

# 失败时重启（最多3次）
docker run -d --restart=on-failure:3 nginx

# 除非手动停止，否则重启
docker run -d --restart=unless-stopped nginx
```

---

## 7. 实战案例

### 案例1：部署静态网站

```bash
# 1. 创建网站目录
mkdir -p ~/mywebsite
cd ~/mywebsite

# 2. 创建 index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>My Docker Website</title>
</head>
<body>
    <h1>Hello Docker!</h1>
    <p>This is my first Docker website.</p>
</body>
</html>
EOF

# 3. 运行 Nginx 容器，挂载网站目录
docker run -d \
    --name mywebsite \
    -p 8080:80 \
    -v ~/mywebsite:/usr/share/nginx/html:ro \
    nginx

# 4. 访问网站
curl http://localhost:8080

# 5. 修改网站内容
echo "<h2>Updated!</h2>" >> ~/mywebsite/index.html

# 6. 刷新浏览器查看变化
```

### 案例2：运行 WordPress

```bash
# 1. 运行 MySQL
docker run -d \
    --name wordpress-mysql \
    -e MYSQL_ROOT_PASSWORD=rootpass \
    -e MYSQL_DATABASE=wordpress \
    -e MYSQL_USER=wpuser \
    -e MYSQL_PASSWORD=wppass \
    mysql:5.7

# 2. 运行 WordPress
docker run -d \
    --name wordpress \
    -p 8080:80 \
    --link wordpress-mysql:mysql \
    -e WORDPRESS_DB_HOST=mysql \
    -e WORDPRESS_DB_USER=wpuser \
    -e WORDPRESS_DB_PASSWORD=wppass \
    -e WORDPRESS_DB_NAME=wordpress \
    wordpress

# 3. 访问 WordPress
# 浏览器打开 http://localhost:8080
```

### 案例3：多容器应用

```bash
# 1. 创建网络
docker network create myapp

# 2. 运行 Redis
docker run -d \
    --name redis \
    --network myapp \
    redis

# 3. 运行应用容器
docker run -d \
    --name webapp \
    --network myapp \
    -p 8080:80 \
    -e REDIS_HOST=redis \
    myapp:latest

# 4. 查看网络
docker network inspect myapp
```

---

## 8. 常见问题

### 问题1：权限不足

```bash
# 错误：permission denied
# 解决：添加用户到 docker 组
sudo usermod -aG docker $USER
newgrp docker
```

### 问题2：端口被占用

```bash
# 错误：port is already allocated
# 解决：更换端口或停止占用端口的进程
docker run -d -p 8081:80 nginx  # 使用其他端口
```

### 问题3：镜像拉取失败

```bash
# 错误：timeout
# 解决：配置镜像加速器
sudo vim /etc/docker/daemon.json
# 添加镜像加速器配置
sudo systemctl restart docker
```

### 问题4：容器无法启动

```bash
# 查看容器日志
docker logs <container_name>

# 查看容器详细信息
docker inspect <container_name>

# 查看 Docker 事件
docker events
```

---

## 9. 练习题

### 练习1：基础操作
1. 安装 Docker
2. 拉取 nginx 镜像
3. 运行 nginx 容器并映射端口
4. 访问 nginx 首页

### 练习2：容器管理
1. 运行 3 个不同的容器（nginx、mysql、redis）
2. 查看所有运行中的容器
3. 停止所有容器
4. 删除所有容器

### 练习3：实战应用
1. 部署一个静态网站
2. 使用数据卷持久化数据
3. 配置容器自动重启
4. 查看容器日志和资源使用

---

## 📝 本节总结

### 核心要点

1. **Docker 概念**：容器化平台，轻量级虚拟化
2. **Docker 架构**：Client、Daemon、Registry
3. **基础命令**：镜像操作、容器操作、系统命令
4. **容器生命周期**：创建、运行、停止、删除
5. **实战应用**：Nginx、MySQL、WordPress

### 最佳实践

```
✅ 使用镜像加速器
✅ 为容器指定名称
✅ 使用数据卷持久化数据
✅ 配置容器自动重启
✅ 定期清理未使用的资源
✅ 查看容器日志排查问题
```

### 下一步

学习完 Docker 基础后，继续学习：
- Docker 镜像管理和 Dockerfile
- Docker 网络和数据卷
- Docker Compose 多容器编排

---

**掌握 Docker 基础，开启容器化之旅！** 🚀
