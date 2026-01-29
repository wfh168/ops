# Tomcat 集群架构

## 一、集群架构概述

### 1.1 为什么需要集群

**单机 Tomcat 的问题**：
- 单点故障：服务器宕机导致服务不可用
- 性能瓶颈：单台服务器处理能力有限
- 扩展困难：无法应对流量突增
- 维护困难：更新需要停机

**集群的优势**：
- 高可用：一台服务器故障不影响整体服务
- 高性能：多台服务器分担负载
- 可扩展：可以随时增加节点
- 易维护：可以滚动更新，不停机

### 1.2 集群架构设计

```
                    用户请求
                        |
                        ▼
                  [Nginx 负载均衡]
                        |
        +---------------+---------------+
        |               |               |
        ▼               ▼               ▼
    [Tomcat-1]      [Tomcat-2]      [Tomcat-3]
    8080端口        8080端口        8080端口
        |               |               |
        +---------------+---------------+
                        |
                        ▼
                  [Redis/Memcached]
                  (Session 共享)
                        |
                        ▼
                    [MySQL]
                    (数据库)
```

**架构说明**：
- **Nginx**：作为负载均衡器，分发请求到后端 Tomcat
- **Tomcat 集群**：多个 Tomcat 实例处理请求
- **Session 共享**：使用 Redis 或 Memcached 共享 Session
- **数据库**：所有 Tomcat 共享同一个数据库

---

## 二、多实例部署

### 2.1 单机多实例

在一台服务器上运行多个 Tomcat 实例。

#### 方法1：复制多个 Tomcat 目录

```bash
# 复制 Tomcat
cp -r /usr/local/tomcat /usr/local/tomcat1
cp -r /usr/local/tomcat /usr/local/tomcat2
cp -r /usr/local/tomcat /usr/local/tomcat3

# 修改端口（避免冲突）
# Tomcat1 使用默认端口 8080
# Tomcat2 修改为 8081
vim /usr/local/tomcat2/conf/server.xml
```

修改以下端口：
```xml
<!-- 关闭端口 -->
<Server port="8006" shutdown="SHUTDOWN">

<!-- HTTP 端口 -->
<Connector port="8081" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />

<!-- AJP 端口 -->
<Connector port="8010" protocol="AJP/1.3" redirectPort="8443" />
```

```bash
# Tomcat3 修改为 8082
vim /usr/local/tomcat3/conf/server.xml
```

修改端口：
```xml
<Server port="8007" shutdown="SHUTDOWN">
<Connector port="8082" protocol="HTTP/1.1" ... />
<Connector port="8011" protocol="AJP/1.3" ... />
```

启动所有实例：
```bash
/usr/local/tomcat1/bin/startup.sh
/usr/local/tomcat2/bin/startup.sh
/usr/local/tomcat3/bin/startup.sh

# 验证
netstat -tunlp | grep java
```

#### 方法2：使用环境变量（推荐）

```bash
# 创建实例目录
mkdir -p /data/tomcat/{tomcat1,tomcat2,tomcat3}

# 为每个实例创建必要的目录
for i in {1..3}; do
    mkdir -p /data/tomcat/tomcat$i/{conf,logs,temp,webapps,work}
    cp -r /usr/local/tomcat/conf/* /data/tomcat/tomcat$i/conf/
done

# 创建启动脚本
vim /data/tomcat/tomcat1/startup.sh
```

添加以下内容：
```bash
#!/bin/bash
export CATALINA_BASE=/data/tomcat/tomcat1
export CATALINA_HOME=/usr/local/tomcat
export CATALINA_PID=$CATALINA_BASE/tomcat.pid

$CATALINA_HOME/bin/catalina.sh start
```

```bash
# 设置执行权限
chmod +x /data/tomcat/tomcat1/startup.sh

# 修改端口配置
vim /data/tomcat/tomcat1/conf/server.xml
# 按照上面的方法修改端口

# 创建其他实例的启动脚本
# ...
```

### 2.2 多机部署

在多台服务器上部署 Tomcat。

**服务器规划**：
```
192.168.1.11  tomcat-01  # Tomcat 节点1
192.168.1.12  tomcat-02  # Tomcat 节点2
192.168.1.13  tomcat-03  # Tomcat 节点3
```

**部署步骤**：
```bash
# 在每台服务器上安装 JDK 和 Tomcat
# 使用相同的端口（8080）
# 部署相同的应用

# 在 tomcat-01 上
/usr/local/tomcat/bin/startup.sh

# 在 tomcat-02 上
/usr/local/tomcat/bin/startup.sh

# 在 tomcat-03 上
/usr/local/tomcat/bin/startup.sh
```

---

## 三、Nginx 负载均衡配置

### 3.1 安装 Nginx

```bash
# CentOS
yum install -y nginx

# Ubuntu
apt install -y nginx

# 或编译安装
cd /usr/local/src
wget http://nginx.org/download/nginx-1.20.2.tar.gz
tar -zxvf nginx-1.20.2.tar.gz
cd nginx-1.20.2
./configure --prefix=/usr/local/nginx
make && make install
```

### 3.2 配置负载均衡

```bash
vim /etc/nginx/nginx.conf
```

添加以下配置：
```nginx
http {
    # 定义 Tomcat 集群
    upstream tomcat_cluster {
        # 负载均衡算法：轮询（默认）
        server 192.168.1.11:8080 weight=1 max_fails=2 fail_timeout=30s;
        server 192.168.1.12:8080 weight=1 max_fails=2 fail_timeout=30s;
        server 192.168.1.13:8080 weight=1 max_fails=2 fail_timeout=30s;
        
        # 保持连接
        keepalive 32;
    }

    server {
        listen 80;
        server_name www.example.com;

        # 访问日志
        access_log /var/log/nginx/tomcat_access.log;
        error_log /var/log/nginx/tomcat_error.log;

        location / {
            # 代理到 Tomcat 集群
            proxy_pass http://tomcat_cluster;
            
            # 设置 Header
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # 超时设置
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
            
            # 缓冲设置
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }

        # 静态资源直接由 Nginx 处理
        location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
            proxy_pass http://tomcat_cluster;
            expires 30d;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 3.3 负载均衡算法

#### 1. 轮询（默认）

```nginx
upstream tomcat_cluster {
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
    server 192.168.1.13:8080;
}
```

#### 2. 加权轮询

```nginx
upstream tomcat_cluster {
    server 192.168.1.11:8080 weight=3;  # 权重3
    server 192.168.1.12:8080 weight=2;  # 权重2
    server 192.168.1.13:8080 weight=1;  # 权重1
}
```

#### 3. IP Hash（会话保持）

```nginx
upstream tomcat_cluster {
    ip_hash;  # 同一 IP 的请求分配到同一台服务器
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
    server 192.168.1.13:8080;
}
```

#### 4. 最少连接

```nginx
upstream tomcat_cluster {
    least_conn;  # 分配到连接数最少的服务器
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
    server 192.168.1.13:8080;
}
```

#### 5. 一致性哈希

```nginx
upstream tomcat_cluster {
    hash $request_uri consistent;  # 根据 URI 哈希
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
    server 192.168.1.13:8080;
}
```

### 3.4 服务器状态参数

```nginx
upstream tomcat_cluster {
    server 192.168.1.11:8080 weight=1 max_fails=2 fail_timeout=30s;
    server 192.168.1.12:8080 weight=1 max_fails=2 fail_timeout=30s backup;
    server 192.168.1.13:8080 weight=1 max_fails=2 fail_timeout=30s down;
}
```

**参数说明**：
- `weight`：权重，默认为 1
- `max_fails`：最大失败次数，默认为 1
- `fail_timeout`：失败超时时间，默认为 10s
- `backup`：备用服务器，只有其他服务器都不可用时才使用
- `down`：标记服务器不可用

---

## 四、健康检查

### 4.1 被动健康检查（默认）

Nginx 默认的健康检查机制。

```nginx
upstream tomcat_cluster {
    server 192.168.1.11:8080 max_fails=3 fail_timeout=30s;
    server 192.168.1.12:8080 max_fails=3 fail_timeout=30s;
    server 192.168.1.13:8080 max_fails=3 fail_timeout=30s;
}
```

**工作原理**：
- 当请求失败次数达到 `max_fails` 时，标记服务器为不可用
- 在 `fail_timeout` 时间内不再向该服务器发送请求
- `fail_timeout` 时间后，再次尝试该服务器

### 4.2 主动健康检查（需要商业版或第三方模块）

#### 使用 nginx_upstream_check_module

```bash
# 下载模块
cd /usr/local/src
git clone https://github.com/yaoweibin/nginx_upstream_check_module.git

# 重新编译 Nginx
cd nginx-1.20.2
patch -p1 < /usr/local/src/nginx_upstream_check_module/check_1.20.1+.patch
./configure --prefix=/usr/local/nginx --add-module=/usr/local/src/nginx_upstream_check_module
make && make install
```

配置健康检查：
```nginx
upstream tomcat_cluster {
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
    server 192.168.1.13:8080;
    
    # 健康检查配置
    check interval=3000 rise=2 fall=3 timeout=1000 type=http;
    check_http_send "HEAD / HTTP/1.0\r\n\r\n";
    check_http_expect_alive http_2xx http_3xx;
}

server {
    listen 80;
    
    # 健康检查状态页面
    location /status {
        check_status;
        access_log off;
    }
}
```

**参数说明**：
- `interval`：检查间隔（毫秒）
- `rise`：连续成功次数后标记为可用
- `fall`：连续失败次数后标记为不可用
- `timeout`：检查超时时间（毫秒）
- `type`：检查类型（http、tcp、ssl_hello 等）

访问健康检查页面：
```
http://nginx服务器IP/status
```

### 4.3 自定义健康检查脚本

```bash
vim /usr/local/scripts/check_tomcat.sh
```

添加以下内容：
```bash
#!/bin/bash

TOMCAT_SERVERS=(
    "192.168.1.11:8080"
    "192.168.1.12:8080"
    "192.168.1.13:8080"
)

for server in "${TOMCAT_SERVERS[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://$server/)
    
    if [ "$status" == "200" ]; then
        echo "$(date) - $server is UP"
    else
        echo "$(date) - $server is DOWN (HTTP $status)"
        # 发送告警
        # mail -s "Tomcat Down" admin@example.com <<< "$server is down"
    fi
done
```

```bash
# 设置执行权限
chmod +x /usr/local/scripts/check_tomcat.sh

# 添加到 crontab
crontab -e

# 每分钟检查一次
* * * * * /usr/local/scripts/check_tomcat.sh >> /var/log/tomcat_check.log 2>&1
```

---

## 五、故障转移测试

### 5.1 测试负载均衡

```bash
# 在每个 Tomcat 的 webapps/ROOT 下创建测试页面
# Tomcat-1
echo "This is Tomcat-1" > /usr/local/tomcat/webapps/ROOT/index.html

# Tomcat-2
echo "This is Tomcat-2" > /usr/local/tomcat/webapps/ROOT/index.html

# Tomcat-3
echo "This is Tomcat-3" > /usr/local/tomcat/webapps/ROOT/index.html

# 多次访问 Nginx
for i in {1..10}; do
    curl http://nginx服务器IP/
done
```

你应该看到请求被分配到不同的 Tomcat 服务器。

### 5.2 测试故障转移

```bash
# 停止 Tomcat-1
ssh 192.168.1.11 "/usr/local/tomcat/bin/shutdown.sh"

# 继续访问
for i in {1..10}; do
    curl http://nginx服务器IP/
done
```

你应该看到请求只分配到 Tomcat-2 和 Tomcat-3。

```bash
# 重新启动 Tomcat-1
ssh 192.168.1.11 "/usr/local/tomcat/bin/startup.sh"

# 等待几秒后再次访问
sleep 30
for i in {1..10}; do
    curl http://nginx服务器IP/
done
```

Tomcat-1 应该重新加入负载均衡。

---

## 六、监控和日志

### 6.1 Nginx 访问日志分析

```bash
# 查看访问最多的 IP
awk '{print $1}' /var/log/nginx/tomcat_access.log | sort | uniq -c | sort -rn | head -10

# 查看访问最多的 URL
awk '{print $7}' /var/log/nginx/tomcat_access.log | sort | uniq -c | sort -rn | head -10

# 查看响应状态码分布
awk '{print $9}' /var/log/nginx/tomcat_access.log | sort | uniq -c | sort -rn

# 查看后端服务器响应时间
awk '{print $NF}' /var/log/nginx/tomcat_access.log | sort -n | tail -10
```

### 6.2 Tomcat 监控

```bash
# 查看 Tomcat 进程
ps aux | grep tomcat

# 查看 Tomcat 内存使用
jmap -heap <PID>

# 查看线程数
jstack <PID> | grep "java.lang.Thread.State" | wc -l

# 查看 GC 情况
jstat -gc <PID> 1000 10
```

### 6.3 集群监控脚本

```bash
vim /usr/local/scripts/monitor_cluster.sh
```

添加以下内容：
```bash
#!/bin/bash

echo "=== Tomcat Cluster Status ==="
echo "Time: $(date)"
echo ""

# 检查 Nginx
echo "Nginx Status:"
systemctl status nginx | grep Active
echo ""

# 检查 Tomcat 节点
TOMCAT_SERVERS=(
    "192.168.1.11:8080"
    "192.168.1.12:8080"
    "192.168.1.13:8080"
)

echo "Tomcat Nodes:"
for server in "${TOMCAT_SERVERS[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://$server/ --connect-timeout 5)
    if [ "$status" == "200" ]; then
        echo "  $server: UP"
    else
        echo "  $server: DOWN"
    fi
done
echo ""

# 检查连接数
echo "Nginx Connections:"
ss -s | grep TCP
echo ""

# 检查负载
echo "System Load:"
uptime
```

```bash
chmod +x /usr/local/scripts/monitor_cluster.sh

# 定时执行
crontab -e
*/5 * * * * /usr/local/scripts/monitor_cluster.sh >> /var/log/cluster_monitor.log 2>&1
```

---

## 七、实战练习

### 练习1：搭建 3 节点集群

1. 准备 3 台服务器（或虚拟机）
2. 在每台服务器上安装 JDK 和 Tomcat
3. 部署相同的测试应用
4. 配置 Nginx 负载均衡
5. 测试负载均衡效果

### 练习2：测试故障转移

1. 停止其中一个 Tomcat 节点
2. 观察 Nginx 是否自动将请求转发到其他节点
3. 重新启动该节点
4. 验证节点是否重新加入集群

### 练习3：性能测试

1. 使用 ab 或 JMeter 进行压力测试
2. 对比单机和集群的性能差异
3. 调整负载均衡算法，观察效果
4. 记录测试结果

---

## 八、总结

本节学习了：

✅ 集群架构设计  
✅ 单机多实例和多机部署  
✅ Nginx 负载均衡配置  
✅ 多种负载均衡算法  
✅ 健康检查机制  
✅ 故障转移测试  
✅ 集群监控方法  

**下一节**：学习 Session 共享和 Tomcat 性能优化。

---

## 参考资料

- [Nginx 负载均衡文档](http://nginx.org/en/docs/http/load_balancing.html)
- [Tomcat 集群配置](https://tomcat.apache.org/tomcat-9.0-doc/cluster-howto.html)
- [nginx_upstream_check_module](https://github.com/yaoweibin/nginx_upstream_check_module)
