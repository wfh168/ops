# 08 - Docker 实战应用

## 📚 本节目标

- 掌握 Web 应用容器化
- 部署微服务架构
- 实现 CI/CD 集成
- 掌握生产环境部署
- 了解最佳实践
- 解决常见问题

---

## 1. LNMP 架构部署

### 1.1 架构设计

```
┌─────────────────────────────────┐
│         Nginx (反向代理)         │
│         Port: 80                │
└──────────────┬──────────────────┘
               │
┌──────────────↓──────────────────┐
│         PHP-FPM (应用)           │
│         Port: 9000              │
└──────────────┬──────────────────┘
               │
┌──────────────↓──────────────────┐
│         MySQL (数据库)           │
│         Port: 3306              │
└─────────────────────────────────┘
```

### 1.2 docker-compose.yml

```yaml
version: '3'

services:
  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
    volumes:
      - ./www:/var/www/html
      - ./nginx/conf.d:/etc/nginx/conf.d
    depends_on:
      - php
    networks:
      - lnmp
    restart: always

  php:
    image: php:7.4-fpm-alpine
    container_name: php
    volumes:
      - ./www:/var/www/html
    networks:
      - lnmp
    restart: always

  mysql:
    image: mysql:8.0
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: mydb
      MYSQL_USER: dbuser
      MYSQL_PASSWORD: dbpass
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - lnmp
    restart: always

networks:
  lnmp:
    driver: bridge

volumes:
  mysql-data:
```

### 1.3 Nginx 配置

**nginx/conf.d/default.conf**：
```nginx
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

### 1.4 测试应用

**www/index.php**：
```php
<?php
phpinfo();

// 测试 MySQL 连接
$host = 'mysql';
$db = 'mydb';
$user = 'dbuser';
$pass = 'dbpass';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
    echo "<h2>MySQL 连接成功！</h2>";
} catch (PDOException $e) {
    echo "<h2>MySQL 连接失败：" . $e->getMessage() . "</h2>";
}
?>
```

**启动服务**：
```bash
docker-compose up -d

# 访问
curl http://localhost
```

---

## 2. 微服务架构部署

### 2.1 架构设计

```
┌─────────────────────────────────┐
│      Nginx (API Gateway)        │
└──────────────┬──────────────────┘
               │
       ┌───────┴───────┐
       ↓               ↓
┌─────────────┐ ┌─────────────┐
│ User Service│ │Order Service│
└──────┬──────┘ └──────┬──────┘
       │               │
       ↓               ↓
┌─────────────┐ ┌─────────────┐
│   MySQL     │ │   Redis     │
└─────────────┘ └─────────────┘
```

### 2.2 用户服务

**user-service/app.py**：
```python
from flask import Flask, jsonify, request
import mysql.connector

app = Flask(__name__)

def get_db():
    return mysql.connector.connect(
        host='mysql',
        user='root',
        password='root123',
        database='userdb'
    )

@app.route('/users', methods=['GET'])
def get_users():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(users)

@app.route('/users', methods=['POST'])
def create_user():
    data = request.json
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO users (name, email) VALUES (%s, %s)",
        (data['name'], data['email'])
    )
    db.commit()
    user_id = cursor.lastrowid
    cursor.close()
    db.close()
    return jsonify({'id': user_id}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**user-service/Dockerfile**：
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

### 2.3 订单服务

**order-service/app.py**：
```python
from flask import Flask, jsonify, request
import redis

app = Flask(__name__)
r = redis.Redis(host='redis', port=6379, decode_responses=True)

@app.route('/orders', methods=['GET'])
def get_orders():
    orders = []
    for key in r.keys('order:*'):
        orders.append(r.hgetall(key))
    return jsonify(orders)

@app.route('/orders', methods=['POST'])
def create_order():
    data = request.json
    order_id = r.incr('order:id')
    r.hset(f'order:{order_id}', mapping={
        'user_id': data['user_id'],
        'product': data['product'],
        'amount': data['amount']
    })
    return jsonify({'id': order_id}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
```

### 2.4 docker-compose.yml

```yaml
version: '3'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - user-service
      - order-service
    networks:
      - microservices

  user-service:
    build: ./user-service
    environment:
      - DB_HOST=mysql
    depends_on:
      - mysql
    networks:
      - microservices

  order-service:
    build: ./order-service
    environment:
      - REDIS_HOST=redis
    depends_on:
      - redis
    networks:
      - microservices

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: userdb
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - microservices

  redis:
    image: redis:alpine
    networks:
      - microservices

networks:
  microservices:

volumes:
  mysql-data:
```

---

## 3. CI/CD 集成

### 3.1 GitLab CI/CD

**.gitlab-ci.yml**：
```yaml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_REGISTRY: registry.example.com
  IMAGE_NAME: myapp
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA

build:
  stage: build
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $DOCKER_REGISTRY
    - docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG .
    - docker push $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
  only:
    - master

test:
  stage: test
  script:
    - docker run --rm $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG pytest
  only:
    - master

deploy:
  stage: deploy
  script:
    - ssh user@server "docker pull $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    - ssh user@server "docker stop myapp || true"
    - ssh user@server "docker rm myapp || true"
    - ssh user@server "docker run -d --name myapp -p 80:80 $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
  only:
    - master
  when: manual
```

### 3.2 Jenkins Pipeline

**Jenkinsfile**：
```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        IMAGE_NAME = 'myapp'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    docker.image("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}").inside {
                        sh 'pytest'
                    }
                }
            }
        }
        
        stage('Push') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials') {
                        docker.image("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}").push()
                        docker.image("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}").push('latest')
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    ssh user@server "docker pull ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    ssh user@server "docker stop myapp || true"
                    ssh user@server "docker rm myapp || true"
                    ssh user@server "docker run -d --name myapp -p 80:80 ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                '''
            }
        }
    }
}
```

---

## 4. 生产环境部署

### 4.1 健康检查

**Dockerfile**：
```dockerfile
FROM nginx:alpine

COPY html /usr/share/nginx/html

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80
```

**docker-compose.yml**：
```yaml
services:
  web:
    image: myapp:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
```

### 4.2 资源限制

```yaml
services:
  web:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '1'
          memory: 512M
```

### 4.3 日志配置

```yaml
services:
  web:
    image: myapp:latest
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 4.4 环境变量管理

**.env 文件**：
```
DB_HOST=mysql
DB_PORT=3306
DB_USER=dbuser
DB_PASS=dbpass
REDIS_HOST=redis
REDIS_PORT=6379
```

**docker-compose.yml**：
```yaml
services:
  web:
    image: myapp:latest
    env_file:
      - .env
    environment:
      - APP_ENV=production
```

### 4.5 数据备份

**备份脚本**：
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 备份 MySQL
docker exec mysql mysqldump -u root -proot123 --all-databases > $BACKUP_DIR/mysql_$DATE.sql

# 备份数据卷
docker run --rm \
    -v mysql-data:/data \
    -v $BACKUP_DIR:/backup \
    alpine tar czf /backup/mysql-data_$DATE.tar.gz /data

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

---

## 5. 最佳实践

### 5.1 镜像优化

```dockerfile
# ✅ 使用精简基础镜像
FROM python:3.9-slim

# ✅ 合并 RUN 命令
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

# ✅ 利用构建缓存
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# ✅ 使用非 root 用户
RUN useradd -m -u 1000 appuser
USER appuser

# ✅ 多阶段构建
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
```

### 5.2 安全配置

```yaml
services:
  web:
    image: myapp:latest
    # 只读根文件系统
    read_only: true
    # 临时文件系统
    tmpfs:
      - /tmp
    # 禁用特权模式
    privileged: false
    # 限制能力
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    # 安全选项
    security_opt:
      - no-new-privileges:true
```

### 5.3 网络隔离

```yaml
services:
  web:
    networks:
      - frontend
  
  api:
    networks:
      - frontend
      - backend
  
  db:
    networks:
      - backend

networks:
  frontend:
  backend:
    internal: true  # 内部网络，不能访问外网
```

### 5.4 配置管理

**使用 Docker Secrets**：
```yaml
services:
  web:
    image: myapp:latest
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**使用 Docker Configs**：
```yaml
services:
  web:
    image: myapp:latest
    configs:
      - source: nginx_config
        target: /etc/nginx/nginx.conf

configs:
  nginx_config:
    file: ./nginx.conf
```

---

## 6. 常见问题

### 问题1：容器无法启动

```bash
# 查看日志
docker logs container_name

# 查看详细信息
docker inspect container_name

# 检查健康状态
docker ps --filter "health=unhealthy"
```

### 问题2：网络连接问题

```bash
# 查看网络
docker network ls
docker network inspect network_name

# 测试连接
docker exec container1 ping container2

# 检查端口映射
docker port container_name
```

### 问题3：数据丢失

```bash
# 使用数据卷
docker volume create mydata
docker run -v mydata:/data myapp

# 备份数据卷
docker run --rm -v mydata:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data

# 恢复数据卷
docker run --rm -v mydata:/data -v $(pwd):/backup alpine tar xzf /backup/backup.tar.gz -C /
```

### 问题4：性能问题

```bash
# 查看资源使用
docker stats

# 限制资源
docker run --cpus="1.5" --memory="512m" myapp

# 查看容器进程
docker top container_name
```

---

## 7. 实战项目

### 项目1：博客系统

**技术栈**：
- 前端：Nginx + Vue.js
- 后端：Python Flask
- 数据库：MySQL
- 缓存：Redis

**部署步骤**：
```bash
# 1. 克隆项目
git clone https://github.com/example/blog.git
cd blog

# 2. 构建镜像
docker-compose build

# 3. 启动服务
docker-compose up -d

# 4. 初始化数据库
docker-compose exec backend python init_db.py

# 5. 访问应用
# http://localhost
```

### 项目2：电商系统

**微服务架构**：
- 用户服务
- 商品服务
- 订单服务
- 支付服务
- API 网关

**部署架构**：
```
Nginx (API Gateway)
    ↓
User Service → MySQL
Product Service → MySQL
Order Service → MySQL + Redis
Payment Service → MySQL
```

---

## 8. 练习题

### 练习1：LNMP 部署
部署一个完整的 LNMP 环境，运行 WordPress。

### 练习2：微服务部署
部署一个包含 3 个微服务的应用。

### 练习3：CI/CD 集成
配置 GitLab CI/CD 自动构建和部署。

### 练习4：生产环境
配置健康检查、资源限制、日志管理。

---

## 📝 本节总结

### 核心要点

1. **LNMP 架构**：Nginx + PHP + MySQL
2. **微服务部署**：多容器协作
3. **CI/CD 集成**：自动化构建部署
4. **生产实践**：健康检查、资源限制、安全配置
5. **最佳实践**：镜像优化、网络隔离、配置管理

### 最佳实践

```
✅ 使用 Docker Compose 编排
✅ 配置健康检查
✅ 设置资源限制
✅ 使用数据卷持久化
✅ 配置日志管理
✅ 实现 CI/CD 自动化
✅ 定期备份数据
✅ 监控容器状态
```

### 下一步

完成 Docker 学习后，继续学习：
- Kubernetes 容器编排
- 服务网格（Service Mesh）
- 云原生架构
- DevOps 实践

---

**恭喜你完成 Docker 全部学习！** 🎉🚀

**从基础到实战，你已经掌握了 Docker 容器技术的核心技能！**

**继续加油，成为容器技术专家！** 💪
