# Git 分支管理

## 📚 本节目标

- 理解分支的概念和原理
- 掌握分支的创建和切换
- 掌握分支的合并方法
- 能够解决合并冲突
- 理解分支管理策略
- 掌握标签的使用

---

## 1. 分支概念

### 1.1 什么是分支

分支是 Git 中最强大的功能之一。分支可以让你从主线上分离出来，在不影响主线的情况下继续工作。

**分支的作用**：
- 🌿 并行开发多个功能
- 🔧 修复 bug 不影响主分支
- 🧪 实验新想法
- 👥 团队成员独立工作
- 🚀 准备发布版本

### 1.2 分支原理

Git 的分支本质上是指向提交对象的可变指针。

```
master 分支：
A ← B ← C ← D (master)

创建 dev 分支：
A ← B ← C ← D (master, dev)

在 dev 分支提交：
A ← B ← C ← D (master)
              ↓
              E (dev)
```

**HEAD 指针**：
- HEAD 是一个特殊指针，指向当前所在的分支
- 切换分支就是让 HEAD 指向不同的分支指针

---

## 2. 分支基础操作

### 2.1 查看分支

```bash
# 查看本地分支
git branch

# 查看所有分支（包括远程）
git branch -a

# 查看远程分支
git branch -r

# 查看分支详细信息
git branch -v

# 查看已合并的分支
git branch --merged

# 查看未合并的分支
git branch --no-merged
```

### 2.2 创建分支

```bash
# 创建新分支
git branch dev

# 创建并切换到新分支
git checkout -b dev
# 或使用新命令
git switch -c dev

# 基于指定提交创建分支
git branch dev commit_hash

# 基于远程分支创建本地分支
git checkout -b dev origin/dev
```

### 2.3 切换分支

```bash
# 切换分支
git checkout dev
# 或使用新命令
git switch dev

# 切换到上一个分支
git checkout -
git switch -

# 强制切换（丢弃当前修改）
git checkout -f dev
```

### 2.4 删除分支

```bash
# 删除已合并的分支
git branch -d dev

# 强制删除分支（未合并也删除）
git branch -D dev

# 删除远程分支
git push origin --delete dev
git push origin :dev
```

### 2.5 重命名分支

```bash
# 重命名当前分支
git branch -m new_name

# 重命名指定分支
git branch -m old_name new_name
```

---

## 3. 分支合并

### 3.1 快进合并（Fast-forward）

当前分支的每一个提交都已经存在于目标分支中，Git 只需要移动指针。

```bash
# 切换到主分支
git checkout master

# 合并 dev 分支（快进合并）
git merge dev
```

**示例**：
```
合并前：
A ← B ← C (master)
          ↓
          D ← E (dev)

合并后：
A ← B ← C ← D ← E (master, dev)
```

### 3.2 三方合并（Three-way merge）

当前分支和目标分支都有新的提交，Git 会创建一个新的合并提交。

```bash
# 切换到主分支
git checkout master

# 合并 dev 分支（三方合并）
git merge dev
```

**示例**：
```
合并前：
A ← B ← C ← D (master)
      ↓
      E ← F (dev)

合并后：
A ← B ← C ← D ← G (master)
      ↓         ↗
      E ← F ← ┘ (dev)
```

### 3.3 禁用快进合并

```bash
# 即使可以快进，也创建合并提交
git merge --no-ff dev -m "merge dev branch"
```

**好处**：
- 保留分支历史
- 清晰看出功能开发过程
- 方便回滚整个功能

### 3.4 压缩合并（Squash merge）

将多个提交压缩成一个提交再合并。

```bash
# 压缩合并
git merge --squash dev
git commit -m "feat: 完成某功能"
```

**适用场景**：
- 功能分支有很多琐碎提交
- 想保持主分支历史简洁

---

## 4. 冲突解决

### 4.1 什么是冲突

当两个分支修改了同一个文件的同一部分，Git 无法自动合并，就会产生冲突。

### 4.2 冲突标记

```
<<<<<<< HEAD
当前分支的内容
=======
要合并分支的内容
>>>>>>> dev
```

### 4.3 解决冲突步骤

**步骤1：尝试合并**
```bash
git merge dev
# 输出：Auto-merging file.txt
# 输出：CONFLICT (content): Merge conflict in file.txt
```

**步骤2：查看冲突文件**
```bash
git status
# 输出：Unmerged paths:
#   both modified:   file.txt
```

**步骤3：手动解决冲突**
```bash
# 编辑冲突文件
vim file.txt

# 删除冲突标记，保留需要的内容
# 原始内容：
<<<<<<< HEAD
print("Hello from master")
=======
print("Hello from dev")
>>>>>>> dev

# 解决后：
print("Hello from master and dev")
```

**步骤4：标记为已解决**
```bash
git add file.txt
```

**步骤5：完成合并**
```bash
git commit -m "merge: 解决冲突并合并 dev 分支"
```

### 4.4 取消合并

```bash
# 取消合并，回到合并前状态
git merge --abort
```

### 4.5 使用工具解决冲突

```bash
# 使用配置的合并工具
git mergetool

# 常用合并工具：
# - vimdiff
# - meld
# - kdiff3
# - Beyond Compare
```

---

## 5. 分支管理策略

### 5.1 主分支（master/main）

- 永远保持稳定
- 只用于发布新版本
- 不直接在上面开发

### 5.2 开发分支（develop）

- 日常开发的主分支
- 包含最新的开发代码
- 定期合并到 master

### 5.3 功能分支（feature）

```bash
# 创建功能分支
git checkout -b feature/user-login develop

# 开发完成后合并到 develop
git checkout develop
git merge --no-ff feature/user-login
git branch -d feature/user-login
```

**命名规范**：
- feature/功能名称
- 例如：feature/user-auth, feature/payment

### 5.4 发布分支（release）

```bash
# 创建发布分支
git checkout -b release/v1.0.0 develop

# 修复 bug 和准备发布
# ...

# 合并到 master 和 develop
git checkout master
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release version 1.0.0"

git checkout develop
git merge --no-ff release/v1.0.0

# 删除发布分支
git branch -d release/v1.0.0
```

### 5.5 热修复分支（hotfix）

```bash
# 创建热修复分支
git checkout -b hotfix/critical-bug master

# 修复 bug
# ...

# 合并到 master 和 develop
git checkout master
git merge --no-ff hotfix/critical-bug
git tag -a v1.0.1 -m "Hotfix version 1.0.1"

git checkout develop
git merge --no-ff hotfix/critical-bug

# 删除热修复分支
git branch -d hotfix/critical-bug
```

---

## 6. 标签管理

### 6.1 什么是标签

标签是版本库的快照，用于标记重要的提交点（如发布版本）。

**标签类型**：
- 轻量标签（lightweight）：只是一个提交的引用
- 附注标签（annotated）：包含标签信息的完整对象

### 6.2 创建标签

```bash
# 创建轻量标签
git tag v1.0.0

# 创建附注标签（推荐）
git tag -a v1.0.0 -m "Release version 1.0.0"

# 为指定提交创建标签
git tag -a v0.9.0 commit_hash -m "Version 0.9.0"

# 查看标签
git tag

# 查看标签详细信息
git show v1.0.0
```

### 6.3 推送标签

```bash
# 推送指定标签
git push origin v1.0.0

# 推送所有标签
git push origin --tags
```

### 6.4 删除标签

```bash
# 删除本地标签
git tag -d v1.0.0

# 删除远程标签
git push origin --delete v1.0.0
git push origin :refs/tags/v1.0.0
```

### 6.5 检出标签

```bash
# 查看标签对应的代码
git checkout v1.0.0

# 基于标签创建分支
git checkout -b hotfix/v1.0.0 v1.0.0
```

---

## 7. 实战案例

### 案例1：功能开发流程

```bash
# 1. 从 develop 创建功能分支
git checkout develop
git checkout -b feature/user-profile

# 2. 开发功能
echo "用户资料功能" > profile.py
git add profile.py
git commit -m "feat: 添加用户资料功能"

# 3. 继续开发
echo "完善用户资料" >> profile.py
git commit -am "feat: 完善用户资料功能"

# 4. 合并到 develop
git checkout develop
git merge --no-ff feature/user-profile -m "merge: 合并用户资料功能"

# 5. 删除功能分支
git branch -d feature/user-profile
```

### 案例2：解决合并冲突

```bash
# 1. 在 master 分支修改文件
git checkout master
echo "master 版本" > config.txt
git add config.txt
git commit -m "update config in master"

# 2. 在 dev 分支修改同一文件
git checkout dev
echo "dev 版本" > config.txt
git add config.txt
git commit -m "update config in dev"

# 3. 合并产生冲突
git checkout master
git merge dev
# 输出：CONFLICT (content): Merge conflict in config.txt

# 4. 查看冲突
cat config.txt
# <<<<<<< HEAD
# master 版本
# =======
# dev 版本
# >>>>>>> dev

# 5. 解决冲突
echo "master 和 dev 合并版本" > config.txt
git add config.txt
git commit -m "merge: 解决 config.txt 冲突"
```

### 案例3：发布版本流程

```bash
# 1. 创建发布分支
git checkout -b release/v1.0.0 develop

# 2. 更新版本号
echo "version = '1.0.0'" > version.py
git commit -am "chore: 更新版本号为 1.0.0"

# 3. 合并到 master
git checkout master
git merge --no-ff release/v1.0.0

# 4. 打标签
git tag -a v1.0.0 -m "Release version 1.0.0"

# 5. 合并回 develop
git checkout develop
git merge --no-ff release/v1.0.0

# 6. 删除发布分支
git branch -d release/v1.0.0

# 7. 推送到远程
git push origin master
git push origin develop
git push origin --tags
```

---

## 8. 常见问题

### 问题1：切换分支时有未提交的修改

```bash
# 方法1：提交修改
git commit -am "WIP: 临时保存"

# 方法2：储藏修改（推荐）
git stash
git checkout other-branch
# 工作完成后
git checkout original-branch
git stash pop

# 方法3：强制切换（丢弃修改）
git checkout -f other-branch
```

### 问题2：误删分支

```bash
# 查找被删除分支的最后一次提交
git reflog

# 恢复分支
git branch recovered-branch commit_hash
```

### 问题3：合并错误的分支

```bash
# 撤销合并（未推送到远程）
git reset --hard HEAD~1

# 撤销合并（已推送到远程）
git revert -m 1 merge_commit_hash
```

### 问题4：分支太多难以管理

```bash
# 清理已合并的分支
git branch --merged | grep -v "\*" | grep -v "master" | grep -v "develop" | xargs -n 1 git branch -d

# 清理远程已删除的分支
git remote prune origin
```

---

## 9. 最佳实践

### 1. 分支命名规范

```
feature/功能名称    - 功能开发
bugfix/bug描述      - bug 修复
hotfix/紧急修复     - 生产环境紧急修复
release/版本号      - 发布准备
test/测试内容       - 测试分支
```

### 2. 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具
```

### 3. 合并策略

- 功能分支合并到 develop：使用 `--no-ff`
- develop 合并到 master：使用 `--no-ff`
- 热修复合并：使用 `--no-ff`

### 4. 分支保护

- master 分支只能通过 PR 合并
- 需要代码审查
- 需要通过 CI 测试

---

## 10. 练习题

### 练习1：分支基础操作
1. 创建并切换到 dev 分支
2. 在 dev 分支创建文件并提交
3. 切换回 master 分支
4. 合并 dev 分支
5. 删除 dev 分支

### 练习2：冲突解决
1. 在 master 分支修改文件
2. 创建 dev 分支并修改同一文件
3. 合并产生冲突
4. 手动解决冲突
5. 完成合并

### 练习3：Git Flow 实践
1. 创建 develop 分支
2. 从 develop 创建 feature 分支
3. 开发功能并合并回 develop
4. 创建 release 分支
5. 合并到 master 并打标签

---

## 11. 小结

本节学习了：

✅ 分支的概念和原理  
✅ 分支的创建、切换、删除  
✅ 分支的合并方法  
✅ 冲突的解决  
✅ 分支管理策略  
✅ 标签的使用  

**下一节**：我们将学习 Git 远程协作，包括 GitHub 和 GitLab 的使用！

---

**继续加油！** 💪🚀
