# Git 高级操作

## 📚 本节目标

- 掌握 Rebase 变基操作
- 掌握 Stash 储藏功能
- 掌握 Reset 和 Revert
- 理解 Cherry-pick 操作
- 掌握子模块管理
- 了解 Git Hooks

---

## 1. Rebase 变基

### 1.1 什么是 Rebase

Rebase 是将一系列提交移动到新的基础提交上。

**Merge vs Rebase**：
```
Merge：
A ← B ← C ← D (master)
      ↓       ↗
      E ← F ← G

Rebase：
A ← B ← C ← D ← E' ← F' (master)
```

### 1.2 基本用法

```bash
# 将当前分支变基到 master
git checkout feature
git rebase master

# 或一步完成
git rebase master feature

# 交互式变基
git rebase -i HEAD~3
```

### 1.3 交互式 Rebase

```bash
# 编辑最近 3 次提交
git rebase -i HEAD~3

# 编辑器中显示：
# pick abc1234 提交1
# pick def5678 提交2
# pick ghi9012 提交3

# 可用命令：
# p, pick = 使用提交
# r, reword = 使用提交，但修改提交说明
# e, edit = 使用提交，但停下来修改
# s, squash = 使用提交，但合并到前一个提交
# f, fixup = 类似 squash，但丢弃提交说明
# d, drop = 删除提交
```

**示例：合并提交**
```bash
# 将最近 3 次提交合并为 1 次
git rebase -i HEAD~3

# 修改为：
pick abc1234 提交1
squash def5678 提交2
squash ghi9012 提交3

# 保存后编辑合并后的提交说明
```

### 1.4 解决 Rebase 冲突

```bash
# 1. 开始 rebase
git rebase master

# 2. 如果有冲突，解决冲突
# 编辑冲突文件

# 3. 标记为已解决
git add .

# 4. 继续 rebase
git rebase --continue

# 或跳过当前提交
git rebase --skip

# 或取消 rebase
git rebase --abort
```

### 1.5 Rebase 黄金法则

⚠️ **永远不要 rebase 已经推送到公共仓库的提交！**

原因：
- 会改变提交历史
- 导致其他人的仓库混乱
- 可能丢失代码

---

## 2. Stash 储藏

### 2.1 什么是 Stash

Stash 可以临时保存工作区和暂存区的修改，让你切换到其他分支工作。

### 2.2 基本用法

```bash
# 储藏当前修改
git stash

# 储藏时添加说明
git stash save "WIP: 用户登录功能"

# 查看储藏列表
git stash list

# 应用最近的储藏
git stash apply

# 应用并删除储藏
git stash pop

# 应用指定储藏
git stash apply stash@{2}

# 删除储藏
git stash drop stash@{0}

# 清空所有储藏
git stash clear
```

### 2.3 高级用法

```bash
# 储藏包括未跟踪的文件
git stash -u
git stash --include-untracked

# 储藏所有文件（包括忽略的）
git stash -a
git stash --all

# 查看储藏的差异
git stash show
git stash show -p

# 从储藏创建分支
git stash branch new-branch stash@{0}
```

---

## 3. Reset 重置

### 3.1 Reset 模式

**--soft**：只移动 HEAD，保留暂存区和工作区
```bash
git reset --soft HEAD~1
```

**--mixed**（默认）：移动 HEAD，重置暂存区，保留工作区
```bash
git reset HEAD~1
git reset --mixed HEAD~1
```

**--hard**：移动 HEAD，重置暂存区和工作区
```bash
git reset --hard HEAD~1
```

### 3.2 常用场景

**撤销最后一次提交**：
```bash
# 保留修改
git reset --soft HEAD~1

# 丢弃修改
git reset --hard HEAD~1
```

**取消暂存**：
```bash
git reset HEAD file.txt
```

**回退到指定提交**：
```bash
git reset --hard commit_hash
```

**恢复误删的提交**：
```bash
# 查找提交
git reflog

# 恢复
git reset --hard commit_hash
```

---

## 4. Revert 还原

### 4.1 什么是 Revert

Revert 创建一个新提交来撤销之前的提交，不改变历史。

### 4.2 基本用法

```bash
# 还原指定提交
git revert commit_hash

# 还原最近的提交
git revert HEAD

# 还原多个提交
git revert HEAD~3..HEAD

# 还原但不自动提交
git revert -n commit_hash
```

### 4.3 Revert vs Reset

**Reset**：
- 改变历史
- 不能用于已推送的提交
- 适合本地操作

**Revert**：
- 不改变历史
- 可以用于已推送的提交
- 适合公共分支

---

## 5. Cherry-pick 拣选

### 5.1 什么是 Cherry-pick

Cherry-pick 可以将指定的提交应用到当前分支。

### 5.2 基本用法

```bash
# 拣选单个提交
git cherry-pick commit_hash

# 拣选多个提交
git cherry-pick commit1 commit2

# 拣选提交范围
git cherry-pick commit1..commit2

# 拣选但不自动提交
git cherry-pick -n commit_hash
```

### 5.3 解决冲突

```bash
# 1. 拣选提交
git cherry-pick commit_hash

# 2. 如果有冲突，解决冲突
# 编辑冲突文件

# 3. 标记为已解决
git add .

# 4. 继续 cherry-pick
git cherry-pick --continue

# 或取消
git cherry-pick --abort
```

---

## 6. 子模块管理

### 6.1 什么是子模块

子模块允许你将一个 Git 仓库作为另一个 Git 仓库的子目录。

### 6.2 添加子模块

```bash
# 添加子模块
git submodule add https://github.com/user/repo.git path/to/submodule

# 提交
git commit -m "chore: 添加子模块"
```

### 6.3 克隆包含子模块的仓库

```bash
# 方法1：克隆后初始化子模块
git clone https://github.com/user/main-repo.git
cd main-repo
git submodule init
git submodule update

# 方法2：克隆时递归初始化
git clone --recursive https://github.com/user/main-repo.git
```

### 6.4 更新子模块

```bash
# 更新所有子模块
git submodule update --remote

# 更新指定子模块
git submodule update --remote path/to/submodule
```

### 6.5 删除子模块

```bash
# 1. 删除子模块配置
git submodule deinit path/to/submodule

# 2. 删除子模块目录
git rm path/to/submodule

# 3. 删除 .git/modules 中的子模块
rm -rf .git/modules/path/to/submodule

# 4. 提交
git commit -m "chore: 删除子模块"
```

---

## 7. Git Hooks

### 7.1 什么是 Hooks

Hooks 是在 Git 执行特定操作时自动运行的脚本。

### 7.2 常用 Hooks

**客户端 Hooks**：
- `pre-commit`：提交前执行
- `prepare-commit-msg`：准备提交信息时执行
- `commit-msg`：提交信息编辑后执行
- `post-commit`：提交后执行
- `pre-push`：推送前执行

**服务器端 Hooks**：
- `pre-receive`：接收推送前执行
- `update`：更新引用前执行
- `post-receive`：接收推送后执行

### 7.3 创建 Hook

```bash
# 进入 hooks 目录
cd .git/hooks

# 创建 pre-commit hook
cat > pre-commit << 'EOF'
#!/bin/sh
# 运行测试
npm test
if [ $? -ne 0 ]; then
    echo "测试失败，提交被拒绝"
    exit 1
fi
EOF

# 添加执行权限
chmod +x pre-commit
```

### 7.4 Hook 示例

**pre-commit：代码检查**
```bash
#!/bin/sh
# 运行 ESLint
npm run lint
if [ $? -ne 0 ]; then
    echo "代码检查失败"
    exit 1
fi
```

**commit-msg：提交信息检查**
```bash
#!/bin/sh
# 检查提交信息格式
commit_msg=$(cat $1)
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore):"; then
    echo "提交信息格式错误"
    echo "格式：type: description"
    exit 1
fi
```

---

## 8. 其他高级操作

### 8.1 Reflog 引用日志

```bash
# 查看引用日志
git reflog

# 查看指定分支的引用日志
git reflog show master

# 恢复误删的提交
git reset --hard HEAD@{2}
```

### 8.2 Bisect 二分查找

```bash
# 开始二分查找
git bisect start

# 标记当前版本为坏版本
git bisect bad

# 标记某个版本为好版本
git bisect good commit_hash

# Git 会自动切换到中间版本
# 测试后标记
git bisect good  # 或 git bisect bad

# 找到问题提交后
git bisect reset
```

### 8.3 Blame 追溯

```bash
# 查看文件每一行的最后修改
git blame file.txt

# 查看指定行范围
git blame -L 10,20 file.txt

# 查看指定提交之前的版本
git blame commit_hash file.txt
```

### 8.4 Clean 清理

```bash
# 查看会删除的文件
git clean -n

# 删除未跟踪的文件
git clean -f

# 删除未跟踪的文件和目录
git clean -fd

# 删除忽略的文件
git clean -fX

# 删除所有未跟踪的文件
git clean -fx
```

---

## 9. 实战案例

### 案例1：整理提交历史

```bash
# 1. 查看最近 5 次提交
git log --oneline -5

# 2. 交互式 rebase
git rebase -i HEAD~5

# 3. 合并琐碎提交
# 将多个 "fix typo" 合并为一个

# 4. 修改提交说明
# 将 "update" 改为 "feat: 添加用户功能"

# 5. 完成 rebase
```

### 案例2：紧急修复流程

```bash
# 1. 正在开发功能，需要紧急修复 bug
git stash save "WIP: 用户功能开发中"

# 2. 切换到 master
git checkout master

# 3. 创建 hotfix 分支
git checkout -b hotfix/critical-bug

# 4. 修复 bug
echo "修复" > fix.txt
git add fix.txt
git commit -m "fix: 修复严重 bug"

# 5. 合并到 master
git checkout master
git merge --no-ff hotfix/critical-bug

# 6. 切换回开发分支
git checkout feature/user-function

# 7. 恢复工作
git stash pop
```

### 案例3：拣选提交

```bash
# 1. 在 dev 分支有一个重要修复
git checkout dev
git log --oneline
# abc1234 fix: 修复登录问题

# 2. 将这个修复应用到 master
git checkout master
git cherry-pick abc1234

# 3. 推送
git push origin master
```

---

## 10. 常见问题

### 问题1：Rebase 后推送失败

```bash
# 原因：改变了历史
# 解决：强制推送（确保没有其他人在使用）
git push -f origin feature-branch
```

### 问题2：误用 reset --hard

```bash
# 使用 reflog 恢复
git reflog
git reset --hard HEAD@{1}
```

### 问题3：子模块更新问题

```bash
# 更新所有子模块到最新
git submodule update --remote --merge
```

---

## 11. 最佳实践

### 1. Rebase 使用原则
- 只 rebase 本地未推送的提交
- 保持提交历史清晰
- 合并琐碎提交

### 2. Stash 使用建议
- 添加清晰的说明
- 及时清理不需要的 stash
- 定期查看 stash 列表

### 3. Reset 使用注意
- 谨慎使用 --hard
- 不要 reset 已推送的提交
- 使用前确认当前状态

### 4. Hooks 使用建议
- 保持脚本简单快速
- 提供清晰的错误信息
- 考虑团队共享 hooks

---

## 12. 练习题

### 练习1：Rebase 实践
1. 创建功能分支并提交 3 次
2. 使用交互式 rebase 合并提交
3. 修改提交说明

### 练习2：Stash 使用
1. 修改文件但不提交
2. 使用 stash 保存
3. 切换分支工作
4. 恢复 stash

### 练习3：子模块管理
1. 创建主仓库
2. 添加子模块
3. 更新子模块
4. 克隆包含子模块的仓库

---

## 13. 小结

本节学习了：

✅ Rebase 变基操作  
✅ Stash 储藏功能  
✅ Reset 和 Revert  
✅ Cherry-pick 拣选  
✅ 子模块管理  
✅ Git Hooks  

**下一节**：我们将学习 Git 工作流和团队协作规范！

---

**继续加油！** 💪🚀
