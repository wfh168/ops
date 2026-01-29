# Git 远程协作

## 📚 本节目标

- 理解远程仓库的概念
- 掌握 GitHub/GitLab 的使用
- 掌握远程仓库操作
- 能够进行团队协作
- 掌握 Fork 和 Pull Request
- 理解 SSH 密钥配置

---

## 1. 远程仓库概念

### 1.1 什么是远程仓库

远程仓库是托管在网络上的项目版本库，可以是 GitHub、GitLab、Gitee 等平台。

**远程仓库的作用**：
- 📦 代码备份
- 👥 团队协作
- 🌍 开源分享
- 🔄 版本同步
- 📊 项目管理

### 1.2 常见远程仓库平台

**GitHub**：
- 全球最大的代码托管平台
- 开源项目首选
- 免费私有仓库
- 强大的社区

**GitLab**：
- 支持私有部署
- 内置 CI/CD
- 企业级功能
- 免费私有仓库

**Gitee（码云）**：
- 国内访问速度快
- 中文界面
- 免费私有仓库
- 适合国内团队

---

## 2. GitHub 使用

### 2.1 注册 GitHub 账号

1. 访问 https://github.com
2. 点击 "Sign up" 注册
3. 填写用户名、邮箱、密码
4. 验证邮箱

### 2.2 创建仓库

**方法1：通过网页创建**
1. 登录 GitHub
2. 点击右上角 "+" → "New repository"
3. 填写仓库名称和描述
4. 选择公开或私有
5. 可选：添加 README、.gitignore、LICENSE
6. 点击 "Create repository"

**方法2：通过命令行创建**
```bash
# 使用 GitHub CLI
gh repo create myproject --public
```

### 2.3 SSH 密钥配置

**生成 SSH 密钥**：
```bash
# 生成密钥（使用你的 GitHub 邮箱）
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 按 Enter 使用默认路径
# 可选：设置密码短语

# 查看公钥
cat ~/.ssh/id_rsa.pub
```

**添加到 GitHub**：
1. 复制公钥内容
2. 登录 GitHub
3. 点击头像 → Settings
4. 左侧菜单 → SSH and GPG keys
5. 点击 "New SSH key"
6. 粘贴公钥，添加标题
7. 点击 "Add SSH key"

**测试连接**：
```bash
ssh -T git@github.com
# 输出：Hi username! You've successfully authenticated...
```

---

## 3. 远程仓库操作

### 3.1 查看远程仓库

```bash
# 查看远程仓库
git remote

# 查看远程仓库详细信息
git remote -v

# 查看指定远程仓库信息
git remote show origin
```

### 3.2 添加远程仓库

```bash
# 添加远程仓库
git remote add origin git@github.com:username/repo.git

# 添加多个远程仓库
git remote add github git@github.com:username/repo.git
git remote add gitlab git@gitlab.com:username/repo.git
```

### 3.3 修改远程仓库

```bash
# 修改远程仓库 URL
git remote set-url origin git@github.com:username/newrepo.git

# 重命名远程仓库
git remote rename origin upstream

# 删除远程仓库
git remote remove origin
```

### 3.4 克隆仓库

```bash
# 克隆仓库
git clone git@github.com:username/repo.git

# 克隆到指定目录
git clone git@github.com:username/repo.git myproject

# 克隆指定分支
git clone -b dev git@github.com:username/repo.git

# 浅克隆（只克隆最近的提交）
git clone --depth 1 git@github.com:username/repo.git
```

---

## 4. 推送和拉取

### 4.1 推送到远程

```bash
# 推送到远程仓库
git push origin master

# 首次推送并设置上游分支
git push -u origin master

# 推送所有分支
git push origin --all

# 推送标签
git push origin --tags

# 强制推送（谨慎使用）
git push -f origin master
```

### 4.2 从远程拉取

```bash
# 拉取并合并
git pull origin master

# 等价于
git fetch origin
git merge origin/master

# 拉取并变基
git pull --rebase origin master
```

### 4.3 获取远程更新

```bash
# 获取远程仓库更新（不合并）
git fetch origin

# 获取所有远程仓库更新
git fetch --all

# 获取并清理远程已删除的分支
git fetch -p
git fetch --prune
```

---

## 5. 分支协作

### 5.1 跟踪远程分支

```bash
# 创建本地分支跟踪远程分支
git checkout -b dev origin/dev

# 或使用
git checkout --track origin/dev

# 设置已存在分支的上游分支
git branch --set-upstream-to=origin/dev dev
```

### 5.2 推送本地分支

```bash
# 推送本地分支到远程
git push origin dev

# 推送并设置上游分支
git push -u origin dev

# 推送本地分支到不同名称的远程分支
git push origin local-branch:remote-branch
```

### 5.3 删除远程分支

```bash
# 删除远程分支
git push origin --delete dev

# 或使用
git push origin :dev
```

### 5.4 查看远程分支

```bash
# 查看远程分支
git branch -r

# 查看所有分支
git branch -a

# 查看远程分支详细信息
git remote show origin
```

---

## 6. Fork 和 Pull Request

### 6.1 Fork 项目

**什么是 Fork**：
- 复制别人的仓库到自己账号下
- 可以自由修改而不影响原仓库
- 用于贡献开源项目

**Fork 步骤**：
1. 访问要 Fork 的项目
2. 点击右上角 "Fork" 按钮
3. 选择 Fork 到的账号
4. 等待 Fork 完成

### 6.2 克隆 Fork 的仓库

```bash
# 克隆你 Fork 的仓库
git clone git@github.com:your-username/repo.git
cd repo

# 添加原仓库为上游仓库
git remote add upstream git@github.com:original-owner/repo.git

# 查看远程仓库
git remote -v
# origin    git@github.com:your-username/repo.git (fetch)
# origin    git@github.com:your-username/repo.git (push)
# upstream  git@github.com:original-owner/repo.git (fetch)
# upstream  git@github.com:original-owner/repo.git (push)
```

### 6.3 同步上游仓库

```bash
# 获取上游仓库更新
git fetch upstream

# 切换到主分支
git checkout master

# 合并上游更新
git merge upstream/master

# 推送到你的远程仓库
git push origin master
```

### 6.4 创建 Pull Request

**步骤**：
1. 在你的 Fork 仓库创建新分支
2. 进行修改并提交
3. 推送到你的远程仓库
4. 访问原仓库页面
5. 点击 "New pull request"
6. 选择你的分支
7. 填写 PR 标题和描述
8. 点击 "Create pull request"

**PR 最佳实践**：
- 一个 PR 只做一件事
- 提供清晰的描述
- 关联相关 Issue
- 保持代码整洁
- 及时响应审查意见

---

## 7. 团队协作流程

### 7.1 集中式工作流

所有人都在 master 分支上工作。

```bash
# 1. 克隆仓库
git clone git@github.com:team/project.git

# 2. 拉取最新代码
git pull origin master

# 3. 进行修改
# ...

# 4. 提交
git commit -am "feat: 添加新功能"

# 5. 推送
git push origin master
```

**适用场景**：
- 小团队
- 简单项目
- 快速迭代

### 7.2 功能分支工作流

每个功能在独立分支开发。

```bash
# 1. 创建功能分支
git checkout -b feature/user-login

# 2. 开发功能
# ...

# 3. 提交
git commit -am "feat: 实现用户登录"

# 4. 推送到远程
git push -u origin feature/user-login

# 5. 创建 Pull Request
# 在 GitHub 上创建 PR

# 6. 代码审查和合并
# 团队成员审查后合并

# 7. 删除分支
git branch -d feature/user-login
git push origin --delete feature/user-login
```

### 7.3 Gitflow 工作流

使用 master、develop、feature、release、hotfix 分支。

```bash
# 1. 克隆仓库
git clone git@github.com:team/project.git

# 2. 切换到 develop 分支
git checkout develop

# 3. 创建功能分支
git checkout -b feature/payment

# 4. 开发功能
# ...

# 5. 合并到 develop
git checkout develop
git merge --no-ff feature/payment

# 6. 创建发布分支
git checkout -b release/v1.0.0 develop

# 7. 合并到 master 并打标签
git checkout master
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release 1.0.0"

# 8. 合并回 develop
git checkout develop
git merge --no-ff release/v1.0.0
```

### 7.4 Forking 工作流

适用于开源项目。

```bash
# 1. Fork 项目到自己账号

# 2. 克隆 Fork 的仓库
git clone git@github.com:your-username/project.git

# 3. 添加上游仓库
git remote add upstream git@github.com:original/project.git

# 4. 创建功能分支
git checkout -b feature/new-feature

# 5. 开发功能
# ...

# 6. 推送到自己的仓库
git push origin feature/new-feature

# 7. 创建 Pull Request
# 在 GitHub 上创建 PR 到原仓库

# 8. 同步上游更新
git fetch upstream
git checkout master
git merge upstream/master
git push origin master
```

---

## 8. 实战案例

### 案例1：参与开源项目

```bash
# 1. Fork 项目
# 在 GitHub 上点击 Fork

# 2. 克隆到本地
git clone git@github.com:your-username/awesome-project.git
cd awesome-project

# 3. 添加上游仓库
git remote add upstream git@github.com:original-owner/awesome-project.git

# 4. 创建功能分支
git checkout -b fix/typo-in-readme

# 5. 修复问题
echo "修复 README 中的拼写错误" >> README.md
git commit -am "docs: 修复 README 拼写错误"

# 6. 推送到自己的仓库
git push origin fix/typo-in-readme

# 7. 创建 Pull Request
# 在 GitHub 上创建 PR

# 8. 等待审查和合并
```

### 案例2：团队协作开发

```bash
# 开发者 A
# 1. 克隆仓库
git clone git@github.com:team/project.git
cd project

# 2. 创建功能分支
git checkout -b feature/user-auth

# 3. 开发功能
echo "用户认证功能" > auth.py
git add auth.py
git commit -m "feat: 添加用户认证"

# 4. 推送并创建 PR
git push -u origin feature/user-auth

# 开发者 B
# 1. 拉取最新代码
git pull origin master

# 2. 审查 PR 并提供反馈
# 在 GitHub 上审查代码

# 3. 合并 PR
# 在 GitHub 上合并

# 开发者 A
# 4. 同步更新
git checkout master
git pull origin master
git branch -d feature/user-auth
```

### 案例3：解决推送冲突

```bash
# 1. 尝试推送
git push origin master
# 输出：! [rejected] master -> master (fetch first)

# 2. 拉取远程更新
git pull origin master
# 或使用 rebase
git pull --rebase origin master

# 3. 解决冲突（如果有）
# 编辑冲突文件
git add .
git rebase --continue

# 4. 再次推送
git push origin master
```

---

## 9. GitHub 高级功能

### 9.1 Issues

```bash
# 在提交中关联 Issue
git commit -m "fix: 修复登录问题 #123"

# 关闭 Issue
git commit -m "fix: 修复登录问题，closes #123"
```

### 9.2 GitHub Actions

创建 `.github/workflows/ci.yml`：
```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          npm install
          npm test
```

### 9.3 GitHub Pages

```bash
# 创建 gh-pages 分支
git checkout --orphan gh-pages

# 添加网站文件
echo "<h1>My Website</h1>" > index.html
git add index.html
git commit -m "init: 初始化 GitHub Pages"

# 推送
git push origin gh-pages

# 访问：https://username.github.io/repo
```

---

## 10. 常见问题

### 问题1：推送被拒绝

```bash
# 原因：远程有新提交
# 解决：先拉取再推送
git pull origin master
git push origin master
```

### 问题2：HTTPS 每次都要输入密码

```bash
# 解决：使用 SSH 或配置凭据缓存
git config --global credential.helper cache

# 或使用 SSH
git remote set-url origin git@github.com:username/repo.git
```

### 问题3：克隆速度慢

```bash
# 方法1：使用浅克隆
git clone --depth 1 url

# 方法2：使用国内镜像
# GitHub：https://github.com.cnpmjs.org/
# 或使用 Gitee 导入仓库
```

### 问题4：大文件推送失败

```bash
# 使用 Git LFS
git lfs install
git lfs track "*.psd"
git add .gitattributes
git add file.psd
git commit -m "add large file"
git push origin master
```

---

## 11. 最佳实践

### 1. 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具
```

### 2. 分支命名

```
feature/功能名
bugfix/bug描述
hotfix/紧急修复
release/版本号
```

### 3. PR 规范

- 标题清晰简洁
- 描述详细完整
- 关联相关 Issue
- 保持代码整洁
- 及时响应审查

### 4. 代码审查

- 仔细阅读代码
- 提供建设性意见
- 关注代码质量
- 检查测试覆盖
- 及时反馈

---

## 12. 练习题

### 练习1：GitHub 基础
1. 注册 GitHub 账号
2. 创建一个公开仓库
3. 克隆到本地
4. 添加文件并推送

### 练习2：Fork 和 PR
1. Fork 一个开源项目
2. 克隆到本地
3. 修改并提交
4. 创建 Pull Request

### 练习3：团队协作
1. 创建团队仓库
2. 邀请成员
3. 使用分支开发
4. 通过 PR 合并代码

---

## 13. 小结

本节学习了：

✅ 远程仓库的概念  
✅ GitHub/GitLab 的使用  
✅ SSH 密钥配置  
✅ 远程仓库操作  
✅ Fork 和 Pull Request  
✅ 团队协作流程  

**下一节**：我们将学习 Git 高级操作，包括 Rebase、Stash 等！

---

**继续加油！** 💪🚀
