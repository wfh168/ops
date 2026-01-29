# 05 - Docker Compose 编排

## 📚 本节目标

- 理解 Docker Compose 概念
- 掌握 docker-compose.yml 编写
- 学会多容器应用编排
- 掌握 Compose 命令
- 实现生产环境部署

---

## 1. Docker Compose 简介

### 1.1 什么是 Docker Compose

Docker Compose 是用于定义和运行多容器 Docker 应用的工具。

**核心概念**：
```
一个 YAML 文件 → 定义多个服务
一条命令 → 启动所有服务
```

**优势**：
```
✅ 简化多容器管理
✅ 服务依赖管理
✅ 环境变量配置
✅ 网络自动创建
✅ 数据卷管理
✅ 一键启动/停止
```

### 1.2 安装 Docker Compose

```bash
# 方法1：使用 pip 安装
sudo pip install docker-compose

# 方法2：下载二进制文件
sudo curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

---

## 2. docker-compose.yml 基础

### 2.1 基本结构

```yaml
version: '3.8'  # Compose 文件版本

services:  # 定义服务
  web:
    image: nginx
    ports:
      - "80:80"
  
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: 123456

networks:  # 定义网络（可选）
  default:
    driver: bridge

volumes:  # 定义数据卷（可选）
  db-data:
```

### 2.2 服务配置选项

```yaml
services:
  myapp:
    # 使用镜像
    image: nginx:latest
    
    # 或构建镜像
    build:
      context: .
      dockerfile: Dockerfile
    
    # 容器名称
    container_name: myapp
    
    # 端口映射
    ports:
      - "8080:80"
      - "443:443"
    
    # 环境变量
    environment:
      - NODE_ENV=production
      - DB_HOST=mysql
    
    # 或使用 env_file
    env_file:
      - .env
    
    # 数据卷
    volumes:
      - ./data:/app/data
      - app-logs:/var/log
    
    # 网络
    networks:
      - frontend
      - backend
    
    # 依赖关系
    depends_on:
      - db
      - redis
    
    # 重启策略
    restart: always
    
    # 命令
    command: npm start
    
    # 工作目录
    working_dir: /app
    
    # 用户
    user: "1000:1000"
    
    # 资源限制
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

---

## 3. 实战案例

### 案例1：LNMP 架构

**目录结构**：
```
lnmp/
├── docker-compose.yml
├── nginx/
│   └── default.conf
├── php/
│   └── Dockerfile
└── www/
    └── index.php
```

**docker-compose.yml**：
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./www:/var/www/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php
    networks:
      - lnmp

  php:
    build: ./php
    volumes:
      - ./www:/var/www/html
    networks:
      - lnmp
    depends_on:
      - mysql

  mysql:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: testdb
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - lnmp

networks:
  lnmp:
    driver: bridge

volumes:
  mysql-data:
```

**nginx/default.conf**：
```nginx
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html;

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

**php/Dockerfile**：
```dockerfile
FROM php:7.4-fpm
RUN docker-php-ext-install mysqli pdo pdo_mysql
```

**www/index.php**：
```php
<?php
phpinfo();
?>
```

**启动**：
```bash
docker-compose up -d
```

### 案例2：WordPress 部署

```yaml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppass
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress-data:/var/www/html
    depends_on:
      - db
    restart: always

  db:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppass
    volumes:
      - db-data:/var/lib/mysql
    restart: always

volumes:
  wordpress-data:
  db-data:
```

### 案例3：微服务架构

```yaml
version: '3.8'

services:
  # API 网关
  gateway:
    build: ./gateway
    ports:
      - "8080:80"
    environment:
      - USER_SERVICE=http://user-service:8080
      - ORDER_SERVICE=http://order-service:8080
    depends_on:
      - user-service
      - order-service
    networks:
      - frontend

  # 用户服务
  user-service:
    build: ./user-service
    environment:
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis
    networks:
      - frontend
      - backend

  # 订单服务
  order-service:
    build: ./order-service
    environment:
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis
    networks:
      - frontend
      - backend

  # MySQL
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: 123456
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - backend

  # Redis
  redis:
    image: redis:alpine
    networks:
      - backend

networks:
  frontend:
  backend:

volumes:
  mysql-data:
```

---

## 4. Docker Compose 命令

### 4.1 基础命令

```bash
# 启动服务
docker-compose up
docker-compose up -d  # 后台运行
docker-compose up --build  # 重新构建镜像

# 停止服务
docker-compose stop

# 停止并删除容器
docker-compose down
docker-compose down -v  # 同时删除数据卷

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs
docker-compose logs -f  # 实时查看
docker-compose logs web  # 查看特定服务

# 执行命令
docker-compose exec web bash
docker-compose exec db mysql -uroot -p

# 重启服务
docker-compose restart
docker-compose restart web

# 暂停/恢复服务
docker-compose pause
docker-compose unpause

# 查看配置
docker-compose config

# 拉取镜像
docker-compose pull

# 构建镜像
docker-compose build
docker-compose build --no-cache
```

### 4.2 扩缩容

```bash
# 扩展服务实例
docker-compose up -d --scale web=3

# 查看扩展后的容器
docker-compose ps
```

### 4.3 指定配置文件

```bash
# 使用自定义配置文件
docker-compose -f docker-compose.prod.yml up -d

# 使用多个配置文件
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## 5. 环境变量

### 5.1 使用 .env 文件

**.env**：
```bash
# 数据库配置
MYSQL_ROOT_PASSWORD=123456
MYSQL_DATABASE=mydb

# 应用配置
APP_PORT=8080
APP_ENV=production
```

**docker-compose.yml**：
```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
  
  web:
    image: myapp
    ports:
      - "${APP_PORT}:80"
    environment:
      APP_ENV: ${APP_ENV}
```

### 5.2 环境变量优先级

```
1. Compose 文件中的 environment
2. Shell 环境变量
3. .env 文件
4. Dockerfile 中的 ENV
```

---

## 6. 网络配置

### 6.1 自定义网络

```yaml
version: '3.8'

services:
  web:
    image: nginx
    networks:
      - frontend
  
  app:
    image: myapp
    networks:
      - frontend
      - backend
  
  db:
    image: mysql
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # 内部网络，不能访问外网
```

### 6.2 使用已存在的网络

```yaml
networks:
  default:
    external:
      name: my-existing-network
```

---

## 7. 数据卷配置

### 7.1 命名数据卷

```yaml
version: '3.8'

services:
  db:
    image: mysql
    volumes:
      - db-data:/var/lib/mysql

volumes:
  db-data:
    driver: local
```

### 7.2 使用已存在的数据卷

```yaml
volumes:
  db-data:
    external: true
```

### 7.3 数据卷驱动

```yaml
volumes:
  db-data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=192.168.1.100,rw
      device: ":/path/to/dir"
```

---

## 8. 生产环境部署

### 8.1 多环境配置

**docker-compose.yml**（基础配置）：
```yaml
version: '3.8'

services:
  web:
    image: myapp
    ports:
      - "80:80"
```

**docker-compose.prod.yml**（生产环境）：
```yaml
version: '3.8'

services:
  web:
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    restart: always
```

**启动生产环境**：
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 8.2 健康检查

```yaml
services:
  web:
    image: nginx
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 8.3 日志配置

```yaml
services:
  web:
    image: nginx
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## 9. 实战项目

### 项目：完整的 Web 应用

**目录结构**：
```
myproject/
├── docker-compose.yml
├── .env
├── nginx/
│   ├── Dockerfile
│   └── nginx.conf
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
└── frontend/
    ├── Dockerfile
    ├── package.json
    └── src/
```

**docker-compose.yml**：
```yaml
version: '3.8'

services:
  nginx:
    build: ./nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - frontend
      - backend
    networks:
      - app-network

  frontend:
    build: ./frontend
    volumes:
      - ./frontend/src:/app/src
    environment:
      - API_URL=http://backend:5000
    networks:
      - app-network

  backend:
    build: ./backend
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis
    networks:
      - app-network

  postgres:
    image: postgres:13
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

  redis:
    image: redis:alpine
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres-data:
```

---

## 10. 练习题

### 练习1：基础编排
使用 Docker Compose 部署 Nginx + MySQL。

### 练习2：WordPress 部署
使用 Docker Compose 部署完整的 WordPress 站点。

### 练习3：微服务架构
部署一个包含多个服务的微服务应用。

### 练习4：生产环境
配置生产环境的 Docker Compose 文件。

---

## 📝 本节总结

### 核心要点

1. **Docker Compose**：多容器应用编排工具
2. **YAML 配置**：定义服务、网络、数据卷
3. **服务依赖**：depends_on 管理启动顺序
4. **环境变量**：.env 文件配置
5. **多环境部署**：开发、测试、生产环境

### 最佳实践

```
✅ 使用 .env 文件管理环境变量
✅ 合理使用服务依赖
✅ 配置健康检查
✅ 限制资源使用
✅ 配置日志驱动
✅ 使用命名数据卷
✅ 多环境配置分离
```

### 下一步

学习完 Docker Compose 后，继续学习：
- Docker Swarm 集群
- Kubernetes 容器编排
- CI/CD 集成

---

**掌握 Docker Compose，轻松编排多容器应用！** 🚀
