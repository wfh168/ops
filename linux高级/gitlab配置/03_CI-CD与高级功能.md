# GitLab CI/CD 与高级功能

## 一、GitLab CI/CD 概述

### 1.1 什么是 CI/CD

**CI（Continuous Integration）持续集成**：
- 频繁地将代码集成到主分支
- 自动化构建和测试
- 快速发现和修复问题

**CD（Continuous Delivery/Deployment）持续交付/部署**：
- 持续交付：自动化部署到测试环境
- 持续部署：自动化部署到生产环境

### 1.2 GitLab CI/CD 架构

```
                GitLab CI/CD 架构
                        |
        +---------------+---------------+
        |               |               |
    [GitLab]        [Runner]        [应用]
    (协调器)        (执行器)        (目标)
        |               |               |
    .gitlab-ci.yml  执行 Job      部署应用
```

**核心组件**：
- **.gitlab-ci.yml**：CI/CD 配置文件
- **GitLab Runner**：任务执行器
- **Pipeline**：流水线
- **Job**：具体任务
- **Stage**：阶段

---

## 二、GitLab Runner

### 2.1 安装 Runner

#### Linux 安装

```bash
# 添加官方仓库
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash

# 安装 GitLab Runner
sudo yum install gitlab-runner

# 或 Ubuntu
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner
```

#### Docker 安装

```bash
# 运行 Runner 容器
docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
```

### 2.2 注册 Runner

```bash
# 注册 Runner
sudo gitlab-runner register

# 交互式配置：
# GitLab URL: https://gitlab.example.com
# Registration token: 从 GitLab 获取
# Description: my-runner
# Tags: docker,linux
# Executor: docker
# Default Docker image: alpine:latest
```

**获取 Registration Token**：
```
# 项目级 Runner
Project → Settings → CI/CD → Runners

# 组级 Runner
Group → Settings → CI/CD → Runners

# 实例级 Runner（管理员）
Admin Area → Runners
```

### 2.3 Runner 类型

| 类型 | 说明 | 适用场景 |
|------|------|----------|
| **Shared Runner** | 共享 Runner | 所有项目可用 |
| **Group Runner** | 组 Runner | 组内项目可用 |
| **Specific Runner** | 项目 Runner | 特定项目专用 ⭐ |

### 2.4 Executor 类型

| Executor | 说明 | 优缺点 |
|----------|------|--------|
| **Shell** | 直接在主机执行 | 简单但不隔离 |
| **Docker** | 在容器中执行 | 隔离性好 ⭐ |
| **Docker+Machine** | 自动扩展 | 适合大规模 |
| **Kubernetes** | K8s 集群 | 云原生 |

---

## 三、.gitlab-ci.yml 配置

### 3.1 基本结构

```yaml
# 定义阶段
stages:
  - build
  - test
  - deploy

# 定义变量
variables:
  APP_NAME: "myapp"
  VERSION: "1.0.0"

# 构建任务
build_job:
  stage: build
  script:
    - echo "Building application..."
    - npm install
    - npm run build
  artifacts:
    paths:
      - dist/

# 测试任务
test_job:
  stage: test
  script:
    - echo "Running tests..."
    - npm run test

# 部署任务
deploy_job:
  stage: deploy
  script:
    - echo "Deploying application..."
    - scp -r dist/* user@server:/var/www/html/
  only:
    - main
```

### 3.2 关键字详解

#### stages（阶段）

```yaml
stages:
  - build      # 构建阶段
  - test       # 测试阶段
  - deploy     # 部署阶段
  - cleanup    # 清理阶段
```

#### script（脚本）

```yaml
job_name:
  script:
    - echo "Step 1"
    - echo "Step 2"
    - |
      echo "Multi-line"
      echo "script"
```

#### before_script 和 after_script

```yaml
job_name:
  before_script:
    - echo "Before job"
  script:
    - echo "Main job"
  after_script:
    - echo "After job"
```

#### only 和 except

```yaml
# 只在 main 分支运行
deploy_prod:
  script: deploy.sh
  only:
    - main

# 除了 develop 分支都运行
test_job:
  script: test.sh
  except:
    - develop

# 只在标签时运行
release_job:
  script: release.sh
  only:
    - tags
```

#### when（执行时机）

```yaml
job_name:
  script: echo "Hello"
  when: on_success  # 前面任务成功时执行（默认）
  # when: on_failure  # 前面任务失败时执行
  # when: always      # 总是执行
  # when: manual      # 手动触发
```

#### artifacts（制品）

```yaml
build_job:
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
      - build/
    expire_in: 1 week  # 保留时间
    name: "$CI_JOB_NAME-$CI_COMMIT_REF_NAME"
```

#### cache（缓存）

```yaml
job_name:
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths:
      - node_modules/
      - .npm/
```

#### dependencies（依赖）

```yaml
test_job:
  stage: test
  dependencies:
    - build_job  # 依赖 build_job 的 artifacts
  script:
    - npm run test
```

---

## 四、实战案例

### 案例1：Node.js 项目 CI/CD

```yaml
image: node:14

stages:
  - install
  - test
  - build
  - deploy

variables:
  npm_config_cache: "$CI_PROJECT_DIR/.npm"

cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .npm/

# 安装依赖
install_dependencies:
  stage: install
  script:
    - npm ci
  artifacts:
    paths:
      - node_modules/
    expire_in: 1 day

# 代码检查
lint:
  stage: test
  dependencies:
    - install_dependencies
  script:
    - npm run lint

# 单元测试
unit_test:
  stage: test
  dependencies:
    - install_dependencies
  script:
    - npm run test
  coverage: '/Statements\s*:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      junit: junit.xml
      cobertura: coverage/cobertura-coverage.xml

# 构建
build:
  stage: build
  dependencies:
    - install_dependencies
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

# 部署到测试环境
deploy_staging:
  stage: deploy
  dependencies:
    - build
  script:
    - echo "Deploying to staging..."
    - scp -r dist/* user@staging-server:/var/www/html/
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - develop

# 部署到生产环境
deploy_production:
  stage: deploy
  dependencies:
    - build
  script:
    - echo "Deploying to production..."
    - scp -r dist/* user@prod-server:/var/www/html/
  environment:
    name: production
    url: https://www.example.com
  when: manual  # 手动触发
  only:
    - main
```

### 案例2：Java Maven 项目

```yaml
image: maven:3.8-jdk-11

stages:
  - build
  - test
  - package
  - deploy

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"

cache:
  paths:
    - .m2/repository/

# 编译
build:
  stage: build
  script:
    - mvn clean compile

# 测试
test:
  stage: test
  script:
    - mvn test
  artifacts:
    reports:
      junit:
        - target/surefire-reports/TEST-*.xml

# 打包
package:
  stage: package
  script:
    - mvn package -DskipTests
  artifacts:
    paths:
      - target/*.jar
    expire_in: 1 week

# 部署
deploy:
  stage: deploy
  script:
    - echo "Deploying application..."
    - scp target/*.jar user@server:/opt/app/
    - ssh user@server "systemctl restart myapp"
  only:
    - main
```

### 案例3：Docker 镜像构建

```yaml
image: docker:latest

services:
  - docker:dind

variables:
  DOCKER_DRIVER: overlay2
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

stages:
  - build
  - test
  - push

before_script:
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

# 构建镜像
build_image:
  stage: build
  script:
    - docker build -t $IMAGE_TAG .
    - docker tag $IMAGE_TAG $CI_REGISTRY_IMAGE:latest

# 测试镜像
test_image:
  stage: test
  script:
    - docker run --rm $IMAGE_TAG npm test

# 推送镜像
push_image:
  stage: push
  script:
    - docker push $IMAGE_TAG
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
```

---

## 五、环境管理

### 5.1 定义环境

```yaml
deploy_staging:
  stage: deploy
  script:
    - deploy.sh staging
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop_staging

deploy_production:
  stage: deploy
  script:
    - deploy.sh production
  environment:
    name: production
    url: https://www.example.com
  when: manual

stop_staging:
  stage: deploy
  script:
    - cleanup.sh staging
  environment:
    name: staging
    action: stop
  when: manual
```

### 5.2 查看环境

```
Project → Deployments → Environments
```

---

## 六、变量管理

### 6.1 预定义变量

GitLab 提供了许多预定义变量：

```yaml
job_name:
  script:
    - echo "Project: $CI_PROJECT_NAME"
    - echo "Branch: $CI_COMMIT_REF_NAME"
    - echo "Commit: $CI_COMMIT_SHA"
    - echo "Pipeline ID: $CI_PIPELINE_ID"
    - echo "Job ID: $CI_JOB_ID"
```

**常用变量**：
- `CI_PROJECT_NAME`：项目名称
- `CI_COMMIT_REF_NAME`：分支或标签名
- `CI_COMMIT_SHA`：提交 SHA
- `CI_PIPELINE_ID`：Pipeline ID
- `CI_JOB_ID`：Job ID
- `CI_REGISTRY`：容器镜像仓库地址

### 6.2 自定义变量

#### 在 .gitlab-ci.yml 中定义

```yaml
variables:
  APP_NAME: "myapp"
  VERSION: "1.0.0"
  DEPLOY_SERVER: "prod.example.com"

job_name:
  script:
    - echo "Deploying $APP_NAME version $VERSION to $DEPLOY_SERVER"
```

#### 在 GitLab 界面中定义

```
Project → Settings → CI/CD → Variables

配置：
- Key：变量名
- Value：变量值
- Type：Variable 或 File
- Environment scope：环境范围
- Protect variable：保护变量
- Mask variable：掩码变量
```

---

## 七、高级功能

### 7.1 Include（包含）

```yaml
# 包含其他 YAML 文件
include:
  - local: '/templates/.gitlab-ci-template.yml'
  - project: 'group/project'
    file: '/templates/.gitlab-ci-template.yml'
  - remote: 'https://example.com/ci-template.yml'
  - template: 'Auto-DevOps.gitlab-ci.yml'
```

### 7.2 Extends（继承）

```yaml
.deploy_template:
  script:
    - deploy.sh
  only:
    - main

deploy_staging:
  extends: .deploy_template
  environment:
    name: staging

deploy_production:
  extends: .deploy_template
  environment:
    name: production
  when: manual
```

### 7.3 Needs（并行）

```yaml
# 默认按 stage 顺序执行
# 使用 needs 可以并行执行

build:
  stage: build
  script: build.sh

test:unit:
  stage: test
  needs: [build]  # 只依赖 build
  script: test-unit.sh

test:integration:
  stage: test
  needs: [build]  # 只依赖 build
  script: test-integration.sh

deploy:
  stage: deploy
  needs: [test:unit, test:integration]
  script: deploy.sh
```

### 7.4 Rules（规则）

```yaml
job_name:
  script: echo "Hello"
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: always
    - if: '$CI_COMMIT_BRANCH == "develop"'
      when: manual
    - when: never
```

---

## 八、备份和恢复

### 8.1 备份

```bash
# 创建备份
sudo gitlab-backup create

# 备份文件位置
ls -lh /var/opt/gitlab/backups/

# 备份配置文件
sudo cp /etc/gitlab/gitlab.rb /backup/
sudo cp /etc/gitlab/gitlab-secrets.json /backup/
```

### 8.2 自动备份

```bash
# 添加到 crontab
sudo crontab -e

# 每天凌晨 2 点备份
0 2 * * * /opt/gitlab/bin/gitlab-backup create CRON=1
```

### 8.3 恢复

```bash
# 停止服务
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq

# 恢复备份
sudo gitlab-backup restore BACKUP=1640000000_2024_01_29_15.8.0

# 恢复配置文件
sudo cp /backup/gitlab.rb /etc/gitlab/
sudo cp /backup/gitlab-secrets.json /etc/gitlab/

# 重新配置并启动
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart

# 检查
sudo gitlab-rake gitlab:check SANITIZE=true
```

---

## 九、监控和日志

### 9.1 查看日志

```bash
# 查看所有日志
sudo gitlab-ctl tail

# 查看特定服务日志
sudo gitlab-ctl tail nginx
sudo gitlab-ctl tail gitlab-rails
sudo gitlab-ctl tail sidekiq

# 日志文件位置
/var/log/gitlab/
```

### 9.2 性能监控

```
Admin Area → Monitoring → Performance

监控指标：
- CPU 使用率
- 内存使用率
- 磁盘 I/O
- 网络流量
- 请求响应时间
```

---

## 十、总结

本节学习了：

✅ GitLab CI/CD 概念和架构  
✅ GitLab Runner 安装和配置  
✅ .gitlab-ci.yml 编写  
✅ 实战案例（Node.js、Java、Docker）  
✅ 环境和变量管理  
✅ 高级功能（Include、Extends、Needs、Rules）  
✅ 备份和恢复  
✅ 监控和日志  

**恭喜你完成了 GitLab 配置的学习！**

---

## 参考资料

- [GitLab CI/CD 文档](https://docs.gitlab.com/ee/ci/)
- [.gitlab-ci.yml 参考](https://docs.gitlab.com/ee/ci/yaml/)
- [GitLab Runner 文档](https://docs.gitlab.com/runner/)
