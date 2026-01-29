# Tomcat 基础与安装

## 一、Tomcat 简介

### 1.1 什么是 Tomcat

Tomcat 是 Apache 软件基金会的一个开源项目，是一个轻量级的 Java Web 应用服务器。

**核心特点**：
- 免费开源
- 轻量级、高性能
- 支持 Servlet 和 JSP 规范
- 跨平台（Java 编写）
- 广泛应用于企业级应用

### 1.2 Tomcat 架构

```
                    Tomcat 架构
                        |
        +---------------+---------------+
        |                               |
    [Server]                        [Service]
        |                               |
    [Connector]                     [Engine]
        |                               |
    [HTTP/AJP]                       [Host]
                                        |
                                    [Context]
                                        |
                                    [Servlet]
```

**核心组件**：
- **Server**：Tomcat 实例，一个 JVM 一个 Server
- **Service**：服务，包含 Connector 和 Engine
- **Connector**：连接器，处理客户端请求
- **Engine**：引擎，处理请求的核心
- **Host**：虚拟主机
- **Context**：Web 应用上下文

### 1.3 Tomcat vs 其他服务器

| 特性 | Tomcat | Jetty | JBoss/WildFly | WebLogic |
|------|--------|-------|---------------|----------|
| 类型 | Servlet 容器 | Servlet 容器 | 应用服务器 | 应用服务器 |
| 重量级 | 轻量 | 轻量 | 中等 | 重量 |
| 启动速度 | 快 | 很快 | 中等 | 慢 |
| 内存占用 | 小 | 很小 | 中等 | 大 |
| 企业功能 | 基础 | 基础 | 完整 | 完整 |
| 适用场景 | 中小型应用 | 嵌入式 | 企业应用 | 大型企业 |

---

## 二、环境准备

### 2.1 系统要求

**最低配置**：
- CPU：1核
- 内存：1GB
- 硬盘：10GB
- 操作系统：Linux/Windows/macOS

**推荐配置**：
- CPU：2核+
- 内存：4GB+
- 硬盘：50GB+
- 操作系统：CentOS 7/8、Ubuntu 18.04+

### 2.2 安装 JDK

Tomcat 需要 Java 运行环境。

#### 方法1：使用 yum 安装（CentOS）

```bash
# 查看可用的 JDK 版本
yum list java*

# 安装 JDK 1.8
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

# 验证安装
java -version
javac -version
```

#### 方法2：手动安装 Oracle JDK

```bash
# 下载 JDK（需要 Oracle 账号）
# 或使用 wget 下载
cd /usr/local/src
wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz

# 解压
tar -zxvf jdk-17_linux-x64_bin.tar.gz -C /usr/local/

# 创建软链接
ln -s /usr/local/jdk-17 /usr/local/java

# 配置环境变量
vim /etc/profile

# 添加以下内容
export JAVA_HOME=/usr/local/java
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib
export PATH=$JAVA_HOME/bin:$PATH

# 使配置生效
source /etc/profile

# 验证
java -version
```

**输出示例**：
```
java version "1.8.0_301"
Java(TM) SE Runtime Environment (build 1.8.0_301-b09)
Java HotSpot(TM) 64-Bit Server VM (build 25.301-b09, mixed mode)
```

---

## 三、安装 Tomcat

### 3.1 下载 Tomcat

访问官网：https://tomcat.apache.org/

```bash
# 进入下载目录
cd /usr/local/src

# 下载 Tomcat 9
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.70/bin/apache-tomcat-9.0.70.tar.gz

# 解压
tar -zxvf apache-tomcat-9.0.70.tar.gz -C /usr/local/

# 创建软链接
ln -s /usr/local/apache-tomcat-9.0.70 /usr/local/tomcat

# 设置权限
chmod +x /usr/local/tomcat/bin/*.sh
```

### 3.2 目录结构

```bash
cd /usr/local/tomcat
tree -L 1
```

**目录说明**：
```
/usr/local/tomcat/
├── bin/          # 启动和停止脚本
├── conf/         # 配置文件
├── lib/          # 依赖库
├── logs/         # 日志文件
├── temp/         # 临时文件
├── webapps/      # Web 应用目录
└── work/         # 工作目录（JSP 编译后的文件）
```

**重要文件**：
- `bin/startup.sh`：启动脚本
- `bin/shutdown.sh`：停止脚本
- `bin/catalina.sh`：核心脚本
- `conf/server.xml`：主配置文件
- `conf/web.xml`：Web 应用配置
- `conf/tomcat-users.xml`：用户权限配置
- `logs/catalina.out`：主日志文件

---

## 四、配置 Tomcat

### 4.1 配置环境变量

```bash
vim /etc/profile

# 添加以下内容
export CATALINA_HOME=/usr/local/tomcat
export PATH=$CATALINA_HOME/bin:$PATH

# 使配置生效
source /etc/profile
```

### 4.2 修改端口（可选）

```bash
vim /usr/local/tomcat/conf/server.xml
```

找到以下内容：
```xml
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />
```

修改为：
```xml
<Connector port="80" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="443" />
```

### 4.3 配置管理用户

```bash
vim /usr/local/tomcat/conf/tomcat-users.xml
```

在 `<tomcat-users>` 标签内添加：
```xml
<role rolename="manager-gui"/>
<role rolename="admin-gui"/>
<user username="admin" password="admin123" roles="manager-gui,admin-gui"/>
```

### 4.4 允许远程访问管理界面

```bash
# 编辑 Manager 应用配置
vim /usr/local/tomcat/webapps/manager/META-INF/context.xml

# 注释掉以下内容（允许所有 IP 访问）
<!--
<Valve className="org.apache.catalina.valves.RemoteAddrValve"
       allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->
```

---

## 五、启动和管理

### 5.1 启动 Tomcat

```bash
# 方法1：使用启动脚本
/usr/local/tomcat/bin/startup.sh

# 方法2：使用 catalina.sh
/usr/local/tomcat/bin/catalina.sh start

# 方法3：前台运行（调试用）
/usr/local/tomcat/bin/catalina.sh run
```

**输出示例**：
```
Using CATALINA_BASE:   /usr/local/tomcat
Using CATALINA_HOME:   /usr/local/tomcat
Using CATALINA_TMPDIR: /usr/local/tomcat/temp
Using JRE_HOME:        /usr/local/java
Using CLASSPATH:       /usr/local/tomcat/bin/bootstrap.jar
Tomcat started.
```

### 5.2 停止 Tomcat

```bash
# 方法1：正常停止
/usr/local/tomcat/bin/shutdown.sh

# 方法2：强制停止
ps -ef | grep tomcat
kill -9 <PID>

# 方法3：使用 catalina.sh
/usr/local/tomcat/bin/catalina.sh stop
```

### 5.3 查看状态

```bash
# 查看进程
ps -ef | grep tomcat

# 查看端口
netstat -tunlp | grep 8080
ss -tunlp | grep 8080

# 查看日志
tail -f /usr/local/tomcat/logs/catalina.out
```

### 5.4 配置开机自启

#### 方法1：使用 systemd

```bash
vim /etc/systemd/system/tomcat.service
```

添加以下内容：
```ini
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/local/java
Environment=CATALINA_PID=/usr/local/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/usr/local/tomcat
Environment=CATALINA_BASE=/usr/local/tomcat

ExecStart=/usr/local/tomcat/bin/startup.sh
ExecStop=/usr/local/tomcat/bin/shutdown.sh

User=root
Group=root
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
# 重新加载 systemd
systemctl daemon-reload

# 启动服务
systemctl start tomcat

# 设置开机自启
systemctl enable tomcat

# 查看状态
systemctl status tomcat
```

#### 方法2：使用 rc.local

```bash
vim /etc/rc.local

# 添加以下内容
/usr/local/tomcat/bin/startup.sh

# 添加执行权限
chmod +x /etc/rc.local
```

---

## 六、部署第一个应用

### 6.1 访问默认页面

打开浏览器访问：
```
http://服务器IP:8080
```

你应该看到 Tomcat 欢迎页面。

### 6.2 部署 WAR 包

#### 方法1：直接复制

```bash
# 将 WAR 包复制到 webapps 目录
cp myapp.war /usr/local/tomcat/webapps/

# Tomcat 会自动解压并部署
# 访问：http://服务器IP:8080/myapp
```

#### 方法2：使用管理界面

1. 访问：`http://服务器IP:8080/manager/html`
2. 使用配置的用户名密码登录
3. 在 "WAR file to deploy" 部分上传 WAR 包
4. 点击 "Deploy" 部署

### 6.3 创建简单的测试应用

```bash
# 创建应用目录
mkdir -p /usr/local/tomcat/webapps/test

# 创建 index.jsp
vim /usr/local/tomcat/webapps/test/index.jsp
```

添加以下内容：
```jsp
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>测试页面</title>
</head>
<body>
    <h1>欢迎使用 Tomcat！</h1>
    <p>当前时间：<%= new java.util.Date() %></p>
    <p>服务器信息：<%= application.getServerInfo() %></p>
</body>
</html>
```

访问：`http://服务器IP:8080/test/`

---

## 七、日志管理

### 7.1 日志文件

```bash
cd /usr/local/tomcat/logs
ls -lh
```

**主要日志文件**：
- `catalina.out`：主日志文件
- `catalina.YYYY-MM-DD.log`：每日日志
- `localhost.YYYY-MM-DD.log`：本地主机日志
- `manager.YYYY-MM-DD.log`：管理应用日志
- `host-manager.YYYY-MM-DD.log`：主机管理日志

### 7.2 查看日志

```bash
# 实时查看日志
tail -f /usr/local/tomcat/logs/catalina.out

# 查看最后 100 行
tail -n 100 /usr/local/tomcat/logs/catalina.out

# 搜索错误
grep -i error /usr/local/tomcat/logs/catalina.out

# 搜索异常
grep -i exception /usr/local/tomcat/logs/catalina.out
```

### 7.3 日志轮转

```bash
vim /etc/logrotate.d/tomcat
```

添加以下内容：
```
/usr/local/tomcat/logs/catalina.out {
    daily
    rotate 30
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
```

---

## 八、常见问题

### 8.1 端口被占用

**问题**：启动失败，提示端口被占用

**解决**：
```bash
# 查看占用端口的进程
netstat -tunlp | grep 8080

# 杀死进程
kill -9 <PID>

# 或修改 Tomcat 端口
vim /usr/local/tomcat/conf/server.xml
```

### 8.2 内存不足

**问题**：启动后很快崩溃，日志显示 OutOfMemoryError

**解决**：
```bash
vim /usr/local/tomcat/bin/catalina.sh

# 在文件开头添加
JAVA_OPTS="-Xms512m -Xmx1024m -XX:PermSize=256m -XX:MaxPermSize=512m"
```

### 8.3 权限问题

**问题**：无法写入日志或临时文件

**解决**：
```bash
# 修改 Tomcat 目录权限
chown -R tomcat:tomcat /usr/local/tomcat

# 或使用 root 用户运行（不推荐）
```

### 8.4 应用部署失败

**问题**：WAR 包部署后无法访问

**解决**：
```bash
# 检查日志
tail -f /usr/local/tomcat/logs/catalina.out

# 检查应用是否解压
ls -l /usr/local/tomcat/webapps/

# 检查应用配置
cat /usr/local/tomcat/webapps/myapp/WEB-INF/web.xml

# 重新部署
rm -rf /usr/local/tomcat/webapps/myapp*
cp myapp.war /usr/local/tomcat/webapps/
```

---

## 九、实战练习

### 练习1：安装和配置 Tomcat

1. 安装 JDK 1.8
2. 下载并安装 Tomcat 9
3. 配置环境变量
4. 启动 Tomcat 并访问默认页面
5. 配置管理用户并登录管理界面

### 练习2：部署应用

1. 创建一个简单的 JSP 应用
2. 打包成 WAR 文件
3. 部署到 Tomcat
4. 访问并测试

### 练习3：配置开机自启

1. 创建 systemd 服务文件
2. 配置开机自启
3. 重启服务器验证

---

## 十、总结

本节学习了：

✅ Tomcat 架构和核心组件  
✅ JDK 和 Tomcat 的安装  
✅ Tomcat 目录结构  
✅ 基本配置和管理  
✅ 应用部署方法  
✅ 日志管理  
✅ 常见问题排查  

**下一节**：学习 Tomcat 集群架构和负载均衡配置。

---

## 参考资料

- [Tomcat 官方文档](https://tomcat.apache.org/tomcat-9.0-doc/)
- [Oracle JDK 下载](https://www.oracle.com/java/technologies/downloads/)
- [Tomcat 性能调优指南](https://tomcat.apache.org/tomcat-9.0-doc/performance.html)
