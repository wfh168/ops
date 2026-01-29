# Git 工作流

## 📚 本节目标

- 理解 Git Flow 工作流
- 掌握 GitHub Flow
- 了解 GitLab Flow
- 掌握团队协作规范
- 理解代码审查流程
- 了解持续集成

---

## 1. Git Flow 工作流

### 1.1 Git Flow 简介

Git Flow 是一套基于 Git 的分支管理策略，由 Vincent Driessen 提出。

**分支类型**：
- `master`：主分支，存放稳定的生产代码
- `develop`：开发分支，最新的开发代码
- `feature/*`：功能分支，开发新功能
- `release/*`：发布分支，准备发布
- `hotfix/*`：热修复分支，紧急修复生产问题

### 1.2 分支模型

```
master  ─────●─────────●─────────●───
              ↑         ↑         ↑
              │         │         │
develop ──●───┴───●─────┴───●─────┴───
          │       │         │
feature   └───●───┘         │
                            │
release                     └───●───
                                │
hotfix                          └───●───
```

### 1.3 功能开发流程

```bash
# 1. 从 develop 创建功能分支
git checkout develop
git checkout -b feature/user-profile

# 2. 开发功能
echo "用户资料功能" > profile.py
git add profile.py
git commit -m "feat: 添加用户资料功能"

# 3. 继续开发
echo "完善功能" >> profile.py
git commit -am "feat: 完善用户资料"

# 4. 合并到 develop
git checkout develop
git merge --no-ff feature/user-profile -m "merge: 合并用户资料功能"

# 5. 删除功能分支
git branch -d feature/user-profile

# 6. 推送
git push origin develop
```

### 1.4 发布流程

```bash
# 1. 从 develop 创建发布分支
git checkout develop
git checkout -b release/v1.0.0

# 2. 更新版本号
echo "version = '1.0.0'" > version.py
git commit -am "chore: 更新版本号为 1.0.0"

# 3. 修复发布前的 bug
# ...

# 4. 合并到 master
git checkout master
git merge --no-ff release/v1.0.0 -m "release: 发布 v1.0.0"

# 5. 打标签
git tag -a v1.0.0 -m "Release version 1.0.0"

# 6. 合并回 develop
git checkout develop
git merge --no-ff release/v1.0.0 -m "merge: 合并发布分支"

# 7. 删除发布分支
git branch -d release/v1.0.0

# 8. 推送
git push origin master
git push origin develop
git push origin --tags
```

### 1.5 热修复流程

```bash
# 1. 从 master 创建热修复分支
git checkout master
git checkout -b hotfix/critical-bug

# 2. 修复 bug
echo "修复严重 bug" > fix.py
git add fix.py
git commit -m "fix: 修复严重 bug"

# 3. 合并到 master
git checkout master
git merge --no-ff hotfix/critical-bug -m "hotfix: 修复严重 bug"

# 4. 打标签
git tag -a v1.0.1 -m "Hotfix version 1.0.1"

# 5. 合并到 develop
git checkout develop
git merge --no-ff hotfix/critical-bug -m "merge: 合并热修复"

# 6. 删除热修复分支
git branch -d hotfix/critical-bug

# 7. 推送
git push origin master
git push origin develop
git push origin --tags
```

### 1.6 Git Flow 工具

```bash
# 安装 git-flow
# Mac
brew install git-flow

# Linux
apt-get install git-flow

# 初始化
git flow init

# 开始功能开发
git flow feature start user-profile

# 完成功能开发
git flow feature finish user-profile

# 开始发布
git flow release start v1.0.0

# 完成发布
git flow release finish v1.0.0

# 开始热修复
git flow hotfix start critical-bug

# 完成热修复
git flow hotfix finish critical-bug
```

---

## 2. GitHub Flow

### 2.1 GitHub Flow 简介

GitHub Flow 是一个轻量级的工作流，适合持续部署。

**核心原则**：
- `master` 分支永远可部署
- 从 `master` 创建描述性分支
- 定期推送到远程
- 通过 Pull Request 合并
- 合并后立即部署

### 2.2 工作流程

```bash
# 1. 创建分支
git checkout master
git pull origin master
git checkout -b feature/add-payment

# 2. 开发并提交
echo "支付功能" > payment.py
git add payment.py
git commit -m "feat: 添加支付功能"

# 3. 推送到远程
git push -u origin feature/add-payment

# 4. 创建 Pull Request
# 在 GitHub 上创建 PR

# 5. 代码审查和讨论
# 团队成员审查代码

# 6. 部署测试
# 在测试环境部署

# 7. 合并到 master
# 在 GitHub 上合并 PR

# 8. 部署到生产环境
# 自动或手动部署

# 9. 删除分支
git branch -d feature/add-payment
git push origin --delete feature/add-payment
```

### 2.3 Pull Request 最佳实践

**创建 PR**：
- 标题清晰简洁
- 描述详细完整
- 关联相关 Issue
- 添加截图或演示
- 标记审查者

**代码审查**：
- 仔细阅读代码
- 提供建设性意见
- 关注代码质量
- 检查测试覆盖
- 及时反馈

**合并 PR**：
- 确保 CI 通过
- 获得足够的审查
- 解决所有评论
- 使用 Squash 合并（可选）

---

## 3. GitLab Flow

### 3.1 GitLab Flow 简介

GitLab Flow 结合了 Git Flow 和 GitHub Flow 的优点。

**环境分支**：
- `master`：开发分支
- `pre-production`：预生产环境
- `production`：生产环境

### 3.2 环境分支流程

```bash
# 1. 在 master 开发
git checkout master
git checkout -b feature/new-feature
# 开发...
git push origin feature/new-feature
# 创建 MR 合并到 master

# 2. 部署到预生产
git checkout pre-production
git merge master
git push origin pre-production
# 自动部署到预生产环境

# 3. 部署到生产
git checkout production
git merge pre-production
git push origin production
# 自动部署到生产环境
```

### 3.3 发布分支流程

```bash
# 1. 创建发布分支
git checkout -b release/v1.0.0 master

# 2. 修复 bug
# 在 release 分支修复
git commit -am "fix: 修复 bug"

# 3. 合并回 master
git checkout master
git merge release/v1.0.0

# 4. 打标签
git tag -a v1.0.0 -m "Release 1.0.0"

# 5. 部署
git push origin master --tags
```

---

## 4. 团队协作规范

### 4.1 分支命名规范

```
功能分支：
feature/功能名称
feature/user-auth
feature/payment-gateway

Bug 修复：
bugfix/bug描述
bugfix/login-error
bugfix/memory-leak

热修复：
hotfix/紧急问题
hotfix/security-patch
hotfix/critical-bug

发布分支：
release/版本号
release/v1.0.0
release/v2.1.0

测试分支：
test/测试内容
test/performance
test/integration
```

### 4.2 提交信息规范

**格式**：
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型**：
```
feat:     新功能
fix:      修复 bug
docs:     文档更新
style:    代码格式（不影响代码运行）
refactor: 重构
perf:     性能优化
test:     测试相关
chore:    构建过程或辅助工具
revert:   回退
```

**示例**：
```bash
# 简单提交
git commit -m "feat: 添加用户登录功能"

# 详细提交
git commit -m "feat(auth): 添加用户登录功能

- 实现用户名密码登录
- 添加记住我功能
- 集成第三方登录

Closes #123"
```

### 4.3 代码审查规范

**审查清单**：
- [ ] 代码符合编码规范
- [ ] 功能实现正确
- [ ] 测试覆盖充分
- [ ] 文档更新完整
- [ ] 性能影响可接受
- [ ] 安全问题已考虑
- [ ] 无明显 bug

**审查意见**：
```
✅ LGTM (Looks Good To Me)
💡 建议：可以考虑...
❓ 问题：这里为什么...
⚠️ 警告：这可能导致...
🔴 必须修改：这里有严重问题...
```

### 4.4 合并策略

**Merge Commit**：
```bash
git merge --no-ff feature-branch
```
- 保留完整历史
- 清晰看出功能分支
- 历史图复杂

**Squash Merge**：
```bash
git merge --squash feature-branch
git commit -m "feat: 完成某功能"
```
- 压缩为单个提交
- 历史简洁
- 丢失详细历史

**Rebase Merge**：
```bash
git rebase master
git checkout master
git merge feature-branch
```
- 线性历史
- 清晰简洁
- 改变历史

---

## 5. 持续集成

### 5.1 CI/CD 概念

**持续集成（CI）**：
- 频繁地将代码集成到主干
- 自动运行测试
- 快速发现问题

**持续部署（CD）**：
- 自动部署到生产环境
- 快速交付价值
- 减少人工错误

### 5.2 GitHub Actions

创建 `.github/workflows/ci.yml`：
```yaml
name: CI

on:
  push:
    branches: [ master, develop ]
  pull_request:
    branches: [ master, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '14'
    
    - name: Install dependencies
      run: npm install
    
    - name: Run tests
      run: npm test
    
    - name: Run linter
      run: npm run lint
    
    - name: Build
      run: npm run build
```

### 5.3 GitLab CI

创建 `.gitlab-ci.yml`：
```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  script:
    - npm install
    - npm test
    - npm run lint

build:
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  only:
    - master
```

---

## 6. 实战案例

### 案例1：Git Flow 完整流程

```bash
# 初始化项目
git init
git commit --allow-empty -m "init: 初始化项目"
git branch develop
git push -u origin master develop

# 开发功能
git checkout develop
git checkout -b feature/user-system
# 开发...
git commit -am "feat: 完成用户系统"
git checkout develop
git merge --no-ff feature/user-system
git push origin develop

# 准备发布
git checkout -b release/v1.0.0 develop
echo "1.0.0" > VERSION
git commit -am "chore: 更新版本号"
git checkout master
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release 1.0.0"
git checkout develop
git merge --no-ff release/v1.0.0
git push origin master develop --tags

# 紧急修复
git checkout -b hotfix/security-patch master
# 修复...
git commit -am "fix: 修复安全漏洞"
git checkout master
git merge --no-ff hotfix/security-patch
git tag -a v1.0.1 -m "Hotfix 1.0.1"
git checkout develop
git merge --no-ff hotfix/security-patch
git push origin master develop --tags
```

### 案例2：GitHub Flow 团队协作

```bash
# 开发者 A
git checkout master
git pull origin master
git checkout -b feature/add-search
# 开发...
git push -u origin feature/add-search
# 创建 PR

# 开发者 B（审查）
# 在 GitHub 上审查代码
# 提供反馈

# 开发者 A（修改）
# 根据反馈修改
git commit -am "refactor: 优化搜索算法"
git push origin feature/add-search

# 开发者 B（批准并合并）
# 在 GitHub 上合并 PR

# 开发者 A（清理）
git checkout master
git pull origin master
git branch -d feature/add-search
```

---

## 7. 常见问题

### 问题1：分支太多难以管理

```bash
# 定期清理已合并的分支
git branch --merged | grep -v "\*" | grep -v "master" | grep -v "develop" | xargs -n 1 git branch -d

# 清理远程已删除的分支
git fetch -p
```

### 问题2：提交历史混乱

```bash
# 使用 rebase 整理提交
git rebase -i HEAD~5

# 使用 squash 合并提交
git merge --squash feature-branch
```

### 问题3：忘记从正确的分支创建功能分支

```bash
# 方法1：rebase 到正确的分支
git rebase --onto develop master feature-branch

# 方法2：cherry-pick 提交
git checkout develop
git checkout -b feature-branch-new
git cherry-pick commit1 commit2
```

---

## 8. 最佳实践

### 1. 选择合适的工作流
- 小团队：GitHub Flow
- 大团队：Git Flow
- 持续部署：GitHub Flow
- 多环境：GitLab Flow

### 2. 保持分支简洁
- 及时合并功能分支
- 定期清理已合并的分支
- 避免长期存在的分支

### 3. 规范提交
- 使用统一的提交格式
- 提交信息清晰明确
- 一次提交只做一件事

### 4. 代码审查
- 所有代码都要审查
- 及时响应审查意见
- 保持友好和建设性

---

## 9. 练习题

### 练习1：Git Flow 实践
1. 初始化 Git Flow
2. 开发一个功能
3. 准备发布
4. 进行热修复

### 练习2：GitHub Flow 实践
1. 创建功能分支
2. 推送并创建 PR
3. 进行代码审查
4. 合并 PR

### 练习3：团队协作
1. 多人协作开发
2. 解决合并冲突
3. 进行代码审查
4. 发布版本

---

## 10. 小结

本节学习了：

✅ Git Flow 工作流  
✅ GitHub Flow  
✅ GitLab Flow  
✅ 团队协作规范  
✅ 代码审查流程  
✅ 持续集成  

**下一节**：我们将学习 Git 实战应用和最佳实践！

---

**继续加油！** 💪🚀
