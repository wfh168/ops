# 02 - Dockerfile 镜像构建

## 📚 本节目标

- 理解镜像分层原理
- 掌握 Dockerfile 语法
- 学会编写 Dockerfile
- 掌握镜像构建优化
- 了解多阶段构建

---

## 1. 镜像原理

### 1.1 镜像分层

Docker 镜像由多个只读层组成，每一层代表 Dockerfile 中的一条指令。

```
┌─────────────────────────────┐
│  Container Layer (可写层)    │  ← 容器运行时的修改
├─────────────────────────────┤
│  Image Layer 3              │  ← RUN apt-get install
├─────────────────────────────┤
│  Image Layer 2              │  ← COPY app.py /app/
├─────────────────────────────┤
│  Image Layer 1              │  ← FROM python:3.9
└─────────────────────────────┘
```

**优点**：
- 共享层：多个镜像可以共享相同的基础层
- 快速构建：只需构建变化的层
- 节省空间：相同的层只存储一次

### 1.2 Union FS（联合文件系统）

```bash
# 查看镜像层
docker history nginx

# 查看镜像详细信息
docker inspect nginx
```

---

## 2. Dockerfile 基础

### 2.1 Dockerfile 结构

```dockerfile
# 基础镜像
FROM ubuntu:20.04

# 维护者信息
LABEL maintainer="your@email.com"

# 设置环境变量
ENV APP_HOME=/app

# 设置工作目录
WORKDIR $APP_HOME

# 复制文件
COPY requirements.txt .

# 执行命令
RUN apt-get update && \
    apt-get install -y python3

# 暴露端口
EXPOSE 8080

# 启动命令
CMD ["python3", "app.py"]
```

### 2.2 常用指令

**FROM**：指定基础镜像
```dockerfile
FROM ubuntu:20.04
FROM python:3.9-slim
FROM node:16-alpine
```

**LABEL**：添加元数据
```dockerfile
LABEL version="1.0"
LABEL description="My Application"
LABEL maintainer="admin@example.com"
```

**ENV**：设置环境变量
```dockerfile
ENV NODE_ENV=production
ENV APP_PORT=8080
ENV PATH=/app/bin:$PATH
```

**WORKDIR**：设置工作目录
```dockerfile
WORKDIR /app
# 后续的 RUN、CMD、COPY 等命令都在此目录执行
```

**COPY**：复制文件
```dockerfile
COPY app.py /app/
COPY . /app/
COPY --chown=user:group file.txt /app/
```

**ADD**：复制文件（支持 URL 和自动解压）
```dockerfile
ADD app.tar.gz /app/
ADD https://example.com/file.txt /app/
```

**RUN**：执行命令
```dockerfile
RUN apt-get update
RUN pip install -r requirements.txt
# 推荐合并命令减少层数
RUN apt-get update && \
    apt-get install -y python3 && \
    rm -rf /var/lib/apt/lists/*
```

**CMD**：容器启动命令
```dockerfile
CMD ["python3", "app.py"]
CMD python3 app.py  # shell 形式
```

**ENTRYPOINT**：容器入口点
```dockerfile
ENTRYPOINT ["python3"]
CMD ["app.py"]  # 可被覆盖的参数
```

**EXPOSE**：声明端口
```dockerfile
EXPOSE 80
EXPOSE 8080/tcp
EXPOSE 53/udp
```

**VOLUME**：定义数据卷
```dockerfile
VOLUME /data
VOLUME ["/var/log", "/var/db"]
```

**USER**：指定运行用户
```dockerfile
USER nginx
USER 1000:1000
```

**ARG**：构建参数
```dockerfile
ARG VERSION=1.0
RUN echo "Building version $VERSION"
```

---

## 3. 编写 Dockerfile

### 3.1 Python 应用

```dockerfile
# Dockerfile
FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 5000

# 启动命令
CMD ["python", "app.py"]
```

**构建和运行**：
```bash
# 构建镜像
docker build -t myapp:1.0 .

# 运行容器
docker run -d -p 5000:5000 myapp:1.0
```

### 3.2 Node.js 应用

```dockerfile
# Dockerfile
FROM node:16-alpine

# 设置工作目录
WORKDIR /app

# 复制 package.json
COPY package*.json ./

# 安装依赖
RUN npm install --production

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["node", "server.js"]
```

### 3.3 Java 应用

```dockerfile
# Dockerfile
FROM openjdk:11-jre-slim

# 设置工作目录
WORKDIR /app

# 复制 JAR 文件
COPY target/myapp.jar app.jar

# 暴露端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 3.4 Nginx 静态网站

```dockerfile
# Dockerfile
FROM nginx:alpine

# 复制网站文件
COPY html/ /usr/share/nginx/html/

# 复制 Nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# Nginx 已有启动命令，无需指定 CMD
```

---

## 4. 镜像构建

### 4.1 构建命令

```bash
# 基本构建
docker build -t myapp:1.0 .

# 指定 Dockerfile
docker build -f Dockerfile.prod -t myapp:prod .

# 指定构建参数
docker build --build-arg VERSION=2.0 -t myapp:2.0 .

# 不使用缓存
docker build --no-cache -t myapp:1.0 .

# 查看构建过程
docker build -t myapp:1.0 . --progress=plain
```

### 4.2 .dockerignore

创建 `.dockerignore` 文件排除不需要的文件：

```
# .dockerignore
.git
.gitignore
README.md
.env
node_modules
__pycache__
*.pyc
.DS_Store
```

### 4.3 构建上下文

```bash
# 当前目录作为构建上下文
docker build -t myapp .

# 指定构建上下文
docker build -t myapp /path/to/context

# 从 Git 仓库构建
docker build -t myapp https://github.com/user/repo.git

# 从标准输入构建
docker build -t myapp - < Dockerfile
```

---

## 5. 镜像优化

### 5.1 减小镜像大小

**使用精简基础镜像**：
```dockerfile
# ❌ 大镜像（~1GB）
FROM ubuntu:20.04

# ✅ 精简镜像（~100MB）
FROM python:3.9-slim

# ✅ 最小镜像（~5MB）
FROM python:3.9-alpine
```

**合并 RUN 命令**：
```dockerfile
# ❌ 多层
RUN apt-get update
RUN apt-get install -y python3
RUN apt-get install -y pip

# ✅ 单层
RUN apt-get update && \
    apt-get install -y python3 pip && \
    rm -rf /var/lib/apt/lists/*
```

**清理缓存**：
```dockerfile
# Python
RUN pip install --no-cache-dir -r requirements.txt

# Node.js
RUN npm install --production && \
    npm cache clean --force

# APT
RUN apt-get update && \
    apt-get install -y package && \
    rm -rf /var/lib/apt/lists/*
```

### 5.2 利用构建缓存

```dockerfile
# ✅ 先复制依赖文件，利用缓存
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

# ❌ 一次性复制所有文件，代码变化导致重新安装依赖
COPY . .
RUN pip install -r requirements.txt
```

### 5.3 多阶段构建

```dockerfile
# 第一阶段：构建
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 第二阶段：运行
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
```

**Java 应用多阶段构建**：
```dockerfile
# 构建阶段
FROM maven:3.8-openjdk-11 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# 运行阶段
FROM openjdk:11-jre-slim
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 6. 实战案例

### 案例1：Flask Web 应用

**目录结构**：
```
myapp/
├── Dockerfile
├── requirements.txt
├── app.py
└── templates/
    └── index.html
```

**app.py**：
```python
from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**requirements.txt**：
```
Flask==2.0.1
```

**Dockerfile**：
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

**构建和运行**：
```bash
docker build -t flask-app .
docker run -d -p 5000:5000 --name myflask flask-app
curl http://localhost:5000
```

### 案例2：React 前端应用

**Dockerfile**：
```dockerfile
# 构建阶段
FROM node:16-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 运行阶段
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf**：
```nginx
server {
    listen 80;
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
}
```

### 案例3：Go 应用

**Dockerfile**：
```dockerfile
# 构建阶段
FROM golang:1.19-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# 运行阶段
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

---

## 7. 镜像管理

### 7.1 镜像标签

```bash
# 构建时打标签
docker build -t myapp:1.0 .
docker build -t myapp:latest .

# 给已有镜像打标签
docker tag myapp:1.0 myapp:v1.0.0
docker tag myapp:1.0 registry.example.com/myapp:1.0
```

### 7.2 推送镜像

```bash
# 登录 Docker Hub
docker login

# 推送镜像
docker push username/myapp:1.0

# 登录私有仓库
docker login registry.example.com

# 推送到私有仓库
docker push registry.example.com/myapp:1.0
```

### 7.3 导出导入镜像

```bash
# 导出镜像
docker save -o myapp.tar myapp:1.0

# 导入镜像
docker load -i myapp.tar

# 导出容器为镜像
docker export container_name > container.tar

# 导入容器为镜像
docker import container.tar myapp:1.0
```

---

## 8. 练习题

### 练习1：编写 Dockerfile
为一个 Python Flask 应用编写 Dockerfile。

### 练习2：多阶段构建
使用多阶段构建优化一个 Node.js 应用的镜像大小。

### 练习3：镜像优化
优化一个现有的 Dockerfile，减小镜像大小。

### 练习4：实战应用
容器化一个完整的 Web 应用（前端 + 后端 + 数据库）。

---

## 📝 本节总结

### 核心要点

1. **镜像分层**：每条指令创建一层
2. **Dockerfile 指令**：FROM、RUN、COPY、CMD 等
3. **镜像构建**：docker build 命令
4. **镜像优化**：精简基础镜像、合并命令、多阶段构建
5. **实战应用**：Python、Node.js、Java、Go

### 最佳实践

```
✅ 使用精简基础镜像（alpine、slim）
✅ 合并 RUN 命令减少层数
✅ 利用构建缓存
✅ 使用 .dockerignore 排除文件
✅ 多阶段构建减小镜像大小
✅ 清理安装缓存
✅ 使用非 root 用户运行
```

### 下一步

学习完 Dockerfile 后，继续学习：
- Docker 网络配置
- Docker 数据卷管理
- Docker Compose 编排

---

**掌握 Dockerfile，构建高效镜像！** 🚀
