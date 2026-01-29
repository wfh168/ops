# Jenkins 安装与基础

## 一、Jenkins 简介

### 1.1 什么是 Jenkins

Jenkins 是一个开源的自动化服务器，用于实现持续集成和持续交付（CI/CD）。

**核心功能**：
- 持续集成（CI）
- 持续交付（CD）
- 自动化构建
- 自动化测试
- 自动化部署
- 插件生态丰富

**优势**：
- 开源免费
- 插件丰富（1800+ 插件）
- 社区活跃
- 易于扩展
- 支持分布式构建

### 1.2 Jenkins 架构

```
                Jenkins 架构
                     |
        +------------+------------+
        |            |            |
    [Master]     [Agent]      [Agent]
    (主节点)     (从节点1)    (从节点2)
        |            |            |
    调度任务      执行构建      执行构建
        |            |            |
        +------------+------------+
                     |
              [代码仓库]
              Git/SVN
                     |
              [制品仓库]
              Nexus/Artifactory
```

**核心组件**：
- **Master**：主节点，负责调度和管理
- **Agent**：从节点，负责执行构建任务
- **Job**：构建任务
- **Pipeline**：流水线
- **Plugin**：插件

---

## 二、系统要求

### 2.1 硬件要求

**最小配置**：
- CPU：1核
- 内存：256MB
- 硬盘：1GB

**推荐配置**（小团队）：
- CPU：2核
- 内存：2GB
- 硬盘：50GB

**生产环境**（大团队）：
- CPU：4核+
- 内存：4GB+
- 硬盘：100GB+

### 2.2 软件要求

- **Java**：JDK 11 或 17（推荐）
- **操作系统**：Linux、Windows、macOS
- **浏览器**：Chrome、Firefox、Edge

---

## 三、安装 Jenkins

### 3.1 安装 JDK

```bash
# CentOS/RHEL
sudo yum install -y java-11-openjdk java-11-openjdk-devel

# Ubuntu/Debian
sudo apt update
sudo apt install -y openjdk-11-jdk

# 验证安装
java -version
```

### 3.2 使用 YUM/APT 安装（推荐）

#### CentOS/RHEL

```bash
# 添加 Jenkins 仓库
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# 安装 Jenkins
sudo yum install -y jenkins

# 启动 Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 查看状态
sudo systemctl status jenkins
```

#### Ubuntu/Debian

```bash
# 添加 Jenkins 仓库
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# 更新并安装
sudo apt update
sudo apt install -y jenkins

# 启动 Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 3.3 使用 WAR 包安装

```bash
# 下载 Jenkins WAR 包
wget https://get.jenkins.io/war-stable/latest/jenkins.war

# 运行 Jenkins
java -jar jenkins.war --httpPort=8080

# 后台运行
nohup java -jar jenkins.war --httpPort=8080 > jenkins.log 2>&1 &
```

### 3.4 使用 Docker 安装

```bash
# 创建数据目录
mkdir -p /data/jenkins_home

# 运行 Jenkins 容器
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /data/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# 查看初始密码
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 3.5 配置防火墙

```bash
# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Ubuntu/Debian
sudo ufw allow 8080/tcp
sudo ufw reload
```

---

## 四、初始化配置

### 4.1 首次访问

1. 打开浏览器访问：`http://服务器IP:8080`
2. 获取初始管理员密码

```bash
# 查看初始密码
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

3. 输入密码解锁 Jenkins

### 4.2 安装插件

**选择安装方式**：
- **安装推荐的插件**（推荐）：自动安装常用插件
- **选择插件来安装**：手动选择需要的插件

**推荐插件**：
- Git plugin
- Pipeline
- Docker plugin
- SSH plugin
- Email Extension
- Blue Ocean（现代化 UI）

### 4.3 创建管理员用户

```
用户名：admin
密码：设置强密码
全名：Administrator
邮箱：admin@example.com
```

### 4.4 实例配置

```
Jenkins URL：http://jenkins.example.com:8080
或：http://服务器IP:8080
```

---

## 五、基础配置

### 5.1 系统配置

```
Manage Jenkins → System

主要配置项：
- # of executors：执行器数量（并发构建数）
- Jenkins Location：Jenkins URL 和管理员邮箱
- Git plugin：Git 可执行文件路径
- Email Notification：邮件通知配置
```

### 5.2 全局工具配置

```
Manage Jenkins → Global Tool Configuration

配置工具：
- JDK installations：JDK 安装路径
- Git installations：Git 安装路径
- Maven installations：Maven 配置
- Gradle installations：Gradle 配置
- Node.js installations：Node.js 配置
```

**配置 JDK**：
```
Name：JDK-11
JAVA_HOME：/usr/lib/jvm/java-11-openjdk
```

**配置 Maven**：
```
Name：Maven-3.8
Install automatically：勾选
Version：3.8.6
```

**配置 Git**：
```
Name：Default
Path to Git executable：git（或 /usr/bin/git）
```

### 5.3 插件管理

```
Manage Jenkins → Manage Plugins

标签页：
- Updates：可更新的插件
- Available：可安装的插件
- Installed：已安装的插件
- Advanced：高级设置
```

**常用插件**：
```
必装插件：
- Git plugin
- Pipeline
- Credentials Binding
- SSH Agent
- Publish Over SSH

推荐插件：
- Blue Ocean（现代化 UI）
- Docker plugin
- Kubernetes plugin
- SonarQube Scanner
- Slack Notification
- DingTalk（钉钉通知）
```

### 5.4 凭据管理

```
Manage Jenkins → Manage Credentials

凭据类型：
- Username with password：用户名密码
- SSH Username with private key：SSH 密钥
- Secret text：密钥文本
- Secret file：密钥文件
- Certificate：证书
```

**添加 Git 凭据**：
```
Kind：Username with password
Scope：Global
Username：git 用户名
Password：git 密码或 token
ID：git-credentials
Description：Git 凭据
```

**添加 SSH 凭据**：
```
Kind：SSH Username with private key
Username：root
Private Key：Enter directly（粘贴私钥）
Passphrase：私钥密码（如果有）
ID：ssh-credentials
```

---

## 六、创建第一个 Job

### 6.1 Freestyle Project

```
1. 点击 "New Item"
2. 输入名称：hello-world
3. 选择 "Freestyle project"
4. 点击 "OK"
```

**配置 Job**：
```
General：
- Description：第一个 Jenkins Job

Source Code Management：
- Git
- Repository URL：https://github.com/user/repo.git
- Credentials：选择 Git 凭据
- Branch：*/main

Build Triggers：
- Poll SCM：H/5 * * * *（每5分钟检查一次）

Build Environment：
- Delete workspace before build starts

Build Steps：
- Execute shell
  #!/bin/bash
  echo "Hello, Jenkins!"
  echo "Current directory: $(pwd)"
  ls -la

Post-build Actions：
- Email Notification
```

### 6.2 运行 Job

```
1. 点击 "Build Now"
2. 查看 "Build History"
3. 点击构建号查看详情
4. 查看 "Console Output"
```

---

## 七、Pipeline 基础

### 7.1 创建 Pipeline Job

```
1. New Item
2. 输入名称：my-pipeline
3. 选择 "Pipeline"
4. 点击 "OK"
```

### 7.2 编写 Pipeline 脚本

**Declarative Pipeline**（推荐）：

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                git branch: 'main',
                    url: 'https://github.com/user/repo.git'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'npm install'
                sh 'npm run build'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'npm test'
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                sh 'scp -r dist/* user@server:/var/www/html/'
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

**Scripted Pipeline**：

```groovy
node {
    stage('Checkout') {
        echo 'Checking out code...'
        git branch: 'main',
            url: 'https://github.com/user/repo.git'
    }
    
    stage('Build') {
        echo 'Building application...'
        sh 'npm install'
        sh 'npm run build'
    }
    
    stage('Test') {
        echo 'Running tests...'
        sh 'npm test'
    }
    
    stage('Deploy') {
        echo 'Deploying application...'
        sh 'scp -r dist/* user@server:/var/www/html/'
    }
}
```

---

## 八、常用管理命令

### 8.1 服务管理

```bash
# 启动 Jenkins
sudo systemctl start jenkins

# 停止 Jenkins
sudo systemctl stop jenkins

# 重启 Jenkins
sudo systemctl restart jenkins

# 查看状态
sudo systemctl status jenkins

# 查看日志
sudo journalctl -u jenkins -f
```

### 8.2 配置文件

```bash
# Jenkins 主目录
/var/lib/jenkins/

# 配置文件
/etc/sysconfig/jenkins  # CentOS
/etc/default/jenkins    # Ubuntu

# 日志文件
/var/log/jenkins/jenkins.log
```

### 8.3 修改端口

```bash
# 编辑配置文件
sudo vim /etc/sysconfig/jenkins  # CentOS
sudo vim /etc/default/jenkins    # Ubuntu

# 修改端口
JENKINS_PORT="8080"  # 改为其他端口

# 重启服务
sudo systemctl restart jenkins
```

---

## 九、安全配置

### 9.1 启用安全

```
Manage Jenkins → Configure Global Security

Security Realm：
- Jenkins' own user database
- Allow users to sign up：取消勾选

Authorization：
- Matrix-based security
- 配置用户权限
```

### 9.2 配置 HTTPS

#### 使用 Nginx 反向代理

```nginx
server {
    listen 80;
    server_name jenkins.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name jenkins.example.com;
    
    ssl_certificate /etc/nginx/ssl/jenkins.crt;
    ssl_certificate_key /etc/nginx/ssl/jenkins.key;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 9.3 备份和恢复

```bash
# 备份 Jenkins 主目录
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins/

# 恢复
sudo systemctl stop jenkins
sudo tar -xzf jenkins-backup-20240129.tar.gz -C /
sudo systemctl start jenkins
```

---

## 十、故障排查

### 10.1 常见问题

#### 问题1：Jenkins 无法启动

```bash
# 检查 Java 版本
java -version

# 检查端口占用
sudo netstat -tunlp | grep 8080

# 查看日志
sudo journalctl -u jenkins -n 50
```

#### 问题2：内存不足

```bash
# 编辑配置文件
sudo vim /etc/sysconfig/jenkins

# 增加内存
JENKINS_JAVA_OPTIONS="-Xms512m -Xmx2048m"

# 重启服务
sudo systemctl restart jenkins
```

#### 问题3：插件安装失败

```
1. 检查网络连接
2. 更换插件源
   Manage Jenkins → Manage Plugins → Advanced
   Update Site：https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
3. 重启 Jenkins
```

---

## 十一、实战练习

### 练习1：安装和配置 Jenkins

1. 安装 Jenkins
2. 完成初始化配置
3. 安装推荐插件
4. 创建管理员用户

### 练习2：创建 Freestyle Job

1. 创建一个 Freestyle Job
2. 配置 Git 仓库
3. 添加构建步骤
4. 运行并查看结果

### 练习3：编写 Pipeline

1. 创建 Pipeline Job
2. 编写简单的 Pipeline 脚本
3. 包含多个 stage
4. 运行并查看结果

---

## 十二、总结

本节学习了：

✅ Jenkins 简介和架构  
✅ Jenkins 安装方法  
✅ 初始化配置  
✅ 基础配置  
✅ 创建第一个 Job  
✅ Pipeline 基础  
✅ 安全配置  
✅ 故障排查  

**下一节**：学习 Job 配置和构建触发器。

---

## 参考资料

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [Jenkins 插件中心](https://plugins.jenkins.io/)
- [Jenkins Pipeline 文档](https://www.jenkins.io/doc/book/pipeline/)
