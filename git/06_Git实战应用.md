# Git 实战应用

## 📚 本节目标

- 掌握企业级项目管理
- 解决常见问题
- 掌握性能优化
- 了解安全最佳实践
- 掌握故障排查
- 理解大型项目管理

---

## 1. 企业级项目管理

### 1.1 项目初始化

```bash
# 1. 创建项目目录
mkdir myproject
cd myproject

# 2. 初始化 Git
git init

# 3. 创建 .gitignore
cat > .gitignore << 'EOF'
# 依赖
node_modules/
vendor/

# 构建产物
dist/
build/
*.pyc
*.class

# IDE
.idea/
.vscode/
*.swp

# 系统文件
.DS_Store
Thumbs.db

# 环境配置
.env
.env.local

# 日志
*.log
logs/
EOF

# 4. 创建 README
cat > README.md << 'EOF'
# 项目名称

## 简介
项目描述

## 安装
```bash
npm install
```

## 使用
```bash
npm start
```

## 贡献
欢迎提交 PR
EOF

# 5. 初始提交
git add .
git commit -m "init: 初始化项目"

# 6. 创建远程仓库并推送
git remote add origin git@github.com:user/project.git
git push -u origin master

# 7. 创建 develop 分支
git checkout -b develop
git push -u origin develop
```

### 1.2 分支保护

**GitHub 分支保护设置**：
1. Settings → Branches
2. Add rule
3. 配置规则：
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date
   - Include administrators

### 1.3 权限管理

```bash
# 团队成员权限
# - Admin：完全控制
# - Write：推送权限
# - Read：只读权限

# 使用 CODEOWNERS 文件
cat > .github/CODEOWNERS << 'EOF'
# 默认所有者
* @team-lead

# 前端代码
/frontend/ @frontend-team

# 后端代码
/backend/ @backend-team

# 文档
/docs/ @doc-team
EOF
```

---

## 2. 常见问题解决

### 2.1 提交了敏感信息

```bash
# 方法1：修改最后一次提交
git reset --soft HEAD~1
# 删除敏感信息
git add .
git commit -m "fix: 移除敏感信息"

# 方法2：使用 filter-branch（已推送）
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/sensitive/file' \
  --prune-empty --tag-name-filter cat -- --all

# 方法3：使用 BFG Repo-Cleaner（推荐）
# 下载 BFG
# 删除敏感文件
java -jar bfg.jar --delete-files sensitive.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 强制推送
git push origin --force --all
```

### 2.2 误删分支恢复

```bash
# 1. 查找被删除分支的提交
git reflog

# 2. 恢复分支
git branch recovered-branch commit_hash

# 3. 或直接切换到该提交
git checkout commit_hash
git checkout -b recovered-branch
```
# 一字不差拉取远程 main 分支

要将本地代码**完全同步**为远程 main 分支的状态（丢弃所有本地修改和提交），请按以下步骤操作：

## 📌 完整命令

```bash
# 1. 切换到 main 分支
git checkout main

# 2. 获取远程最新代码
git fetch origin

# 3. 硬重置本地 main 到远程 main（丢弃所有本地修改）
git reset --hard origin/main

# 4. 清理未跟踪的文件和目录（可选，如果需要彻底干净）
git clean -fd
```

## 🔍 命令说明

| 命令 | 作用 |
|------|------|
| `git fetch origin` | 获取远程仓库最新信息，不合并 |
| `git reset --hard origin/main` | 强制本地与远程完全一致，**丢弃所有本地修改** |
| `git clean -fd` | 删除未跟踪的文件和目录（-f强制，-d包括目录） |

## ⚠️ 重要警告

> **此操作会永久丢失以下内容：**
> - 所有未提交的本地修改
> - 所有本地新增的提交
> - 所有未跟踪的文件（如果执行了 `git clean -fd`）

## 💡 建议先备份

在执行前，建议先创建备份分支：

```bash
# 创建备份分支（以防万一）
git branch backup-before-reset

# 或者查看有哪些本地修改
git status
git diff
```

## 🔙 如果误操作了可以恢复

如果后悔了，可以用 reflog 找回之前的状态：

```bash
# 查看操作历史
git reflog

# 重置到之前的某个状态
git reset --hard HEAD@{n}
```

---

执行完上述命令后，你的本地 main 分支将与远程 **完全一致**，一字不差！
### 2.3 合并冲突解决

```bash
# 1. 尝试合并
git merge feature-branch
# CONFLICT (content): Merge conflict in file.txt

# 2. 查看冲突文件
git status

# 3. 使用工具解决
git mergetool

# 4. 或手动解决
vim file.txt
# 编辑冲突部分

# 5. 标记为已解决
git add file.txt

# 6. 完成合并
git commit

# 7. 如果想取消合并
git merge --abort
```

### 2.4 大文件处理

```bash
# 使用 Git LFS
# 1. 安装 Git LFS
git lfs install

# 2. 跟踪大文件
git lfs track "*.psd"
git lfs track "*.mp4"

# 3. 提交 .gitattributes
git add .gitattributes
git commit -m "chore: 配置 Git LFS"

# 4. 添加大文件
git add large-file.psd
git commit -m "feat: 添加设计文件"
git push origin master

# 查看 LFS 文件
git lfs ls-files

# 迁移已有大文件到 LFS
git lfs migrate import --include="*.psd"
```

### 2.5 历史重写

```bash
# 修改历史提交的作者信息
git filter-branch --env-filter '
if [ "$GIT_COMMITTER_EMAIL" = "old@email.com" ]; then
    export GIT_COMMITTER_NAME="New Name"
    export GIT_COMMITTER_EMAIL="new@email.com"
fi
if [ "$GIT_AUTHOR_EMAIL" = "old@email.com" ]; then
    export GIT_AUTHOR_NAME="New Name"
    export GIT_AUTHOR_EMAIL="new@email.com"
fi
' --tag-name-filter cat -- --branches --tags

# 强制推送
git push origin --force --all
```

---

## 3. 性能优化

### 3.1 仓库瘦身

```bash
# 1. 查看仓库大小
du -sh .git

# 2. 查找大文件
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  sed -n 's/^blob //p' | \
  sort --numeric-sort --key=2 | \
  tail -n 10

# 3. 清理不需要的文件
git gc --aggressive --prune=now

# 4. 删除历史中的大文件
git filter-branch --tree-filter 'rm -f path/to/large/file' HEAD

# 5. 清理 reflog
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### 3.2 浅克隆

```bash
# 只克隆最近的提交
git clone --depth 1 https://github.com/user/repo.git

# 获取更多历史
git fetch --depth=100

# 转换为完整克隆
git fetch --unshallow
```

### 3.3 稀疏检出

```bash
# 只检出部分目录
git clone --no-checkout https://github.com/user/repo.git
cd repo
git sparse-checkout init --cone
git sparse-checkout set src/frontend
git checkout master
```

### 3.4 优化配置

```bash
# 启用文件系统监控
git config core.fsmonitor true

# 启用并行处理
git config core.preloadindex true

# 增加压缩级别
git config core.compression 9

# 启用增量 repack
git config repack.usedeltabaseoffset true
```

---

## 4. 安全最佳实践

### 4.1 签名提交

```bash
# 1. 生成 GPG 密钥
gpg --full-generate-key

# 2. 查看密钥
gpg --list-secret-keys --keyid-format LONG

# 3. 配置 Git
git config --global user.signingkey YOUR_KEY_ID

# 4. 签名提交
git commit -S -m "feat: 添加新功能"

# 5. 自动签名所有提交
git config --global commit.gpgsign true

# 6. 验证签名
git log --show-signature
```

### 4.2 保护敏感信息

```bash
# 1. 使用环境变量
# .env
DATABASE_URL=postgresql://user:pass@localhost/db

# 2. 添加到 .gitignore
echo ".env" >> .gitignore

# 3. 提供示例文件
cp .env .env.example
# 编辑 .env.example，移除敏感信息
git add .env.example

# 4. 使用 git-secrets
git secrets --install
git secrets --register-aws
```

### 4.3 审计日志

```bash
# 查看谁修改了文件
git log --follow --all -- path/to/file

# 查看文件每一行的修改者
git blame file.txt

# 查看特定作者的提交
git log --author="John"

# 查看特定时间的提交
git log --since="2024-01-01" --until="2024-01-31"
```

---

## 5. 故障排查

### 5.1 诊断工具

```bash
# 查看 Git 版本
git --version

# 查看配置
git config --list --show-origin

# 查看远程仓库信息
git remote -v
git remote show origin

# 查看引用日志
git reflog

# 验证仓库完整性
git fsck --full

# 查看对象信息
git cat-file -p commit_hash
```

### 5.2 常见错误

**错误1：fatal: refusing to merge unrelated histories**
```bash
# 解决：允许合并不相关的历史
git pull origin master --allow-unrelated-histories
```

**错误2：error: failed to push some refs**
```bash
# 解决：先拉取再推送
git pull --rebase origin master
git push origin master
```

**错误3：fatal: The remote end hung up unexpectedly**
```bash
# 解决：增加缓冲区大小
git config --global http.postBuffer 524288000
```

**错误4：Permission denied (publickey)**
```bash
# 解决：检查 SSH 密钥
ssh -T git@github.com
# 重新添加 SSH 密钥
ssh-add ~/.ssh/id_rsa
```

### 5.3 性能问题

```bash
# 问题：git status 很慢
# 解决1：清理未跟踪的文件
git clean -fd

# 解决2：优化索引
git update-index --refresh

# 解决3：启用文件系统监控
git config core.fsmonitor true

# 问题：git push 很慢
# 解决：使用 SSH 代替 HTTPS
git remote set-url origin git@github.com:user/repo.git
```

---

## 6. 大型项目管理

### 6.1 Monorepo 管理

```bash
# 项目结构
monorepo/
├── packages/
│   ├── frontend/
│   ├── backend/
│   └── shared/
├── .gitignore
└── README.md

# 使用 Git 子树
git subtree add --prefix=packages/frontend \
  https://github.com/user/frontend.git master --squash

# 更新子树
git subtree pull --prefix=packages/frontend \
  https://github.com/user/frontend.git master --squash

# 推送子树
git subtree push --prefix=packages/frontend \
  https://github.com/user/frontend.git master
```

### 6.2 多仓库管理

```bash
# 使用 Git 子模块
git submodule add https://github.com/user/module1.git modules/module1
git submodule add https://github.com/user/module2.git modules/module2

# 克隆包含子模块的仓库
git clone --recursive https://github.com/user/main-repo.git

# 更新所有子模块
git submodule update --remote --merge

# 在所有子模块中执行命令
git submodule foreach 'git pull origin master'
```

### 6.3 发布管理

```bash
# 1. 创建发布分支
git checkout -b release/v2.0.0 develop

# 2. 更新版本号
npm version 2.0.0
git add package.json package-lock.json
git commit -m "chore: 更新版本号为 2.0.0"

# 3. 生成 CHANGELOG
git log --pretty=format:"- %s" v1.0.0..HEAD > CHANGELOG.md
git add CHANGELOG.md
git commit -m "docs: 更新 CHANGELOG"

# 4. 合并到 master
git checkout master
git merge --no-ff release/v2.0.0

# 5. 打标签
git tag -a v2.0.0 -m "Release version 2.0.0"

# 6. 合并回 develop
git checkout develop
git merge --no-ff release/v2.0.0

# 7. 推送
git push origin master develop --tags

# 8. 发布到 npm/PyPI
npm publish
# 或
python setup.py sdist upload
```

---

## 7. 自动化脚本

### 7.1 自动化部署脚本

```bash
#!/bin/bash
# deploy.sh

set -e

echo "开始部署..."

# 1. 拉取最新代码
git pull origin master

# 2. 安装依赖
npm install

# 3. 运行测试
npm test

# 4. 构建
npm run build

# 5. 备份当前版本
cp -r dist dist.backup

# 6. 部署
rsync -avz dist/ user@server:/var/www/html/

# 7. 重启服务
ssh user@server 'sudo systemctl restart nginx'

echo "部署完成！"
```

### 7.2 自动化清理脚本

```bash
#!/bin/bash
# cleanup.sh

# 删除已合并的本地分支
git branch --merged | grep -v "\*" | grep -v "master" | grep -v "develop" | xargs -n 1 git branch -d

# 清理远程已删除的分支
git fetch -p

# 清理 reflog
git reflog expire --expire=30.days --all

# 垃圾回收
git gc --auto

echo "清理完成！"
```

### 7.3 自动化备份脚本

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/git"
DATE=$(date +%Y%m%d)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份仓库
git bundle create $BACKUP_DIR/repo-$DATE.bundle --all

# 压缩
gzip $BACKUP_DIR/repo-$DATE.bundle

# 删除 30 天前的备份
find $BACKUP_DIR -name "*.bundle.gz" -mtime +30 -delete

echo "备份完成：$BACKUP_DIR/repo-$DATE.bundle.gz"
```

---

## 8. 实战案例

### 案例1：开源项目维护

```bash
# 1. Fork 项目并克隆
git clone git@github.com:your-username/project.git
cd project
git remote add upstream git@github.com:original/project.git

# 2. 创建功能分支
git checkout -b feature/new-feature

# 3. 开发功能
# ...

# 4. 同步上游更新
git fetch upstream
git rebase upstream/master

# 5. 推送并创建 PR
git push origin feature/new-feature

# 6. 响应审查意见
# 修改代码
git commit --amend
git push -f origin feature/new-feature

# 7. PR 合并后清理
git checkout master
git pull upstream master
git push origin master
git branch -d feature/new-feature
```

### 案例2：紧急生产问题修复

```bash
# 1. 从生产标签创建热修复分支
git checkout -b hotfix/critical-bug v1.0.0

# 2. 修复问题
# ...
git commit -am "fix: 修复严重 bug"

# 3. 测试修复
npm test

# 4. 合并到 master
git checkout master
git merge --no-ff hotfix/critical-bug

# 5. 打新标签
git tag -a v1.0.1 -m "Hotfix 1.0.1"

# 6. 合并到 develop
git checkout develop
git merge --no-ff hotfix/critical-bug

# 7. 推送并部署
git push origin master develop --tags
./deploy.sh

# 8. 清理
git branch -d hotfix/critical-bug
```

---

## 9. 最佳实践总结

### 1. 提交规范
- 使用语义化提交信息
- 一次提交只做一件事
- 提交前运行测试
- 避免提交临时文件

### 2. 分支管理
- 保持分支简洁
- 及时合并和删除
- 使用描述性分支名
- 定期同步主分支

### 3. 代码审查
- 所有代码都要审查
- 提供建设性反馈
- 及时响应评论
- 保持友好态度

### 4. 安全实践
- 不提交敏感信息
- 使用 SSH 密钥
- 签名重要提交
- 定期审计日志

### 5. 性能优化
- 定期清理仓库
- 使用浅克隆
- 优化大文件处理
- 启用性能配置

---

## 10. 练习题

### 练习1：项目初始化
1. 创建新项目
2. 配置 .gitignore
3. 设置分支保护
4. 配置 CI/CD

### 练习2：问题排查
1. 模拟提交敏感信息
2. 使用工具清理历史
3. 恢复误删的分支
4. 解决合并冲突

### 练习3：性能优化
1. 分析仓库大小
2. 清理大文件
3. 优化克隆速度
4. 配置性能参数

---

## 11. 小结

本节学习了：

✅ 企业级项目管理  
✅ 常见问题解决  
✅ 性能优化  
✅ 安全最佳实践  
✅ 故障排查  
✅ 大型项目管理  

**恭喜你完成了 Git 版本控制的全部学习！** 🎉

现在你已经掌握了：
- Git 基础操作
- 分支管理
- 远程协作
- 高级操作
- 工作流程
- 实战应用

**继续实践，不断提升！** 💪🚀
