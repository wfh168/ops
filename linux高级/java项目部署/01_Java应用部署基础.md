# Java 应用部署基础

## 一、Java 应用架构概述

### 1.1 Java 应用类型

**传统 Java Web 应用**：
- WAR 包部署到应用服务器（Tomcat、Jetty）
- 依赖外部容器
- 配置复杂

**Spring Boot 应用**：
- 内嵌 Web 服务器
- 独立运行的 JAR 包
- 配置简单
- 推荐方式

**微服务应用**：
- 多个独立的 Spring Boot 服务
- 服务注册与发现
- API 网关
- 配置中心

### 1.2 典型架构

```
                    用户请求
                       ↓
                  [Nginx 负载均衡]
                       ↓
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
   [应用服务器1]  [应用服务器2]  [应用服务器3]
        ↓              ↓              ↓
        └──────────────┼──────────────┘
                       ↓
                  [Redis 缓存]
                       ↓
                  [MySQL 数据库]
```

---

## 二、JDK 环境配置

### 2.1 安装 JDK

#### CentOS/RHEL

```bash
# 安装 OpenJDK 11
sudo yum install -y java-11-openjdk java-11-openjdk-devel

# 安装 OpenJDK 17
sudo yum install -y java-17-openjdk java-17-openjdk-devel

# 验证安装
java -version
javac -version
```

#### Ubuntu/Debian

```bash
# 更新包列表
sudo apt update

# 安装 OpenJDK 11
sudo apt install -y openjdk-11-jdk

# 安装 OpenJDK 17
sudo apt install -y openjdk-17-jdk

# 验证安装
java -version
```

### 2.2 配置环境变量

```bash
# 编辑 profile
sudo vim /etc/profile

# 添加以下内容
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib
export PATH=$JAVA_HOME/bin:$PATH

# 使配置生效
source /etc/profile

# 验证
echo $JAVA_HOME
```

### 2.3 多版本 JDK 管理

```bash
# 查看已安装的 JDK
sudo update-alternatives --config java

# 切换 JDK 版本
sudo update-alternatives --set java /usr/lib/jvm/java-11-openjdk/bin/java

# 设置默认 JDK
sudo update-alternatives --install /usr/bin/java java \
  /usr/lib/jvm/java-11-openjdk/bin/java 1

sudo update-alternatives --install /usr/bin/javac javac \
  /usr/lib/jvm/java-11-openjdk/bin/javac 1
```

---

## 三、Maven 构建工具

### 3.1 安装 Maven

```bash
# 下载 Maven
cd /opt
sudo wget https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz

# 解压
sudo tar -xzf apache-maven-3.9.5-bin.tar.gz
sudo mv apache-maven-3.9.5 maven

# 配置环境变量
sudo vim /etc/profile

# 添加
export MAVEN_HOME=/opt/maven
export PATH=$MAVEN_HOME/bin:$PATH

# 生效
source /etc/profile

# 验证
mvn -version
```

### 3.2 配置 Maven

```bash
# 编辑 settings.xml
vim /opt/maven/conf/settings.xml
```

**配置本地仓库**：
```xml
<localRepository>/data/maven/repository</localRepository>
```

**配置阿里云镜像**：
```xml
<mirrors>
  <mirror>
    <id>aliyun</id>
    <mirrorOf>central</mirrorOf>
    <name>Aliyun Maven</name>
    <url>https://maven.aliyun.com/repository/public</url>
  </mirror>
</mirrors>
```

### 3.3 Maven 常用命令

```bash
# 清理
mvn clean

# 编译
mvn compile

# 测试
mvn test

# 打包
mvn package

# 安装到本地仓库
mvn install

# 部署到远程仓库
mvn deploy

# 跳过测试打包
mvn clean package -DskipTests

# 指定环境打包
mvn clean package -P prod
```

---

## 四、Spring Boot 应用部署

### 4.1 创建 Spring Boot 应用

**pom.xml**：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.7.14</version>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>myapp</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <java.version>11</java.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

### 4.2 构建应用

```bash
# 克隆代码
git clone https://github.com/user/myapp.git
cd myapp

# 构建
mvn clean package

# 查看构建产物
ls -lh target/
# myapp-1.0.0.jar
```

### 4.3 运行 Spring Boot 应用

#### 方式1：直接运行

```bash
# 前台运行
java -jar target/myapp-1.0.0.jar

# 后台运行
nohup java -jar target/myapp-1.0.0.jar > app.log 2>&1 &

# 指定端口
java -jar target/myapp-1.0.0.jar --server.port=8081

# 指定配置文件
java -jar target/myapp-1.0.0.jar --spring.config.location=/etc/myapp/application.yml
```

#### 方式2：使用 systemd 管理

```bash
# 创建服务文件
sudo vim /etc/systemd/system/myapp.service
```

```ini
[Unit]
Description=My Spring Boot Application
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/java -jar /opt/myapp/myapp-1.0.0.jar
ExecStop=/bin/kill -15 $MAINPID
Restart=on-failure
RestartSec=10

# JVM 参数
Environment="JAVA_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC"

# 应用参数
Environment="SPRING_PROFILES_ACTIVE=prod"

[Install]
WantedBy=multi-user.target
```

```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start myapp

# 设置开机自启
sudo systemctl enable myapp

# 查看状态
sudo systemctl status myapp

# 查看日志
sudo journalctl -u myapp -f
```

#### 方式3：使用启动脚本

```bash
# 创建启动脚本
vim /opt/myapp/start.sh
```

```bash
#!/bin/bash

APP_NAME="myapp"
APP_JAR="/opt/myapp/myapp-1.0.0.jar"
APP_LOG="/var/log/myapp/app.log"
PID_FILE="/var/run/myapp.pid"

# JVM 参数
JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"
JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError"
JAVA_OPTS="$JAVA_OPTS -XX:HeapDumpPath=/var/log/myapp/heapdump.hprof"

# Spring Boot 参数
SPRING_OPTS="--spring.profiles.active=prod"
SPRING_OPTS="$SPRING_OPTS --server.port=8080"

case "$1" in
  start)
    echo "Starting $APP_NAME..."
    nohup java $JAVA_OPTS -jar $APP_JAR $SPRING_OPTS > $APP_LOG 2>&1 &
    echo $! > $PID_FILE
    echo "$APP_NAME started."
    ;;
  
  stop)
    echo "Stopping $APP_NAME..."
    if [ -f $PID_FILE ]; then
      PID=$(cat $PID_FILE)
      kill $PID
      rm $PID_FILE
      echo "$APP_NAME stopped."
    else
      echo "$APP_NAME is not running."
    fi
    ;;
  
  restart)
    $0 stop
    sleep 2
    $0 start
    ;;
  
  status)
    if [ -f $PID_FILE ]; then
      PID=$(cat $PID_FILE)
      if ps -p $PID > /dev/null; then
        echo "$APP_NAME is running (PID: $PID)"
      else
        echo "$APP_NAME is not running (stale PID file)"
      fi
    else
      echo "$APP_NAME is not running"
    fi
    ;;
  
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0
```

```bash
# 赋予执行权限
chmod +x /opt/myapp/start.sh

# 使用脚本
/opt/myapp/start.sh start
/opt/myapp/start.sh stop
/opt/myapp/start.sh restart
/opt/myapp/start.sh status
```

### 4.4 JVM 参数优化

```bash
# 基本参数
java -Xms2g -Xmx2g \
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -jar myapp.jar

# 完整参数
java \
  # 堆内存
  -Xms2g \
  -Xmx2g \
  -Xmn1g \
  
  # 垃圾回收器
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:G1HeapRegionSize=16m \
  
  # GC 日志
  -Xlog:gc*:file=/var/log/myapp/gc.log:time,uptime:filecount=10,filesize=100m \
  
  # OOM 处理
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/var/log/myapp/heapdump.hprof \
  -XX:OnOutOfMemoryError="kill -9 %p" \
  
  # JMX 监控
  -Dcom.sun.management.jmxremote \
  -Dcom.sun.management.jmxremote.port=9999 \
  -Dcom.sun.management.jmxremote.authenticate=false \
  -Dcom.sun.management.jmxremote.ssl=false \
  
  -jar myapp.jar
```

---

## 五、配置文件管理

### 5.1 多环境配置

**application.yml**（默认配置）：
```yaml
spring:
  application:
    name: myapp
  profiles:
    active: @spring.profiles.active@

server:
  port: 8080
```

**application-dev.yml**（开发环境）：
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/myapp_dev
    username: dev_user
    password: dev_pass

logging:
  level:
    root: DEBUG
```

**application-prod.yml**（生产环境）：
```yaml
spring:
  datasource:
    url: jdbc:mysql://db.example.com:3306/myapp_prod
    username: prod_user
    password: ${DB_PASSWORD}

logging:
  level:
    root: INFO
  file:
    name: /var/log/myapp/app.log
```

### 5.2 外部配置

```bash
# 方式1：命令行参数
java -jar myapp.jar --spring.profiles.active=prod

# 方式2：环境变量
export SPRING_PROFILES_ACTIVE=prod
java -jar myapp.jar

# 方式3：外部配置文件
java -jar myapp.jar --spring.config.location=/etc/myapp/application.yml

# 方式4：配置目录
java -jar myapp.jar --spring.config.location=/etc/myapp/
```

### 5.3 敏感信息管理

```bash
# 使用环境变量
export DB_PASSWORD=secret_password
export REDIS_PASSWORD=secret_redis_pass

# 在配置文件中引用
spring:
  datasource:
    password: ${DB_PASSWORD}
  redis:
    password: ${REDIS_PASSWORD}
```

---

## 六、传统 WAR 包部署

### 6.1 创建 WAR 包项目

**pom.xml**：
```xml
<packaging>war</packaging>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- 排除内嵌 Tomcat -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-tomcat</artifactId>
        <scope>provided</scope>
    </dependency>
</dependencies>
```

**Application.java**：
```java
@SpringBootApplication
public class Application extends SpringBootServletInitializer {
    
    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(Application.class);
    }
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### 6.2 构建和部署

```bash
# 构建 WAR 包
mvn clean package

# 部署到 Tomcat
cp target/myapp.war /opt/tomcat/webapps/

# 重启 Tomcat
/opt/tomcat/bin/shutdown.sh
/opt/tomcat/bin/startup.sh

# 访问应用
http://localhost:8080/myapp
```

---

## 七、数据库配置

### 7.1 MySQL 配置

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/myapp?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
    
    # 连接池配置（HikariCP）
    hikari:
      minimum-idle: 5
      maximum-pool-size: 20
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      connection-test-query: SELECT 1
```

### 7.2 Redis 配置

```yaml
spring:
  redis:
    host: localhost
    port: 6379
    password: 
    database: 0
    timeout: 3000
    
    # Lettuce 连接池
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0
        max-wait: -1ms
```

---

## 八、实战练习

### 练习1：部署 Spring Boot 应用

1. 创建简单的 Spring Boot 应用
2. 使用 Maven 构建
3. 使用 systemd 管理服务
4. 配置多环境

### 练习2：JVM 调优

1. 配置合适的堆内存
2. 选择合适的垃圾回收器
3. 配置 GC 日志
4. 配置 OOM 处理

### 练习3：配置管理

1. 创建多环境配置文件
2. 使用外部配置
3. 管理敏感信息

---

## 九、总结

本节学习了：

✅ Java 应用架构  
✅ JDK 环境配置  
✅ Maven 构建工具  
✅ Spring Boot 应用部署  
✅ JVM 参数优化  
✅ 配置文件管理  
✅ 传统 WAR 包部署  
✅ 数据库配置  

**下一节**：学习应用服务器配置和负载均衡。
