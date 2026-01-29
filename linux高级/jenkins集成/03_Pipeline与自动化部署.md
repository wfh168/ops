# Pipeline 与自动化部署

## 一、Jenkinsfile 详解

### 1.1 什么是 Jenkinsfile

Jenkinsfile 是一个文本文件，包含 Jenkins Pipeline 的定义，存储在项目的源代码仓库中。

**优势**：
- Pipeline as Code（流水线即代码）
- 版本控制
- 代码审查
- 团队协作
- 可重用

### 1.2 Jenkinsfile 位置

```
项目根目录/
├── Jenkinsfile          # 默认文件名
├── Jenkinsfile.dev      # 开发环境
├── Jenkinsfile.prod     # 生产环境
├── src/
└── pom.xml
```

### 1.3 基本 Jenkinsfile

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'mvn clean package'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Testing...'
                sh 'mvn test'
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                sh './deploy.sh'
            }
        }
    }
}
```

---

## 二、Declarative Pipeline 高级特性

### 2.1 并行执行

```groovy
pipeline {
    agent any
    
    stages {
        stage('Parallel Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'mvn test'
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        sh 'mvn verify'
                    }
                }
                
                stage('UI Tests') {
                    steps {
                        sh 'npm run test:e2e'
                    }
                }
            }
        }
    }
}
```

### 2.2 矩阵构建

```groovy
pipeline {
    agent none
    
    stages {
        stage('Build') {
            matrix {
                axes {
                    axis {
                        name 'PLATFORM'
                        values 'linux', 'windows', 'mac'
                    }
                    axis {
                        name 'JAVA_VERSION'
                        values '8', '11', '17'
                    }
                }
                agent {
                    label "${PLATFORM}"
                }
                stages {
                    stage('Build on Platform') {
                        steps {
                            echo "Building on ${PLATFORM} with Java ${JAVA_VERSION}"
                            sh "mvn clean package -Djava.version=${JAVA_VERSION}"
                        }
                    }
                }
            }
        }
    }
}
```


### 2.3 Input 交互式审批

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Deploy to Test') {
            steps {
                sh 'deploy-test.sh'
            }
        }
        
        stage('Approval') {
            steps {
                input message: '是否部署到生产环境？',
                      ok: '确认部署',
                      submitter: 'admin,ops-team',
                      parameters: [
                          choice(name: 'STRATEGY', choices: ['rolling', 'blue-green'], description: '部署策略')
                      ]
            }
        }
        
        stage('Deploy to Production') {
            steps {
                echo "Deploying with ${STRATEGY} strategy"
                sh "deploy-prod.sh ${STRATEGY}"
            }
        }
    }
}
```

### 2.4 Script 块

```groovy
pipeline {
    agent any
    
    stages {
        stage('Complex Logic') {
            steps {
                script {
                    // 使用 Groovy 脚本
                    def version = sh(script: 'git describe --tags', returnStdout: true).trim()
                    echo "Version: ${version}"
                    
                    // 条件判断
                    if (env.BRANCH_NAME == 'main') {
                        echo 'Main branch detected'
                        env.DEPLOY_ENV = 'prod'
                    } else {
                        echo 'Feature branch detected'
                        env.DEPLOY_ENV = 'dev'
                    }
                    
                    // 循环
                    def servers = ['server1', 'server2', 'server3']
                    for (server in servers) {
                        echo "Deploying to ${server}"
                        sh "deploy.sh ${server}"
                    }
                }
            }
        }
    }
}
```

### 2.5 共享库

**定义共享库**（vars/deployApp.groovy）：
```groovy
def call(String env, String version) {
    echo "Deploying version ${version} to ${env}"
    sh """
        ssh deploy@${env}-server "
            cd /opt/app &&
            wget http://nexus/app-${version}.jar &&
            systemctl restart app
        "
    """
}
```

**使用共享库**：
```groovy
@Library('my-shared-library') _

pipeline {
    agent any
    
    stages {
        stage('Deploy') {
            steps {
                deployApp('prod', '1.0.0')
            }
        }
    }
}
```

---

## 三、Scripted Pipeline 高级特性

### 3.1 完整示例

```groovy
node {
    def mvnHome
    def buildNumber = env.BUILD_NUMBER
    def workspace = env.WORKSPACE
    
    try {
        // Checkout
        stage('Checkout') {
            checkout scm
            mvnHome = tool 'Maven-3.8'
        }
        
        // Build
        stage('Build') {
            withEnv(["PATH+MAVEN=${mvnHome}/bin"]) {
                sh 'mvn clean package'
            }
        }
        
        // Test
        stage('Test') {
            parallel(
                'Unit Tests': {
                    sh 'mvn test'
                },
                'Integration Tests': {
                    sh 'mvn verify'
                }
            )
        }
        
        // Archive
        stage('Archive') {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
        
        // Deploy
        stage('Deploy') {
            if (env.BRANCH_NAME == 'main') {
                timeout(time: 5, unit: 'MINUTES') {
                    input message: '确认部署？', ok: '部署'
                }
                sh 'deploy.sh'
            }
        }
        
        currentBuild.result = 'SUCCESS'
        
    } catch (Exception e) {
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        // Cleanup
        cleanWs()
        
        // Notification
        emailext(
            subject: "Build ${currentBuild.result}: ${env.JOB_NAME} #${buildNumber}",
            body: "Build ${currentBuild.result}",
            to: 'team@example.com'
        )
    }
}
```

---

## 四、Docker 集成

### 4.1 使用 Docker Agent

```groovy
pipeline {
    agent {
        docker {
            image 'maven:3.8-jdk-11'
            args '-v /root/.m2:/root/.m2'
        }
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
    }
}
```

### 4.2 构建 Docker 镜像

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        IMAGE_NAME = 'myapp'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Build Application') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }
        
        stage('Push Docker Image') {
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
                sh """
                    ssh deploy@server "
                        docker pull ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} &&
                        docker stop myapp || true &&
                        docker rm myapp || true &&
                        docker run -d --name myapp -p 8080:8080 ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    "
                """
            }
        }
    }
}
```

### 4.3 Docker Compose 部署

```groovy
pipeline {
    agent any
    
    stages {
        stage('Deploy with Docker Compose') {
            steps {
                sh '''
                    scp docker-compose.yml deploy@server:/opt/app/
                    ssh deploy@server "
                        cd /opt/app &&
                        docker-compose pull &&
                        docker-compose up -d
                    "
                '''
            }
        }
    }
}
```

---

## 五、Kubernetes 集成

### 5.1 使用 Kubernetes Agent

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  containers:
  - name: maven
    image: maven:3.8-jdk-11
    command: ['cat']
    tty: true
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  - name: docker
    image: docker:latest
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: maven-cache
    hostPath:
      path: /tmp/maven-cache
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }
    
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn clean package'
                }
            }
        }
        
        stage('Build Image') {
            steps {
                container('docker') {
                    sh 'docker build -t myapp:${BUILD_NUMBER} .'
                }
            }
        }
    }
}
```

### 5.2 部署到 Kubernetes

```groovy
pipeline {
    agent any
    
    environment {
        K8S_NAMESPACE = 'production'
        APP_NAME = 'myapp'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Build and Push Image') {
            steps {
                sh '''
                    docker build -t registry.example.com/myapp:${IMAGE_TAG} .
                    docker push registry.example.com/myapp:${IMAGE_TAG}
                '''
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    kubectl set image deployment/${APP_NAME} \
                        ${APP_NAME}=registry.example.com/myapp:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}
                    
                    kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE}
                """
            }
        }
    }
}
```

---

## 六、自动化测试集成

### 6.1 单元测试

```groovy
pipeline {
    agent any
    
    stages {
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco(
                        execPattern: 'target/jacoco.exec',
                        classPattern: 'target/classes',
                        sourcePattern: 'src/main/java'
                    )
                }
            }
        }
    }
}
```

### 6.2 集成测试

```groovy
pipeline {
    agent any
    
    stages {
        stage('Integration Tests') {
            steps {
                sh '''
                    # 启动测试环境
                    docker-compose -f docker-compose.test.yml up -d
                    
                    # 等待服务就绪
                    sleep 30
                    
                    # 运行集成测试
                    mvn verify
                    
                    # 清理测试环境
                    docker-compose -f docker-compose.test.yml down
                '''
            }
        }
    }
}
```

### 6.3 代码质量检查

```groovy
pipeline {
    agent any
    
    stages {
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
```

---

## 七、通知和监控

### 7.1 邮件通知

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
    }
    
    post {
        success {
            emailext(
                subject: "✅ 构建成功: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>构建成功</h2>
                    <p>项目: ${env.JOB_NAME}</p>
                    <p>构建号: #${env.BUILD_NUMBER}</p>
                    <p>分支: ${env.GIT_BRANCH}</p>
                    <p>查看详情: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                """,
                to: 'team@example.com',
                mimeType: 'text/html'
            )
        }
        
        failure {
            emailext(
                subject: "❌ 构建失败: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>构建失败</h2>
                    <p>项目: ${env.JOB_NAME}</p>
                    <p>构建号: #${env.BUILD_NUMBER}</p>
                    <p>查看日志: <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a></p>
                """,
                to: 'team@example.com',
                mimeType: 'text/html'
            )
        }
    }
}
```

### 7.2 钉钉通知

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
    }
    
    post {
        success {
            dingtalk(
                robot: 'jenkins-robot',
                type: 'MARKDOWN',
                title: '构建成功',
                text: [
                    "### ✅ 构建成功",
                    "- 项目: ${env.JOB_NAME}",
                    "- 构建号: #${env.BUILD_NUMBER}",
                    "- 分支: ${env.GIT_BRANCH}",
                    "- [查看详情](${env.BUILD_URL})"
                ]
            )
        }
        
        failure {
            dingtalk(
                robot: 'jenkins-robot',
                type: 'MARKDOWN',
                title: '构建失败',
                text: [
                    "### ❌ 构建失败",
                    "- 项目: ${env.JOB_NAME}",
                    "- 构建号: #${env.BUILD_NUMBER}",
                    "- [查看日志](${env.BUILD_URL}console)"
                ],
                at: ['18888888888']
            )
        }
    }
}
```

### 7.3 Slack 通知

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
    }
    
    post {
        success {
            slackSend(
                color: 'good',
                message: "✅ Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}\n<${env.BUILD_URL}|View Build>"
            )
        }
        
        failure {
            slackSend(
                color: 'danger',
                message: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}\n<${env.BUILD_URL}console|View Log>"
            )
        }
    }
}
```

---

## 八、完整实战案例

### 案例1：Spring Boot 微服务 CI/CD

```groovy
pipeline {
    agent any
    
    environment {
        // 应用信息
        APP_NAME = 'user-service'
        APP_VERSION = "${env.BUILD_NUMBER}"
        
        // Docker 配置
        DOCKER_REGISTRY = 'registry.example.com'
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/${APP_NAME}"
        
        // Kubernetes 配置
        K8S_NAMESPACE = 'production'
        K8S_DEPLOYMENT = "${APP_NAME}"
    }
    
    tools {
        maven 'Maven-3.8'
        jdk 'JDK-11'
    }
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'test', 'prod'], description: '部署环境')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: '跳过测试')
        booleanParam(name: 'DEPLOY', defaultValue: true, description: '是否部署')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_MSG = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                    env.GIT_AUTHOR = sh(script: 'git log -1 --pretty=%an', returnStdout: true).trim()
                }
            }
        }
        
        stage('Build') {
            steps {
                echo "Building ${APP_NAME} version ${APP_VERSION}"
                sh 'mvn clean package -DskipTests=${params.SKIP_TESTS}'
            }
        }
        
        stage('Unit Tests') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco execPattern: 'target/jacoco.exec'
                }
            }
        }
        
        stage('Code Quality') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${APP_VERSION}")
                    docker.build("${DOCKER_IMAGE}:latest")
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials') {
                        docker.image("${DOCKER_IMAGE}:${APP_VERSION}").push()
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }
        
        stage('Deploy to Dev') {
            when {
                expression { params.ENVIRONMENT == 'dev' && params.DEPLOY }
            }
            steps {
                sh """
                    kubectl set image deployment/${K8S_DEPLOYMENT} \
                        ${APP_NAME}=${DOCKER_IMAGE}:${APP_VERSION} \
                        -n dev
                    kubectl rollout status deployment/${K8S_DEPLOYMENT} -n dev
                """
            }
        }
        
        stage('Integration Tests') {
            when {
                expression { params.ENVIRONMENT == 'dev' }
            }
            steps {
                sh 'mvn verify -Pintegration-test'
            }
        }
        
        stage('Deploy to Test') {
            when {
                expression { params.ENVIRONMENT == 'test' && params.DEPLOY }
            }
            steps {
                sh """
                    kubectl set image deployment/${K8S_DEPLOYMENT} \
                        ${APP_NAME}=${DOCKER_IMAGE}:${APP_VERSION} \
                        -n test
                    kubectl rollout status deployment/${K8S_DEPLOYMENT} -n test
                """
            }
        }
        
        stage('Approval for Production') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: '确认部署到生产环境？',
                          ok: '确认部署',
                          submitter: 'admin,ops-lead'
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                expression { params.ENVIRONMENT == 'prod' && params.DEPLOY }
            }
            steps {
                sh """
                    # 滚动更新
                    kubectl set image deployment/${K8S_DEPLOYMENT} \
                        ${APP_NAME}=${DOCKER_IMAGE}:${APP_VERSION} \
                        -n ${K8S_NAMESPACE}
                    
                    # 等待部署完成
                    kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE}
                    
                    # 验证部署
                    kubectl get pods -n ${K8S_NAMESPACE} -l app=${APP_NAME}
                """
            }
        }
        
        stage('Smoke Tests') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                sh '''
                    # 健康检查
                    curl -f http://api.example.com/health || exit 1
                    
                    # 基本功能测试
                    curl -f http://api.example.com/api/users || exit 1
                '''
            }
        }
    }
    
    post {
        success {
            script {
                def message = """
                    ✅ 构建和部署成功
                    
                    项目: ${APP_NAME}
                    版本: ${APP_VERSION}
                    环境: ${params.ENVIRONMENT}
                    分支: ${env.GIT_BRANCH}
                    提交: ${env.GIT_COMMIT_MSG}
                    作者: ${env.GIT_AUTHOR}
                    
                    查看详情: ${env.BUILD_URL}
                """
                
                emailext(
                    subject: "✅ ${APP_NAME} 部署成功 - ${params.ENVIRONMENT}",
                    body: message,
                    to: 'team@example.com'
                )
                
                dingtalk(
                    robot: 'jenkins-robot',
                    type: 'MARKDOWN',
                    title: '部署成功',
                    text: [message]
                )
            }
        }
        
        failure {
            script {
                def message = """
                    ❌ 构建或部署失败
                    
                    项目: ${APP_NAME}
                    环境: ${params.ENVIRONMENT}
                    分支: ${env.GIT_BRANCH}
                    
                    查看日志: ${env.BUILD_URL}console
                """
                
                emailext(
                    subject: "❌ ${APP_NAME} 部署失败 - ${params.ENVIRONMENT}",
                    body: message,
                    to: 'team@example.com'
                )
                
                dingtalk(
                    robot: 'jenkins-robot',
                    type: 'MARKDOWN',
                    title: '部署失败',
                    text: [message],
                    at: ['18888888888']
                )
            }
        }
        
        always {
            cleanWs()
        }
    }
}
```

---

## 九、最佳实践

### 9.1 Pipeline 设计原则

1. **保持简洁**：每个 stage 职责单一
2. **快速失败**：尽早发现问题
3. **并行执行**：提高构建速度
4. **可重用**：使用共享库
5. **版本控制**：Jenkinsfile 纳入版本管理

### 9.2 性能优化

```groovy
pipeline {
    agent any
    
    options {
        // 限制保留构建数量
        buildDiscarder(logRotator(numToKeepStr: '10'))
        
        // 禁用并发构建
        disableConcurrentBuilds()
        
        // 设置超时
        timeout(time: 1, unit: 'HOURS')
        
        // 跳过默认 checkout
        skipDefaultCheckout()
    }
    
    stages {
        stage('Checkout') {
            steps {
                // 浅克隆
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [[$class: 'CloneOption', depth: 1, shallow: true]],
                    userRemoteConfigs: [[url: 'https://github.com/user/repo.git']]
                ])
            }
        }
    }
}
```

### 9.3 安全最佳实践

```groovy
pipeline {
    agent any
    
    environment {
        // 使用凭据
        DB_PASSWORD = credentials('db-password')
        API_KEY = credentials('api-key')
    }
    
    stages {
        stage('Deploy') {
            steps {
                // 使用凭据绑定
                withCredentials([
                    usernamePassword(
                        credentialsId: 'ssh-credentials',
                        usernameVariable: 'SSH_USER',
                        passwordVariable: 'SSH_PASS'
                    )
                ]) {
                    sh '''
                        sshpass -p "$SSH_PASS" ssh $SSH_USER@server "deploy.sh"
                    '''
                }
            }
        }
    }
}
```

---

## 十、故障排查

### 10.1 常见问题

#### 问题1：Pipeline 语法错误

```bash
# 使用 Pipeline Syntax 生成器
Jenkins → Pipeline Job → Pipeline Syntax

# 验证 Jenkinsfile
curl -X POST -F "jenkinsfile=<Jenkinsfile" \
  http://jenkins.example.com:8080/pipeline-model-converter/validate
```

#### 问题2：构建超时

```groovy
pipeline {
    options {
        timeout(time: 2, unit: 'HOURS')
    }
    
    stages {
        stage('Long Running Task') {
            options {
                timeout(time: 30, unit: 'MINUTES')
            }
            steps {
                sh 'long-task.sh'
            }
        }
    }
}
```

#### 问题3：工作空间清理

```groovy
pipeline {
    agent any
    
    post {
        always {
            cleanWs()
        }
    }
}
```

---

## 十一、总结

本节学习了：

✅ Jenkinsfile 编写  
✅ Declarative Pipeline 高级特性  
✅ Scripted Pipeline 高级特性  
✅ Docker 和 Kubernetes 集成  
✅ 自动化测试集成  
✅ 通知和监控  
✅ 完整 CI/CD 实战案例  
✅ 最佳实践和故障排查  

**恭喜！** 你已经掌握了 Jenkins 的核心技能，可以实现企业级 CI/CD 流程了！

---

## 参考资料

- [Jenkins Pipeline 文档](https://www.jenkins.io/doc/book/pipeline/)
- [Pipeline 语法参考](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Pipeline 步骤参考](https://www.jenkins.io/doc/pipeline/steps/)
- [共享库文档](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
