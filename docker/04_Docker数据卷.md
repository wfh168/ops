# 04 - Docker 数据卷

## 📚 本节目标

- 理解数据持久化需求
- 掌握数据卷操作
- 学会挂载主机目录
- 了解数据卷容器
- 掌握数据备份恢复

---

## 1. 为什么需要数据卷

### 1.1 容器数据问题

```
问题1：数据丢失
容器删除 → 数据丢失

问题2：数据共享困难
容器间无法共享数据

问题3：性能问题
容器层写入性能差

解决方案：Docker 数据卷
```

### 1.2 数据卷的优势

```
✅ 数据持久化：容器删除，数据保留
✅ 数据共享：多个容器共享数据
✅ 性能优化：绕过容器文件系统
✅ 备份恢复：方便数据备份
✅ 主机访问：可直接访问数据
```

---

## 2. 数据卷类型

### 2.1 三种挂载方式

```
1. Volume（数据卷）
   - Docker 管理的数据卷
   - 存储在 /var/lib/docker/volumes/
   - 推荐使用

2. Bind Mount（绑定挂载）
   - 挂载主机目录或文件
   - 可以是任意路径
   - 灵活但依赖主机

3. tmpfs Mount（临时挂载）
   - 挂载到内存
   - 容器停止数据丢失
   - 用于敏感数据
```

**对比**：
```
┌─────────────────────────────────────┐
│         Host (宿主机)                │
│                                     │
│  /var/lib/docker/volumes/           │
│  ├─ myvolume/                       │
│  │  └─ _data/  ← Volume            │
│  │                                  │
│  /home/user/data/  ← Bind Mount    │
│  │                                  │
│  Memory  ← tmpfs                    │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Container                  │   │
│  │  /app/data  ← 挂载点        │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 3. Volume（数据卷）

### 3.1 创建和管理数据卷

```bash
# 创建数据卷
docker volume create mydata

# 查看数据卷列表
docker volume ls

# 查看数据卷详情
docker volume inspect mydata

# 删除数据卷
docker volume rm mydata

# 清理未使用的数据卷
docker volume prune
```

### 3.2 使用数据卷

```bash
# 运行容器并挂载数据卷
docker run -d \
    --name nginx \
    -v mydata:/usr/share/nginx/html \
    nginx

# 或使用 --mount（推荐）
docker run -d \
    --name nginx \
    --mount source=mydata,target=/usr/share/nginx/html \
    nginx

# 查看容器挂载信息
docker inspect nginx | grep -A 10 Mounts
```

### 3.3 数据卷位置

```bash
# 查看数据卷在主机上的位置
docker volume inspect mydata

# 输出示例：
# "Mountpoint": "/var/lib/docker/volumes/mydata/_data"

# 直接访问数据卷
sudo ls -la /var/lib/docker/volumes/mydata/_data

# 写入数据
sudo echo "Hello Docker" > /var/lib/docker/volumes/mydata/_data/index.html

# 从容器访问
docker exec nginx cat /usr/share/nginx/html/index.html
```

---

## 4. Bind Mount（绑定挂载）

### 4.1 挂载主机目录

```bash
# 创建主机目录
mkdir -p ~/mywebsite
echo "<h1>Hello Docker</h1>" > ~/mywebsite/index.html

# 挂载主机目录
docker run -d \
    --name nginx \
    -p 8080:80 \
    -v ~/mywebsite:/usr/share/nginx/html \
    nginx

# 或使用 --mount
docker run -d \
    --name nginx \
    -p 8080:80 \
    --mount type=bind,source=~/mywebsite,target=/usr/share/nginx/html \
    nginx

# 访问网站
curl http://localhost:8080
```

### 4.2 只读挂载

```bash
# 只读挂载（容器内无法修改）
docker run -d \
    --name nginx \
    -v ~/mywebsite:/usr/share/nginx/html:ro \
    nginx

# 测试（会失败）
docker exec nginx sh -c "echo test > /usr/share/nginx/html/test.txt"
# 错误：Read-only file system
```

### 4.3 挂载单个文件

```bash
# 挂载配置文件
docker run -d \
    --name nginx \
    -v ~/nginx.conf:/etc/nginx/nginx.conf:ro \
    nginx

# 挂载多个文件
docker run -d \
    --name app \
    -v ~/config.json:/app/config.json:ro \
    -v ~/data:/app/data \
    myapp
```

---

## 5. tmpfs Mount（临时挂载）

### 5.1 使用 tmpfs

```bash
# 挂载到内存
docker run -d \
    --name app \
    --tmpfs /app/cache:rw,size=100m \
    myapp

# 或使用 --mount
docker run -d \
    --name app \
    --mount type=tmpfs,target=/app/cache,tmpfs-size=104857600 \
    myapp
```

**特点**：
- 数据存储在内存中
- 读写速度快
- 容器停止数据丢失
- 适合临时数据、缓存

---

## 6. 数据卷容器

### 6.1 创建数据卷容器

```bash
# 创建数据卷容器
docker create -v /data --name datacontainer busybox

# 其他容器使用数据卷容器
docker run -d \
    --name app1 \
    --volumes-from datacontainer \
    myapp

docker run -d \
    --name app2 \
    --volumes-from datacontainer \
    myapp

# app1 和 app2 共享 /data 目录
```

### 6.2 数据卷容器的应用

```bash
# 创建配置容器
docker create -v /config --name config busybox

# 复制配置文件到数据卷
docker cp app.conf config:/config/

# 应用容器使用配置
docker run -d \
    --name webapp \
    --volumes-from config \
    myapp
```

---

## 7. 数据备份和恢复

### 7.1 备份数据卷

```bash
# 方法1：使用临时容器备份
docker run --rm \
    -v mydata:/data \
    -v $(pwd):/backup \
    busybox \
    tar czf /backup/mydata-backup.tar.gz /data

# 方法2：直接备份主机目录
sudo tar czf mydata-backup.tar.gz \
    /var/lib/docker/volumes/mydata/_data

# 方法3：使用 docker cp
docker cp container_name:/data ./backup/
```

### 7.2 恢复数据卷

```bash
# 创建新数据卷
docker volume create mydata-restore

# 恢复数据
docker run --rm \
    -v mydata-restore:/data \
    -v $(pwd):/backup \
    busybox \
    tar xzf /backup/mydata-backup.tar.gz -C /

# 使用恢复的数据卷
docker run -d \
    --name nginx \
    -v mydata-restore:/usr/share/nginx/html \
    nginx
```

### 7.3 迁移数据卷

```bash
# 导出数据卷
docker run --rm \
    -v mydata:/data \
    -v $(pwd):/backup \
    busybox \
    tar czf /backup/data.tar.gz /data

# 在新主机上导入
docker volume create mydata
docker run --rm \
    -v mydata:/data \
    -v $(pwd):/backup \
    busybox \
    tar xzf /backup/data.tar.gz -C /
```

---

## 8. 实战案例

### 案例1：MySQL 数据持久化

```bash
# 创建数据卷
docker volume create mysql-data

# 运行 MySQL 容器
docker run -d \
    --name mysql \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=123456 \
    -v mysql-data:/var/lib/mysql \
    mysql:8.0

# 创建数据库和表
docker exec -it mysql mysql -uroot -p123456 -e "
CREATE DATABASE testdb;
USE testdb;
CREATE TABLE users (id INT, name VARCHAR(50));
INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');
"

# 删除容器
docker rm -f mysql

# 重新运行容器（数据保留）
docker run -d \
    --name mysql \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=123456 \
    -v mysql-data:/var/lib/mysql \
    mysql:8.0

# 验证数据
docker exec -it mysql mysql -uroot -p123456 -e "
USE testdb;
SELECT * FROM users;
"
```

### 案例2：Nginx 网站部署

```bash
# 创建网站目录
mkdir -p ~/website/{html,conf,logs}

# 创建网站文件
cat > ~/website/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>My Website</title></head>
<body><h1>Hello Docker!</h1></body>
</html>
EOF

# 创建 Nginx 配置
cat > ~/website/conf/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF

# 运行 Nginx 容器
docker run -d \
    --name website \
    -p 80:80 \
    -v ~/website/html:/usr/share/nginx/html:ro \
    -v ~/website/conf:/etc/nginx/conf.d:ro \
    -v ~/website/logs:/var/log/nginx \
    nginx

# 访问网站
curl http://localhost

# 查看日志
tail -f ~/website/logs/access.log
```

### 案例3：WordPress 完整部署

```bash
# 创建网络
docker network create wordpress

# 创建数据卷
docker volume create mysql-data
docker volume create wordpress-data

# 运行 MySQL
docker run -d \
    --name mysql \
    --network wordpress \
    -e MYSQL_ROOT_PASSWORD=rootpass \
    -e MYSQL_DATABASE=wordpress \
    -e MYSQL_USER=wpuser \
    -e MYSQL_PASSWORD=wppass \
    -v mysql-data:/var/lib/mysql \
    mysql:5.7

# 运行 WordPress
docker run -d \
    --name wordpress \
    --network wordpress \
    -p 8080:80 \
    -e WORDPRESS_DB_HOST=mysql \
    -e WORDPRESS_DB_USER=wpuser \
    -e WORDPRESS_DB_PASSWORD=wppass \
    -e WORDPRESS_DB_NAME=wordpress \
    -v wordpress-data:/var/www/html \
    wordpress

# 访问 WordPress
# http://localhost:8080
```

### 案例4：开发环境数据共享

```bash
# 创建项目目录
mkdir -p ~/project/{src,data}

# 运行开发容器
docker run -d \
    --name dev \
    -v ~/project/src:/app/src \
    -v ~/project/data:/app/data \
    -p 3000:3000 \
    node:16

# 在主机编辑代码
vim ~/project/src/app.js

# 容器内自动更新（热重载）
```

---

## 9. 数据卷最佳实践

### 9.1 选择合适的挂载方式

```bash
# ✅ 数据库数据：使用 Volume
docker run -v mysql-data:/var/lib/mysql mysql

# ✅ 配置文件：使用 Bind Mount（只读）
docker run -v ~/config.yml:/app/config.yml:ro myapp

# ✅ 开发代码：使用 Bind Mount
docker run -v ~/project:/app node

# ✅ 临时缓存：使用 tmpfs
docker run --tmpfs /app/cache myapp
```

### 9.2 数据卷命名

```bash
# ✅ 使用有意义的名称
docker volume create mysql-prod-data
docker volume create nginx-logs

# ❌ 避免使用默认名称
docker run -v /data nginx  # 生成随机名称
```

### 9.3 定期备份

```bash
# 创建备份脚本
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
docker run --rm \
    -v mysql-data:/data \
    -v $(pwd)/backups:/backup \
    busybox \
    tar czf /backup/mysql-$DATE.tar.gz /data
EOF

chmod +x backup.sh

# 定时备份（crontab）
0 2 * * * /path/to/backup.sh
```

---

## 10. 常见问题

### 问题1：权限问题

```bash
# 问题：容器内无法写入
# 原因：主机目录权限不足

# 解决：修改主机目录权限
sudo chown -R 1000:1000 ~/data

# 或在 Dockerfile 中指定用户
USER 1000:1000
```

### 问题2：数据卷占用空间

```bash
# 查看数据卷大小
docker system df -v

# 清理未使用的数据卷
docker volume prune

# 删除特定数据卷
docker volume rm volume_name
```

### 问题3：数据卷无法删除

```bash
# 错误：volume is in use
# 原因：有容器正在使用

# 查看使用该数据卷的容器
docker ps -a --filter volume=mydata

# 停止并删除容器
docker rm -f container_name

# 删除数据卷
docker volume rm mydata
```

---

## 11. 练习题

### 练习1：基础操作
1. 创建数据卷
2. 运行容器并挂载数据卷
3. 在容器内写入数据
4. 删除容器后验证数据是否保留

### 练习2：数据备份
1. 创建 MySQL 容器并持久化数据
2. 创建测试数据
3. 备份数据卷
4. 恢复到新数据卷

### 练习3：实战应用
1. 部署 WordPress（MySQL + WordPress）
2. 配置数据持久化
3. 测试数据是否保留
4. 实现数据备份

---

## 📝 本节总结

### 核心要点

1. **数据卷类型**：Volume、Bind Mount、tmpfs
2. **数据持久化**：容器删除，数据保留
3. **数据共享**：多个容器共享数据
4. **备份恢复**：定期备份，快速恢复
5. **实战应用**：MySQL、Nginx、WordPress

### 最佳实践

```
✅ 使用 Volume 存储重要数据
✅ 使用 Bind Mount 挂载配置文件
✅ 配置文件使用只读挂载
✅ 定期备份数据卷
✅ 使用有意义的数据卷名称
✅ 及时清理未使用的数据卷
```

### 下一步

学习完 Docker 数据卷后，继续学习：
- Docker Compose 多容器编排
- Docker Swarm 集群管理
- 容器监控和日志

---

**掌握 Docker 数据卷，实现数据持久化！** 🚀
