# 03 - Docker 网络

## 📚 本节目标

- 理解 Docker 网络模式
- 掌握网络操作命令
- 学会容器互联
- 掌握端口映射
- 了解自定义网络

---

## 1. Docker 网络模式

### 1.1 网络模式概览

Docker 支持 5 种网络模式：

| 网络模式 | 说明 | 使用场景 |
|---------|------|---------|
| bridge | 桥接模式（默认） | 单机容器通信 |
| host | 主机模式 | 性能要求高 |
| none | 无网络模式 | 安全隔离 |
| container | 容器模式 | 共享网络栈 |
| overlay | 覆盖网络 | 跨主机通信 |

### 1.2 网络架构

```
┌─────────────────────────────────────────┐
│           Host (宿主机)                  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  docker0 (172.17.0.1)           │   │
│  │  (默认网桥)                      │   │
│  └──────┬──────────────┬───────────┘   │
│         │              │                │
│  ┌──────↓──────┐ ┌────↓──────┐        │
│  │ Container1  │ │ Container2 │        │
│  │ 172.17.0.2  │ │ 172.17.0.3 │        │
│  └─────────────┘ └────────────┘        │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  eth0 (192.168.1.100)           │   │
│  │  (物理网卡)                      │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

## 2. Bridge 网络（桥接模式）

### 2.1 默认 bridge 网络

```bash
# 查看网络列表
docker network ls

# 查看 bridge 网络详情
docker network inspect bridge

# 运行容器（默认使用 bridge）
docker run -d --name nginx1 nginx
docker run -d --name nginx2 nginx

# 查看容器 IP
docker inspect nginx1 | grep IPAddress
docker inspect nginx2 | grep IPAddress

# 容器间通信（通过 IP）
docker exec nginx1 ping 172.17.0.3
```

**特点**：
- 容器获得独立 IP（172.17.0.0/16 网段）
- 容器间可通过 IP 通信
- 容器不能通过容器名通信
- 需要端口映射才能从外部访问

### 2.2 自定义 bridge 网络

```bash
# 创建自定义网络
docker network create mynet

# 指定网段创建网络
docker network create --subnet=192.168.100.0/24 mynet2

# 运行容器并连接到自定义网络
docker run -d --name web1 --network mynet nginx
docker run -d --name web2 --network mynet nginx

# 容器间通信（通过容器名）
docker exec web1 ping web2  # ✅ 可以通过容器名通信

# 查看网络详情
docker network inspect mynet
```

**自定义网络的优势**：
- 支持容器名解析（DNS）
- 更好的隔离性
- 可以动态连接/断开容器
- 可以自定义网段

### 2.3 连接和断开网络

```bash
# 将运行中的容器连接到网络
docker network connect mynet nginx1

# 断开容器与网络的连接
docker network disconnect mynet nginx1

# 容器可以连接多个网络
docker network connect mynet2 nginx1
```

---

## 3. Host 网络（主机模式）

### 3.1 使用 host 网络

```bash
# 使用 host 网络运行容器
docker run -d --name nginx-host --network host nginx

# 查看容器（没有独立 IP）
docker inspect nginx-host | grep IPAddress

# 直接访问（使用主机 IP）
curl http://localhost:80
```

**特点**：
- 容器直接使用主机网络
- 没有独立 IP
- 性能最好（无 NAT 转换）
- 端口冲突风险
- 安全性较低

**使用场景**：
- 性能要求极高的应用
- 需要访问主机网络服务
- 网络监控工具

---

## 4. None 网络（无网络模式）

### 4.1 使用 none 网络

```bash
# 使用 none 网络运行容器
docker run -d --name isolated --network none nginx

# 查看网络（只有 lo 回环接口）
docker exec isolated ip addr
```

**特点**：
- 容器没有网络接口（除了 lo）
- 完全隔离
- 最高安全性

**使用场景**：
- 安全要求极高的应用
- 不需要网络的批处理任务
- 自定义网络配置

---

## 5. Container 网络（容器模式）

### 5.1 共享网络栈

```bash
# 运行第一个容器
docker run -d --name web nginx

# 运行第二个容器，共享第一个容器的网络
docker run -d --name app --network container:web myapp

# 两个容器共享相同的 IP 和端口
docker exec web ip addr
docker exec app ip addr  # 相同的 IP
```

**特点**：
- 共享网络命名空间
- 共享 IP 和端口
- 可以通过 localhost 通信

**使用场景**：
- 紧密耦合的容器
- 服务网格（Sidecar 模式）
- 日志收集容器

---

## 6. 端口映射

### 6.1 基本端口映射

```bash
# 映射单个端口
docker run -d -p 8080:80 nginx

# 映射到指定 IP
docker run -d -p 127.0.0.1:8080:80 nginx

# 映射多个端口
docker run -d -p 8080:80 -p 8443:443 nginx

# 随机端口映射
docker run -d -P nginx  # 自动映射 EXPOSE 的端口

# 查看端口映射
docker port nginx
```

### 6.2 UDP 端口映射

```bash
# 映射 UDP 端口
docker run -d -p 53:53/udp dns-server

# 同时映射 TCP 和 UDP
docker run -d -p 53:53/tcp -p 53:53/udp dns-server
```

### 6.3 查看端口映射

```bash
# 查看容器端口映射
docker port container_name

# 查看所有容器的端口映射
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

---

## 7. 容器互联

### 7.1 使用自定义网络

```bash
# 创建网络
docker network create app-net

# 运行数据库容器
docker run -d \
    --name mysql \
    --network app-net \
    -e MYSQL_ROOT_PASSWORD=123456 \
    mysql:8.0

# 运行应用容器
docker run -d \
    --name webapp \
    --network app-net \
    -p 8080:80 \
    -e DB_HOST=mysql \
    myapp

# 应用可以通过容器名访问数据库
# mysql://mysql:3306
```

### 7.2 使用 link（已废弃）

```bash
# 使用 --link（不推荐）
docker run -d --name mysql mysql:8.0
docker run -d --name webapp --link mysql:db myapp

# 推荐使用自定义网络代替
```

---

## 8. 网络管理

### 8.1 网络操作命令

```bash
# 创建网络
docker network create mynet

# 查看网络列表
docker network ls

# 查看网络详情
docker network inspect mynet

# 删除网络
docker network rm mynet

# 清理未使用的网络
docker network prune

# 连接容器到网络
docker network connect mynet container_name

# 断开容器与网络
docker network disconnect mynet container_name
```

### 8.2 网络配置选项

```bash
# 指定子网和网关
docker network create \
    --subnet=192.168.100.0/24 \
    --gateway=192.168.100.1 \
    mynet

# 指定 IP 范围
docker network create \
    --subnet=192.168.100.0/24 \
    --ip-range=192.168.100.128/25 \
    mynet

# 指定驱动
docker network create \
    --driver bridge \
    mynet

# 设置 MTU
docker network create \
    --opt com.docker.network.driver.mtu=1450 \
    mynet
```

### 8.3 为容器指定 IP

```bash
# 创建网络
docker network create --subnet=192.168.100.0/24 mynet

# 运行容器并指定 IP
docker run -d \
    --name web \
    --network mynet \
    --ip 192.168.100.10 \
    nginx
```

---

## 9. 实战案例

### 案例1：LNMP 架构

```bash
# 1. 创建网络
docker network create lnmp

# 2. 运行 MySQL
docker run -d \
    --name mysql \
    --network lnmp \
    -e MYSQL_ROOT_PASSWORD=123456 \
    -e MYSQL_DATABASE=wordpress \
    mysql:5.7

# 3. 运行 PHP-FPM
docker run -d \
    --name php \
    --network lnmp \
    -v /var/www/html:/var/www/html \
    php:7.4-fpm

# 4. 运行 Nginx
docker run -d \
    --name nginx \
    --network lnmp \
    -p 80:80 \
    -v /var/www/html:/var/www/html \
    -v /etc/nginx/conf.d:/etc/nginx/conf.d \
    nginx

# 容器间通信：
# Nginx → PHP: fastcgi_pass php:9000;
# PHP → MySQL: mysqli_connect('mysql', 'root', '123456');
```

### 案例2：微服务架构

```bash
# 创建网络
docker network create microservices

# 运行 Redis
docker run -d \
    --name redis \
    --network microservices \
    redis

# 运行用户服务
docker run -d \
    --name user-service \
    --network microservices \
    -e REDIS_HOST=redis \
    user-service:latest

# 运行订单服务
docker run -d \
    --name order-service \
    --network microservices \
    -e REDIS_HOST=redis \
    -e USER_SERVICE=http://user-service:8080 \
    order-service:latest

# 运行 API 网关
docker run -d \
    --name api-gateway \
    --network microservices \
    -p 8080:80 \
    -e USER_SERVICE=http://user-service:8080 \
    -e ORDER_SERVICE=http://order-service:8080 \
    api-gateway:latest
```

### 案例3：多网络隔离

```bash
# 创建前端网络
docker network create frontend

# 创建后端网络
docker network create backend

# 运行数据库（只在后端网络）
docker run -d \
    --name mysql \
    --network backend \
    mysql:8.0

# 运行应用（连接两个网络）
docker run -d \
    --name app \
    --network frontend \
    myapp

docker network connect backend app

# 运行 Nginx（只在前端网络）
docker run -d \
    --name nginx \
    --network frontend \
    -p 80:80 \
    nginx

# 结果：
# - Nginx 可以访问 app
# - app 可以访问 mysql
# - Nginx 不能直接访问 mysql（隔离）
```

---

## 10. 网络故障排查

### 10.1 常用排查命令

```bash
# 查看容器网络配置
docker exec container_name ip addr
docker exec container_name ip route

# 测试网络连通性
docker exec container_name ping google.com
docker exec container_name ping other_container

# 查看 DNS 配置
docker exec container_name cat /etc/resolv.conf

# 查看端口监听
docker exec container_name netstat -tlnp
docker exec container_name ss -tlnp

# 测试端口连通性
docker exec container_name telnet host port
docker exec container_name nc -zv host port
```

### 10.2 常见问题

**问题1：容器无法访问外网**
```bash
# 检查 DNS 配置
docker exec container_name cat /etc/resolv.conf

# 检查路由
docker exec container_name ip route

# 检查主机转发
sysctl net.ipv4.ip_forward

# 启用转发
sudo sysctl -w net.ipv4.ip_forward=1
```

**问题2：容器间无法通信**
```bash
# 检查是否在同一网络
docker network inspect network_name

# 检查防火墙规则
sudo iptables -L -n

# 测试连通性
docker exec container1 ping container2
```

**问题3：端口映射不生效**
```bash
# 检查端口映射
docker port container_name

# 检查容器是否监听端口
docker exec container_name netstat -tlnp

# 检查防火墙
sudo firewall-cmd --list-all
```

---

## 11. 网络性能优化

### 11.1 使用 host 网络

```bash
# 性能最优（无 NAT）
docker run -d --network host nginx
```

### 11.2 调整 MTU

```bash
# 创建网络时指定 MTU
docker network create \
    --opt com.docker.network.driver.mtu=9000 \
    mynet
```

### 11.3 禁用 iptables

```bash
# 配置 Docker daemon
# /etc/docker/daemon.json
{
  "iptables": false
}

# 重启 Docker
sudo systemctl restart docker
```

---

## 12. 练习题

### 练习1：基础网络
1. 创建自定义网络
2. 运行两个容器并连接到该网络
3. 测试容器间通信

### 练习2：端口映射
1. 运行 Nginx 容器并映射端口
2. 运行 MySQL 容器并映射端口
3. 从主机访问这些服务

### 练习3：多容器应用
1. 搭建 LNMP 架构
2. 配置容器间网络通信
3. 部署 WordPress 应用

### 练习4：网络隔离
1. 创建前端和后端网络
2. 实现网络隔离
3. 测试访问控制

---

## 📝 本节总结

### 核心要点

1. **网络模式**：bridge、host、none、container、overlay
2. **自定义网络**：支持容器名解析，更好的隔离
3. **端口映射**：-p 主机端口:容器端口
4. **容器互联**：使用自定义网络实现
5. **网络管理**：create、inspect、connect、disconnect

### 最佳实践

```
✅ 使用自定义网络代替默认 bridge
✅ 通过容器名而非 IP 通信
✅ 合理使用网络隔离
✅ 避免使用 --link（已废弃）
✅ 生产环境使用 host 网络提升性能
✅ 定期清理未使用的网络
```

### 下一步

学习完 Docker 网络后，继续学习：
- Docker 数据卷管理
- Docker Compose 编排
- Docker Swarm 集群

---

**掌握 Docker 网络，实现容器互联！** 🚀
