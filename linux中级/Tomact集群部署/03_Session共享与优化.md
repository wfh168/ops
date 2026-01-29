# Session 共享与优化

## 一、Session 共享概述

### 1.1 为什么需要 Session 共享

在 Tomcat 集群环境中，用户的请求可能被分配到不同的服务器，如果不共享 Session，会导致：

**问题场景**：
```
用户登录 → 请求到 Tomcat-1 → Session 存储在 Tomcat-1
用户刷新 → 请求到 Tomcat-2 → Tomcat-2 没有 Session → 需要重新登录
```

**解决方案**：
1. **Session 粘性（Sticky Session）**：同一用户的请求始终分配到同一台服务器
2. **Session 复制**：Tomcat 之间相互复制 Session
3. **Session 集中存储**：使用 Redis/Memcached 统一存储 Session ⭐推荐

### 1.2 Session 共享方案对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| Session 粘性 | 简单，无需修改代码 | 单点故障，负载不均 | 小型应用 |
| Session 复制 | 无单点故障 | 性能差，网络开销大 | 节点少的集群 |
| Redis 共享 | 高性能，高可用 | 需要额外的 Redis 服务 | 大型应用 ⭐ |
| Memcached 共享 | 高性能 | 数据可能丢失 | 对数据一致性要求不高 |

---

## 二、Session 粘性（IP Hash）

### 2.1 Nginx 配置

```bash
vim /etc/nginx/nginx.conf
```

添加以下配置：
```nginx
upstream tomcat_cluster {
    ip_hash;  # 启用 IP Hash
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
    server 192.168.1.13:8080;
}

server {
    listen 80;
    server_name www.example.com;

    location / {
        proxy_pass http://tomcat_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# 重新加载配置
nginx -t
nginx -s reload
```

### 2.2 测试 Session 粘性

创建测试 JSP：
```bash
vim /usr/local/tomcat/webapps/ROOT/session_test.jsp
```

添加以下内容：
```jsp
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String serverInfo = application.getServerInfo();
    String sessionId = session.getId();
    Integer count = (Integer) session.getAttribute("count");
    if (count == null) {
        count = 1;
    } else {
        count++;
    }
    session.setAttribute("count", count);
%>
<!DOCTYPE html>
<html>
<head>
    <title>Session 测试</title>
</head>
<body>
    <h1>Session 粘性测试</h1>
    <p>服务器信息：<%= serverInfo %></p>
    <p>Session ID：<%= sessionId %></p>
    <p>访问次数：<%= count %></p>
    <p>当前时间：<%= new java.util.Date() %></p>
</body>
</html>
```

多次刷新页面，观察 Session ID 和访问次数。

**优点**：
- 配置简单
- 无需修改应用代码

**缺点**：
- 如果某台服务器宕机，该服务器上的 Session 会丢失
- 负载可能不均衡（某些 IP 访问量大）

---

## 三、Redis Session 共享

### 3.1 安装 Redis

```bash
# CentOS
yum install -y redis

# 或编译安装
cd /usr/local/src
wget http://download.redis.io/releases/redis-6.2.6.tar.gz
tar -zxvf redis-6.2.6.tar.gz
cd redis-6.2.6
make && make install

# 配置 Redis
vim /etc/redis.conf
```

修改以下配置：
```conf
# 绑定所有网卡
bind 0.0.0.0

# 设置密码
requirepass your_password

# 持久化
save 900 1
save 300 10
save 60 10000

# 最大内存
maxmemory 2gb
maxmemory-policy allkeys-lru
```

```bash
# 启动 Redis
systemctl start redis
systemctl enable redis

# 测试连接
redis-cli -h 192.168.1.14 -a your_password ping
```

### 3.2 方案1：使用 Tomcat Redis Session Manager

#### 下载依赖 JAR 包

```bash
cd /usr/local/tomcat/lib

# 下载 Redis Session Manager
wget https://github.com/jcoleman/tomcat-redis-session-manager/releases/download/2.0.0/tomcat-redis-session-manager-2.0.0.jar

# 下载 Jedis（Redis Java 客户端）
wget https://repo1.maven.org/maven2/redis/clients/jedis/3.6.3/jedis-3.6.3.jar

# 下载 Apache Commons Pool
wget https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/2.11.1/commons-pool2-2.11.1.jar
```

#### 配置 Tomcat

```bash
vim /usr/local/tomcat/conf/context.xml
```

在 `<Context>` 标签内添加：
```xml
<Valve className="com.orangefunction.tomcat.redissessions.RedisSessionHandlerValve" />
<Manager className="com.orangefunction.tomcat.redissessions.RedisSessionManager"
         host="192.168.1.14"
         port="6379"
         password="your_password"
         database="0"
         maxInactiveInterval="1800" />
```

#### 重启 Tomcat

```bash
/usr/local/tomcat/bin/shutdown.sh
/usr/local/tomcat/bin/startup.sh
```

### 3.3 方案2：使用 Spring Session（推荐）

#### 添加 Maven 依赖

```xml
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-redis</artifactId>
    <version>2.7.0</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>io.lettuce</groupId>
    <artifactId>lettuce-core</artifactId>
</dependency>
```

#### 配置 application.properties

```properties
# Redis 配置
spring.redis.host=192.168.1.14
spring.redis.port=6379
spring.redis.password=your_password
spring.redis.database=0

# Session 配置
spring.session.store-type=redis
spring.session.timeout=1800s
server.servlet.session.timeout=30m

# Redis 连接池
spring.redis.lettuce.pool.max-active=8
spring.redis.lettuce.pool.max-idle=8
spring.redis.lettuce.pool.min-idle=0
spring.redis.lettuce.pool.max-wait=-1ms
```

#### 启用 Spring Session

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.session.data.redis.config.annotation.web.http.EnableRedisHttpSession;

@Configuration
@EnableRedisHttpSession(maxInactiveIntervalInSeconds = 1800)
public class SessionConfig {
    // Spring Session 会自动配置
}
```

### 3.4 测试 Redis Session 共享

创建测试接口：
```java
@RestController
public class SessionController {
    
    @GetMapping("/set-session")
    public String setSession(HttpSession session) {
        session.setAttribute("user", "admin");
        session.setAttribute("loginTime", new Date());
        return "Session 已设置，Session ID: " + session.getId();
    }
    
    @GetMapping("/get-session")
    public Map<String, Object> getSession(HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        result.put("sessionId", session.getId());
        result.put("user", session.getAttribute("user"));
        result.put("loginTime", session.getAttribute("loginTime"));
        result.put("serverInfo", System.getProperty("server.info"));
        return result;
    }
}
```

测试步骤：
```bash
# 1. 设置 Session
curl http://nginx服务器IP/set-session

# 2. 多次获取 Session（观察是否在不同服务器上都能获取到）
for i in {1..10}; do
    curl http://nginx服务器IP/get-session
    echo ""
done

# 3. 在 Redis 中查看 Session
redis-cli -h 192.168.1.14 -a your_password
> keys *
> get "spring:session:sessions:xxxxx"
```

---

## 四、Tomcat 性能优化

### 4.1 JVM 参数优化

```bash
vim /usr/local/tomcat/bin/catalina.sh
```

在文件开头添加：
```bash
# JVM 内存设置
JAVA_OPTS="$JAVA_OPTS -Xms2048m"           # 初始堆内存
JAVA_OPTS="$JAVA_OPTS -Xmx2048m"           # 最大堆内存
JAVA_OPTS="$JAVA_OPTS -Xmn1024m"           # 年轻代大小
JAVA_OPTS="$JAVA_OPTS -XX:MetaspaceSize=256m"      # 元空间初始大小
JAVA_OPTS="$JAVA_OPTS -XX:MaxMetaspaceSize=512m"   # 元空间最大大小

# GC 设置（使用 G1 垃圾回收器）
JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC"
JAVA_OPTS="$JAVA_OPTS -XX:MaxGCPauseMillis=200"
JAVA_OPTS="$JAVA_OPTS -XX:G1HeapRegionSize=16m"

# GC 日志
JAVA_OPTS="$JAVA_OPTS -Xloggc:$CATALINA_BASE/logs/gc.log"
JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCDetails"
JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCDateStamps"
JAVA_OPTS="$JAVA_OPTS -XX:+UseGCLogFileRotation"
JAVA_OPTS="$JAVA_OPTS -XX:NumberOfGCLogFiles=10"
JAVA_OPTS="$JAVA_OPTS -XX:GCLogFileSize=100M"

# 其他优化
JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError"
JAVA_OPTS="$JAVA_OPTS -XX:HeapDumpPath=$CATALINA_BASE/logs/heapdump.hprof"
JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"
JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=UTF-8"
```

**参数说明**：
- `-Xms`：初始堆内存，建议与 -Xmx 相同
- `-Xmx`：最大堆内存，一般设置为物理内存的 70-80%
- `-Xmn`：年轻代大小，一般为堆内存的 1/3 到 1/2
- `-XX:MetaspaceSize`：元空间大小（JDK 8+）
- `-XX:+UseG1GC`：使用 G1 垃圾回收器（推荐）

### 4.2 Connector 优化

```bash
vim /usr/local/tomcat/conf/server.xml
```

优化 Connector 配置：
```xml
<Connector port="8080" protocol="org.apache.coyote.http11.Http11NioProtocol"
           connectionTimeout="20000"
           redirectPort="8443"
           maxThreads="500"
           minSpareThreads="50"
           maxConnections="10000"
           acceptCount="100"
           enableLookups="false"
           compression="on"
           compressionMinSize="2048"
           compressableMimeType="text/html,text/xml,text/plain,text/css,text/javascript,application/javascript,application/json"
           URIEncoding="UTF-8" />
```

**参数说明**：
- `protocol`：使用 NIO 协议（性能更好）
- `maxThreads`：最大线程数，根据并发量调整
- `minSpareThreads`：最小空闲线程数
- `maxConnections`：最大连接数
- `acceptCount`：等待队列长度
- `enableLookups`：禁用 DNS 查询（提高性能）
- `compression`：启用压缩
- `URIEncoding`：URI 编码

### 4.3 线程池优化

```xml
<!-- 在 server.xml 中添加 Executor -->
<Executor name="tomcatThreadPool"
          namePrefix="catalina-exec-"
          maxThreads="500"
          minSpareThreads="50"
          maxIdleTime="60000"
          prestartminSpareThreads="true"
          maxQueueSize="100" />

<!-- Connector 使用 Executor -->
<Connector executor="tomcatThreadPool"
           port="8080"
           protocol="org.apache.coyote.http11.Http11NioProtocol"
           connectionTimeout="20000"
           redirectPort="8443" />
```

### 4.4 静态资源优化

```xml
<!-- 在 conf/web.xml 中配置默认 Servlet -->
<servlet>
    <servlet-name>default</servlet-name>
    <servlet-class>org.apache.catalina.servlets.DefaultServlet</servlet-class>
    <init-param>
        <param-name>listings</param-name>
        <param-value>false</param-value>
    </init-param>
    <init-param>
        <param-name>gzip</param-name>
        <param-value>true</param-value>
    </init-param>
    <init-param>
        <param-name>sendfileSize</param-name>
        <param-value>1024</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>
```

### 4.5 数据库连接池优化

使用 HikariCP（性能最好的连接池）：

```xml
<!-- pom.xml -->
<dependency>
    <groupId>com.zaxxer</groupId>
    <artifactId>HikariCP</artifactId>
    <version>5.0.1</version>
</dependency>
```

```properties
# application.properties
spring.datasource.type=com.zaxxer.hikari.HikariDataSource
spring.datasource.hikari.minimum-idle=10
spring.datasource.hikari.maximum-pool-size=50
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.connection-test-query=SELECT 1
```

---

## 五、监控和日志分析

### 5.1 JVM 监控

#### 使用 jstat

```bash
# 查看 GC 情况
jstat -gc <PID> 1000 10

# 查看 GC 统计
jstat -gcutil <PID> 1000 10

# 查看类加载
jstat -class <PID>
```

#### 使用 jmap

```bash
# 查看堆内存使用
jmap -heap <PID>

# 生成堆转储文件
jmap -dump:format=b,file=heap.hprof <PID>

# 查看对象统计
jmap -histo <PID> | head -20
```

#### 使用 jstack

```bash
# 查看线程堆栈
jstack <PID> > thread_dump.txt

# 查看死锁
jstack -l <PID> | grep -A 10 "deadlock"
```

### 5.2 Tomcat 监控

#### 启用 JMX

```bash
vim /usr/local/tomcat/bin/catalina.sh
```

添加以下内容：
```bash
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=9999"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
CATALINA_OPTS="$CATALINA_OPTS -Djava.rmi.server.hostname=192.168.1.11"
```

使用 JConsole 或 VisualVM 连接：
```
服务：192.168.1.11:9999
```

#### 启用 Manager 应用

访问：`http://服务器IP:8080/manager/status`

查看：
- 服务器状态
- JVM 内存使用
- 线程信息
- 请求统计

### 5.3 性能测试

#### 使用 Apache Bench

```bash
# 安装 ab
yum install -y httpd-tools

# 测试
ab -n 10000 -c 100 http://nginx服务器IP/

# 参数说明：
# -n：总请求数
# -c：并发数
```

#### 使用 JMeter

1. 下载 JMeter：https://jmeter.apache.org/
2. 创建测试计划
3. 添加线程组（模拟用户）
4. 添加 HTTP 请求
5. 添加监听器（查看结果）
6. 运行测试

**测试场景**：
```
线程数：1000
Ramp-Up 时间：10 秒
循环次数：10
```

---

## 六、故障排查

### 6.1 常见问题

#### 问题1：Session 丢失

**排查步骤**：
```bash
# 1. 检查 Redis 连接
redis-cli -h 192.168.1.14 -a your_password ping

# 2. 查看 Redis 中的 Session
redis-cli -h 192.168.1.14 -a your_password
> keys *session*

# 3. 检查 Tomcat 日志
tail -f /usr/local/tomcat/logs/catalina.out | grep -i session

# 4. 检查 Session 超时配置
grep -r "session-timeout" /usr/local/tomcat/conf/
```

#### 问题2：内存溢出

**排查步骤**：
```bash
# 1. 查看 GC 日志
tail -f /usr/local/tomcat/logs/gc.log

# 2. 生成堆转储
jmap -dump:format=b,file=heap.hprof <PID>

# 3. 使用 MAT 分析堆转储文件
# 下载 Eclipse Memory Analyzer Tool

# 4. 调整 JVM 参数
vim /usr/local/tomcat/bin/catalina.sh
```

#### 问题3：响应慢

**排查步骤**：
```bash
# 1. 查看线程状态
jstack <PID> > thread.txt

# 2. 查看数据库连接
# 检查慢查询日志

# 3. 查看 Nginx 日志
tail -f /var/log/nginx/tomcat_access.log

# 4. 使用 JProfiler 或 YourKit 进行性能分析
```

---

## 七、实战练习

### 练习1：配置 Redis Session 共享

1. 安装 Redis 服务器
2. 配置 Tomcat 使用 Redis 存储 Session
3. 部署测试应用
4. 验证 Session 共享效果

### 练习2：JVM 调优

1. 配置 JVM 参数
2. 启用 GC 日志
3. 进行压力测试
4. 分析 GC 日志并优化

### 练习3：性能测试

1. 使用 JMeter 创建测试计划
2. 模拟 1000 并发用户
3. 测试单机和集群的性能差异
4. 记录并分析测试结果

---

## 八、总结

本节学习了：

✅ Session 共享的必要性和方案对比  
✅ Session 粘性配置  
✅ Redis Session 共享实现  
✅ JVM 参数优化  
✅ Tomcat Connector 优化  
✅ 监控和性能测试  
✅ 常见问题排查  

**恭喜你完成了 Tomcat 集群部署的学习！**

---

## 参考资料

- [Tomcat 性能调优](https://tomcat.apache.org/tomcat-9.0-doc/performance.html)
- [Spring Session 文档](https://docs.spring.io/spring-session/docs/current/reference/html5/)
- [Redis 官方文档](https://redis.io/documentation)
- [JVM 调优指南](https://docs.oracle.com/javase/8/docs/technotes/guides/vm/gctuning/)
