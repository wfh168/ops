# Job 配置与构建

## 一、Freestyle Job 详解

### 1.1 创建 Freestyle Job

```
1. 点击 "New Item"
2. 输入项目名称：my-freestyle-job
3. 选择 "Freestyle project"
4. 点击 "OK"
```

### 1.2 General 配置

**基本信息**：
```
Description：项目描述
Discard old builds：丢弃旧的构建
  - Days to keep builds：保留天数（如：30）
  - Max # of builds to keep：最大保留数量（如：10）

GitHub project：关联 GitHub 项目
  - Project url：https://github.com/user/repo

This project is parameterized：参数化构建
Throttle builds：限制构建频率
Disable this project：禁用项目
```

### 1.3 Source Code Management（源码管理）

#### Git 配置

```
选择：Git

Repository URL：
  https://github.com/user/repo.git
  或
  git@github.com:user/repo.git

Credentials：
  - 选择已配置的凭据
  - 或点击 "Add" 添加新凭据

Branches to build：
  - Branch Specifier：*/main
  - 或：*/develop
  - 或：${GIT_BRANCH}（参数化）

Repository browser：
  - 选择：githubweb
  - URL：https://github.com/user/repo

Additional Behaviours：
  - Clean before checkout：构建前清理
  - Check out to a sub-directory：检出到子目录
  - Wipe out repository & force clone：强制克隆
```

#### SVN 配置

```
选择：Subversion

Repository URL：
  svn://svn.example.com/repo/trunk

Credentials：选择 SVN 凭据

Local module directory：本地目录（可选）

Repository depth：检出深度
  - infinity：完整检出
  - immediates：只检出直接子目录
```

### 1.4 Build Triggers（构建触发器）

#### 1. Trigger builds remotely

```
Authentication Token：设置触发令牌

触发 URL：
http://JENKINS_URL/job/JOB_NAME/build?token=TOKEN_NAME

示例：
curl http://jenkins.example.com:8080/job/my-job/build?token=mytoken
```

#### 2. Build after other projects are built

```
Projects to watch：监控的项目名称
  - my-upstream-job

Trigger only if build is stable：仅在构建稳定时触发
Trigger even if the build fails：即使构建失败也触发
Trigger even if the build is unstable：即使构建不稳定也触发
```

#### 3. Build periodically（定时构建）

```
Schedule：使用 Cron 语法

示例：
H 2 * * *        # 每天凌晨2点（H表示哈希，避免同时触发）
H */4 * * *      # 每4小时
H H * * 0        # 每周日
H H 1 * *        # 每月1号
H H(0-7) * * *   # 每天0-7点之间的某个时间
```

#### 4. GitHub hook trigger（推荐）

```
勾选：GitHub hook trigger for GITScm polling

配置 GitHub Webhook：
1. 进入 GitHub 仓库 Settings → Webhooks
2. 添加 Webhook
   Payload URL：http://jenkins.example.com:8080/github-webhook/
   Content type：application/json
   Events：Just the push event
3. 保存
```

#### 5. Poll SCM（轮询 SCM）

```
Schedule：使用 Cron 语法

示例：
H/5 * * * *      # 每5分钟检查一次
H/15 * * * *     # 每15分钟检查一次

注意：推荐使用 Webhook，而不是轮询
```

### 1.5 Build Environment（构建环境）

```
Delete workspace before build starts：
  - 构建前删除工作空间

Use secret text(s) or file(s)：
  - 使用密钥文本或文件
  - 绑定凭据到环境变量

Add timestamps to the Console Output：
  - 在控制台输出添加时间戳

Inspect build log for published build scans：
  - 检查构建日志

Terminate a build if it's stuck：
  - 超时终止构建
  - Timeout strategy：Absolute（绝对时间）
  - Timeout minutes：60
```

### 1.6 Build Steps（构建步骤）

#### Execute shell（Linux/Mac）

```bash
#!/bin/bash
set -e  # 遇到错误立即退出

echo "=== 开始构建 ==="
echo "当前目录: $(pwd)"
echo "Git 分支: ${GIT_BRANCH}"
echo "构建号: ${BUILD_NUMBER}"

# 清理旧的构建产物
rm -rf target/

# Maven 构建
mvn clean package -DskipTests

# 检查构建结果
if [ -f target/*.jar ]; then
    echo "构建成功！"
    ls -lh target/*.jar
else
    echo "构建失败！"
    exit 1
fi

echo "=== 构建完成 ==="
```

#### Execute Windows batch command

```batch
@echo off
echo === 开始构建 ===
echo 当前目录: %CD%
echo 构建号: %BUILD_NUMBER%

REM 清理旧的构建产物
if exist target rmdir /s /q target

REM Maven 构建
call mvn clean package -DskipTests

REM 检查构建结果
if exist target\*.jar (
    echo 构建成功！
    dir target\*.jar
) else (
    echo 构建失败！
    exit /b 1
)

echo === 构建完成 ===
```

#### Invoke top-level Maven targets

```
Maven Version：选择 Maven 版本
Goals：clean package
Properties：
  maven.test.skip=true
  env=prod
POM：pom.xml（默认）
```

#### Invoke Gradle script

```
Gradle Version：选择 Gradle 版本
Tasks：clean build
Switches：--info
Build File：build.gradle（默认）
```

#### Execute NodeJS script

```
NodeJS Installation：选择 Node.js 版本
Command：
  npm install
  npm run build
```

### 1.7 Post-build Actions（构建后操作）

#### 1. Archive the artifacts（归档构建产物）

```
Files to archive：
  target/*.jar
  target/*.war
  dist/**/*

Excludes：排除文件（可选）

Advanced：
  - Fingerprint all archived artifacts：指纹识别
  - Discard all but the last successful/stable artifact：只保留最后成功的
```

#### 2. Publish JUnit test result report

```
Test report XMLs：
  target/surefire-reports/*.xml
  target/test-reports/*.xml

Advanced：
  - Retain long standard output/error：保留详细输出
  - Health report amplification factor：健康报告放大因子
```

#### 3. Email Notification

```
Recipients：
  admin@example.com, team@example.com

Send e-mail for every unstable build：每次不稳定构建发送邮件
Send separate e-mails to individuals who broke the build：单独发送给破坏构建的人
```

#### 4. Editable Email Notification（推荐）

```
Project Recipient List：
  $DEFAULT_RECIPIENTS, admin@example.com

Project Reply-To List：
  $DEFAULT_REPLYTO

Content Type：HTML (text/html)

Default Subject：
  构建 $PROJECT_NAME - $BUILD_STATUS - 构建号 #$BUILD_NUMBER

Default Content：
  <h2>构建结果：$BUILD_STATUS</h2>
  <p>项目名称：$PROJECT_NAME</p>
  <p>构建号：#$BUILD_NUMBER</p>
  <p>构建时间：$BUILD_TIMESTAMP</p>
  <p>构建日志：<a href="$BUILD_URL">查看详情</a></p>
  <p>变更记录：</p>
  ${CHANGES, showPaths=true}

Triggers：
  - Success：构建成功
  - Failure - Any：构建失败
  - Unstable (Test Failures)：测试失败
```

#### 5. Build other projects

```
Projects to build：
  downstream-job-1, downstream-job-2

Trigger only if build is stable：仅在构建稳定时触发
Trigger even if the build fails：即使失败也触发
Trigger even if the build is unstable：即使不稳定也触发
```

#### 6. Deploy artifacts to Maven repository

```
Repository URL：
  http://nexus.example.com/repository/maven-releases/

Repository ID：nexus

Credentials：选择 Nexus 凭据
```

---

## 二、Pipeline Job 详解

### 2.1 创建 Pipeline Job

```
1. New Item
2. 输入名称：my-pipeline
3. 选择 "Pipeline"
4. 点击 "OK"
```

### 2.2 Pipeline 配置

#### General 配置

```
Description：Pipeline 描述

Discard old builds：
  - Days to keep builds：30
  - Max # of builds to keep：10

This project is parameterized：
  - 添加参数（见下文）

Do not allow concurrent builds：不允许并发构建

Do not allow the pipeline to resume if the controller restarts：
  - 控制器重启时不恢复 Pipeline
```

#### Pipeline 定义

**方式1：Pipeline script（直接编写）**

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
}
```

**方式2：Pipeline script from SCM（从 SCM 读取）**

```
SCM：Git
Repository URL：https://github.com/user/repo.git
Credentials：选择凭据
Branch：*/main
Script Path：Jenkinsfile（默认）
```

### 2.3 Declarative Pipeline 语法

#### 基本结构

```groovy
pipeline {
    // 1. agent：指定执行节点
    agent any
    
    // 2. environment：环境变量
    environment {
        APP_NAME = 'my-app'
        APP_VERSION = '1.0.0'
    }
    
    // 3. parameters：参数
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Git 分支')
        choice(name: 'ENV', choices: ['dev', 'test', 'prod'], description: '部署环境')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: '跳过测试')
    }
    
    // 4. triggers：触发器
    triggers {
        cron('H 2 * * *')  // 每天凌晨2点
        pollSCM('H/5 * * * *')  // 每5分钟轮询
    }
    
    // 5. options：选项
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }
    
    // 6. stages：阶段
    stages {
        stage('Checkout') {
            steps {
                git branch: "${params.BRANCH}",
                    url: 'https://github.com/user/repo.git'
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Test') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                sh 'mvn test'
            }
        }
        
        stage('Deploy') {
            steps {
                sh "echo Deploying to ${params.ENV}"
            }
        }
    }
    
    // 7. post：构建后操作
    post {
        always {
            echo 'Pipeline finished'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        unstable {
            echo 'Pipeline is unstable'
        }
    }
}
```

#### Agent 配置

```groovy
// 任意可用节点
agent any

// 指定标签
agent {
    label 'linux'
}

// Docker 容器
agent {
    docker {
        image 'maven:3.8-jdk-11'
        args '-v /root/.m2:/root/.m2'
    }
}

// Kubernetes Pod
agent {
    kubernetes {
        yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8-jdk-11
    command: ['cat']
    tty: true
'''
    }
}

// 不同 stage 使用不同 agent
pipeline {
    agent none
    stages {
        stage('Build') {
            agent { label 'linux' }
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Deploy') {
            agent { label 'deploy-server' }
            steps {
                sh 'deploy.sh'
            }
        }
    }
}
```

#### Environment 环境变量

```groovy
environment {
    // 全局环境变量
    APP_NAME = 'my-app'
    APP_VERSION = '1.0.0'
    
    // 使用凭据
    DOCKER_CREDENTIALS = credentials('docker-hub-credentials')
    
    // 使用其他环境变量
    BUILD_TAG = "${env.JOB_NAME}-${env.BUILD_NUMBER}"
}

// Stage 级别的环境变量
stage('Build') {
    environment {
        MAVEN_OPTS = '-Xmx1024m'
    }
    steps {
        sh 'mvn clean package'
    }
}
```

#### Parameters 参数

```groovy
parameters {
    // 字符串参数
    string(
        name: 'BRANCH',
        defaultValue: 'main',
        description: 'Git 分支名称'
    )
    
    // 文本参数（多行）
    text(
        name: 'DESCRIPTION',
        defaultValue: '',
        description: '部署说明'
    )
    
    // 布尔参数
    booleanParam(
        name: 'SKIP_TESTS',
        defaultValue: false,
        description: '是否跳过测试'
    )
    
    // 选择参数
    choice(
        name: 'ENVIRONMENT',
        choices: ['dev', 'test', 'staging', 'prod'],
        description: '部署环境'
    )
    
    // 密码参数
    password(
        name: 'DB_PASSWORD',
        defaultValue: '',
        description: '数据库密码'
    )
    
    // 文件参数
    file(
        name: 'CONFIG_FILE',
        description: '配置文件'
    )
}

// 使用参数
steps {
    echo "Branch: ${params.BRANCH}"
    echo "Environment: ${params.ENVIRONMENT}"
    sh "deploy.sh ${params.ENVIRONMENT}"
}
```

#### When 条件

```groovy
stage('Deploy to Production') {
    when {
        // 分支条件
        branch 'main'
    }
    steps {
        sh 'deploy-prod.sh'
    }
}

stage('Deploy') {
    when {
        // 表达式条件
        expression { params.ENVIRONMENT == 'prod' }
    }
    steps {
        sh 'deploy.sh'
    }
}

stage('Test') {
    when {
        // 多个条件（AND）
        allOf {
            branch 'develop'
            expression { params.SKIP_TESTS == false }
        }
    }
    steps {
        sh 'mvn test'
    }
}

stage('Notify') {
    when {
        // 多个条件（OR）
        anyOf {
            branch 'main'
            branch 'develop'
        }
    }
    steps {
        echo 'Sending notification'
    }
}

stage('Deploy') {
    when {
        // 否定条件
        not {
            branch 'feature/*'
        }
    }
    steps {
        sh 'deploy.sh'
    }
}
```

### 2.4 Scripted Pipeline 语法

```groovy
node {
    try {
        // Checkout
        stage('Checkout') {
            checkout scm
        }
        
        // Build
        stage('Build') {
            sh 'mvn clean package'
        }
        
        // Test
        stage('Test') {
            sh 'mvn test'
        }
        
        // Deploy
        stage('Deploy') {
            if (env.BRANCH_NAME == 'main') {
                sh 'deploy.sh'
            }
        }
        
        // Success
        currentBuild.result = 'SUCCESS'
    } catch (Exception e) {
        // Failure
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        // Cleanup
        echo 'Cleaning up...'
    }
}
```

---

## 三、多分支 Pipeline

### 3.1 创建多分支 Pipeline

```
1. New Item
2. 输入名称：my-multibranch-pipeline
3. 选择 "Multibranch Pipeline"
4. 点击 "OK"
```

### 3.2 配置多分支 Pipeline

```
Branch Sources：
  - Git
    Project Repository：https://github.com/user/repo.git
    Credentials：选择凭据
    
Behaviours：
  - Discover branches：发现分支
    Strategy：All branches
  - Discover pull requests from origin：发现 PR
  - Clean before checkout：构建前清理

Build Configuration：
  - Mode：by Jenkinsfile
  - Script Path：Jenkinsfile

Scan Multibranch Pipeline Triggers：
  - Periodically if not otherwise run：定期扫描
    Interval：1 hour

Orphaned Item Strategy：
  - Discard old items：丢弃旧项目
    Days to keep old items：7
    Max # of old items to keep：10
```

### 3.3 Jenkinsfile 示例

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                echo "Building branch: ${env.BRANCH_NAME}"
                sh 'mvn clean package'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        
        stage('Deploy to Dev') {
            when {
                branch 'develop'
            }
            steps {
                sh 'deploy-dev.sh'
            }
        }
        
        stage('Deploy to Test') {
            when {
                branch 'release/*'
            }
            steps {
                sh 'deploy-test.sh'
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: '确认部署到生产环境？'
                sh 'deploy-prod.sh'
            }
        }
    }
    
    post {
        success {
            echo "Build succeeded for branch ${env.BRANCH_NAME}"
        }
        failure {
            echo "Build failed for branch ${env.BRANCH_NAME}"
        }
    }
}
```

---

## 四、参数化构建

### 4.1 添加参数

```
勾选：This project is parameterized

添加参数：
1. String Parameter
2. Choice Parameter
3. Boolean Parameter
4. File Parameter
5. Password Parameter
```

### 4.2 参数示例

```groovy
parameters {
    string(
        name: 'VERSION',
        defaultValue: '1.0.0',
        description: '应用版本号'
    )
    
    choice(
        name: 'ENVIRONMENT',
        choices: ['dev', 'test', 'staging', 'prod'],
        description: '部署环境'
    )
    
    booleanParam(
        name: 'DEPLOY',
        defaultValue: false,
        description: '是否部署'
    )
}

stages {
    stage('Build') {
        steps {
            echo "Building version ${params.VERSION}"
            sh "mvn clean package -Dversion=${params.VERSION}"
        }
    }
    
    stage('Deploy') {
        when {
            expression { params.DEPLOY == true }
        }
        steps {
            echo "Deploying to ${params.ENVIRONMENT}"
            sh "deploy.sh ${params.ENVIRONMENT} ${params.VERSION}"
        }
    }
}
```

---

## 五、实战案例

### 案例1：Java Maven 项目

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven-3.8'
        jdk 'JDK-11'
    }
    
    parameters {
        choice(name: 'ENV', choices: ['dev', 'test', 'prod'], description: '部署环境')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: '跳过测试')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/user/java-app.git',
                    credentialsId: 'git-credentials'
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests=${params.SKIP_TESTS}'
            }
        }
        
        stage('Test') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    def jarFile = sh(script: 'ls target/*.jar', returnStdout: true).trim()
                    sh """
                        scp ${jarFile} deploy@server:/opt/app/
                        ssh deploy@server 'systemctl restart myapp'
                    """
                }
            }
        }
    }
    
    post {
        success {
            emailext(
                subject: "构建成功: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "构建成功，已部署到 ${params.ENV} 环境",
                to: 'team@example.com'
            )
        }
        failure {
            emailext(
                subject: "构建失败: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "构建失败，请查看日志: ${env.BUILD_URL}",
                to: 'team@example.com'
            )
        }
    }
}
```

### 案例2：Node.js 前端项目

```groovy
pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS-16'
    }
    
    environment {
        CI = 'true'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/user/frontend-app.git'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }
        
        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    rsync -avz --delete dist/ deploy@server:/var/www/html/
                '''
            }
        }
    }
}
```

---

## 六、总结

本节学习了：

✅ Freestyle Job 详细配置  
✅ Pipeline Job 创建和配置  
✅ Declarative Pipeline 语法  
✅ Scripted Pipeline 语法  
✅ 多分支 Pipeline  
✅ 参数化构建  
✅ 实战案例  

**下一节**：学习 Pipeline 高级特性和自动化部署。
