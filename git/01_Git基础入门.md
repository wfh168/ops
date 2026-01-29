# Git 基础入门

## 📚 本节目标

- 理解版本控制的概念和作用
- 掌握 Git 的安装和配置
- 理解 Git 的基本概念
- 掌握 Git 基础命令
- 能够管理文件状态
- 能够查看提交历史

---

## 1. 版本控制简介

### 1.1 什么是版本控制

版本控制是一种记录文件内容变化，以便将来查阅特定版本修订情况的系统。

**为什么需要版本控制？**
- 📝 记录文件的所有修改历史
- 🔄 可以回退到任意历史版本
- 👥 多人协作开发
- 🔍 追踪谁在何时修改了什么
- 🌿 支持并行开发（分支）

### 1.2 版本控制系统类型

**本地版本控制系统**：
- 在本地数据库中记录文件的历次更新
- 例如：RCS

**集中式版本控制系统（CVCS）**：
- 有一个中央服务器保存所有文件的修订版本
- 协同工作的人从中央服务器取出最新版本
- 例如：SVN、CVS

**分布式版本控制系统（DVCS）**：
- 客户端不只提取最新版本，而是完整镜像整个仓库
- 任何一处协同工作用的服务器发生故障，都可以用任何一个镜像恢复
- 例如：Git、Mercurial

### 1.3 Git 的优势

✅ **分布式架构**：每个开发者都有完整的仓库副本  
✅ **速度快**：大部分操作在本地完成  
✅ **数据完整性**：所有数据都经过 SHA-1 哈希校验  
✅ **分支管理强大**：创建和合并分支非常快速  
✅ **开源免费**：完全开源，社区活跃  
✅ **广泛使用**：业界标准，GitHub、GitLab 等平台支持  

---

## 2. Git 安装

### 2.1 Linux 安装

**CentOS/RHEL**：
```bash
# 使用 yum 安装
sudo yum install git -y

# 或使用源码安装最新版本
sudo yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel gcc perl-ExtUtils-MakeMaker -y
cd /usr/local/src
wget https://github.com/git/git/archive/v2.40.0.tar.gz
tar -zxf v2.40.0.tar.gz
cd git-2.40.0
make prefix=/usr/local/git all
sudo make prefix=/usr/local/git install
echo 'export PATH=/usr/local/git/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

**Ubuntu/Debian**：
```bash
# 使用 apt 安装
sudo apt update
sudo apt install git -y
```

### 2.2 Windows 安装

1. 下载 Git for Windows：https://git-scm.com/download/win
2. 运行安装程序
3. 选择默认选项即可
4. 安装完成后，右键菜单会出现 "Git Bash"

### 2.3 Mac 安装

```bash
# 使用 Homebrew 安装
brew install git

# 或使用 Xcode Command Line Tools
xcode-select --install
```

### 2.4 验证安装

```bash
# 查看 Git 版本
git --version
# 输出：git version 2.40.0
```

---

## 3. Git 配置

### 3.1 配置用户信息

```bash
# 配置用户名
git config --global user.name "Your Name"

# 配置邮箱
git config --global user.email "your.email@example.com"

# 查看配置
git config --list
```

### 3.2 配置级别

Git 有三个配置级别：

**系统级别（--system）**：
```bash
# 对所有用户生效
git config --system user.name "System User"
# 配置文件位置：/etc/gitconfig
```

**用户级别（--global）**：
```bash
# 对当前用户生效（推荐）
git config --global user.name "Global User"
# 配置文件位置：~/.gitconfig
```

**仓库级别（--local）**：
```bash
# 只对当前仓库生效
git config --local user.name "Local User"
# 配置文件位置：.git/config
```

**优先级**：local > global > system

### 3.3 常用配置

```bash
# 配置默认编辑器
git config --global core.editor vim

# 配置差异分析工具
git config --global merge.tool vimdiff

# 配置颜色显示
git config --global color.ui true

# 配置别名
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# 配置换行符处理（Windows）
git config --global core.autocrlf true

# 配置换行符处理（Linux/Mac）
git config --global core.autocrlf input

# 忽略文件权限变化
git config --global core.filemode false
```

### 3.4 查看和删除配置

```bash
# 查看所有配置
git config --list

# 查看特定配置
git config user.name

# 删除配置
git config --global --unset user.name

# 编辑配置文件
git config --global --edit
```

---

## 4. Git 基本概念

### 4.1 工作区、暂存区、版本库

```
工作区（Working Directory）
    ↓ git add
暂存区（Staging Area / Index）
    ↓ git commit
版本库（Repository）
```

**工作区**：
- 就是你在电脑里能看到的目录
- 你直接编辑的文件所在的地方

**暂存区**：
- 英文叫 stage 或 index
- 一般存放在 .git 目录下的 index 文件中
- 暂存区也叫索引（index）

**版本库**：
- 工作区有一个隐藏目录 .git
- 这个不算工作区，而是 Git 的版本库
- 版本库里存了很多东西，其中最重要的就是暂存区

### 4.2 文件状态

Git 中文件有四种状态：

**未跟踪（Untracked）**：
- 新创建的文件，Git 还不知道它的存在

**未修改（Unmodified）**：
- 文件已被 Git 跟踪，但没有修改

**已修改（Modified）**：
- 文件已被修改，但还没放到暂存区

**已暂存（Staged）**：
- 文件已被修改并放入暂存区

```
Untracked → (git add) → Staged
Unmodified → (edit) → Modified
Modified → (git add) → Staged
Staged → (git commit) → Unmodified
```

---

## 5. Git 基础命令

### 5.1 创建仓库

**初始化新仓库**：
```bash
# 在当前目录初始化
git init

# 在指定目录初始化
git init myproject
cd myproject
```

**克隆现有仓库**：
```bash
# 克隆远程仓库
git clone https://github.com/user/repo.git

# 克隆到指定目录
git clone https://github.com/user/repo.git myrepo

# 克隆指定分支
git clone -b dev https://github.com/user/repo.git
```

### 5.2 查看状态

```bash
# 查看仓库状态
git status

# 简洁输出
git status -s
# 输出说明：
# ?? - 未跟踪
# A  - 新添加到暂存区
# M  - 已修改
# D  - 已删除
```

### 5.3 添加文件

```bash
# 添加指定文件到暂存区
git add file1.txt file2.txt

# 添加指定目录到暂存区
git add src/

# 添加所有文件到暂存区
git add .
git add -A
git add --all

# 添加所有 .txt 文件
git add *.txt

# 交互式添加
git add -i
```

### 5.4 提交更改

```bash
# 提交暂存区到仓库
git commit -m "提交说明"

# 提交时显示所有 diff 信息
git commit -v

# 跳过暂存区直接提交（已跟踪的文件）
git commit -a -m "提交说明"

# 修改最后一次提交
git commit --amend -m "新的提交说明"
```

**提交说明规范**：
```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式调整
refactor: 重构代码
test: 测试相关
chore: 构建过程或辅助工具的变动
```

### 5.5 查看差异

```bash
# 查看工作区和暂存区的差异
git diff

# 查看暂存区和版本库的差异
git diff --cached
git diff --staged

# 查看工作区和版本库的差异
git diff HEAD

# 查看两个提交之间的差异
git diff commit1 commit2

# 查看指定文件的差异
git diff file.txt
```

### 5.6 删除文件

```bash
# 从工作区和暂存区删除文件
git rm file.txt

# 只从暂存区删除，保留工作区文件
git rm --cached file.txt

# 删除目录
git rm -r directory/

# 强制删除（文件有修改）
git rm -f file.txt
```

### 5.7 移动/重命名文件

```bash
# 重命名文件
git mv old_name.txt new_name.txt

# 等价于：
mv old_name.txt new_name.txt
git rm old_name.txt
git add new_name.txt
```

---

## 6. 查看提交历史

### 6.1 基本用法

```bash
# 查看提交历史
git log

# 显示最近 n 条提交
git log -n 5

# 单行显示
git log --oneline

# 显示分支图
git log --graph

# 显示统计信息
git log --stat

# 显示详细差异
git log -p
```

### 6.2 格式化输出

```bash
# 自定义格式
git log --pretty=format:"%h - %an, %ar : %s"

# 格式说明：
# %H  - 提交的完整哈希值
# %h  - 提交的简短哈希值
# %an - 作者名字
# %ae - 作者邮箱
# %ad - 作者修订日期
# %ar - 作者修订日期，相对格式
# %cn - 提交者名字
# %ce - 提交者邮箱
# %cd - 提交日期
# %cr - 提交日期，相对格式
# %s  - 提交说明

# 漂亮的图形化日志
git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
```

### 6.3 过滤提交

```bash
# 按时间过滤
git log --since="2 weeks ago"
git log --after="2024-01-01"
git log --until="2024-01-31"
git log --before="2024-02-01"

# 按作者过滤
git log --author="John"

# 按提交说明过滤
git log --grep="fix"

# 按文件过滤
git log -- file.txt

# 按内容过滤
git log -S "function_name"

# 组合过滤
git log --since="1 month ago" --author="John" --grep="bug"
```

### 6.4 查看特定提交

```bash
# 查看某次提交的详细信息
git show commit_hash

# 查看最近一次提交
git show HEAD

# 查看上一次提交
git show HEAD^
git show HEAD~1

# 查看上上次提交
git show HEAD^^
git show HEAD~2
```

---

## 7. 忽略文件

### 7.1 .gitignore 文件

创建 `.gitignore` 文件来忽略不需要版本控制的文件：

```bash
# 创建 .gitignore 文件
touch .gitignore
```

### 7.2 .gitignore 规则

```gitignore
# 忽略所有 .log 文件
*.log

# 忽略所有 .tmp 文件
*.tmp

# 忽略 node_modules 目录
node_modules/

# 忽略 build 目录
build/
dist/

# 忽略所有 .class 文件
*.class

# 但不忽略 lib.class
!lib.class

# 只忽略当前目录下的 TODO 文件
/TODO

# 忽略 doc 目录下的所有 .txt 文件
doc/**/*.txt

# 忽略 IDE 配置文件
.idea/
.vscode/
*.swp
*.swo

# 忽略操作系统文件
.DS_Store
Thumbs.db

# 忽略编译文件
*.o
*.so
*.exe
```

### 7.3 全局忽略

```bash
# 创建全局 .gitignore
git config --global core.excludesfile ~/.gitignore_global

# 编辑全局忽略文件
vim ~/.gitignore_global
```

### 7.4 已跟踪文件的忽略

```bash
# 停止跟踪文件但保留在工作区
git rm --cached file.txt

# 停止跟踪目录
git rm -r --cached directory/
```

---

## 8. 实战案例

### 案例1：创建第一个 Git 仓库

```bash
# 1. 创建项目目录
mkdir myproject
cd myproject

# 2. 初始化 Git 仓库
git init

# 3. 配置用户信息
git config user.name "Zhang San"
git config user.email "zhangsan@example.com"

# 4. 创建文件
echo "# My Project" > README.md
echo "print('Hello Git')" > main.py

# 5. 查看状态
git status

# 6. 添加文件到暂存区
git add README.md main.py

# 7. 提交
git commit -m "feat: 初始化项目"

# 8. 查看历史
git log
```

### 案例2：修改文件并提交

```bash
# 1. 修改文件
echo "## 项目说明" >> README.md

# 2. 查看状态
git status

# 3. 查看差异
git diff README.md

# 4. 添加到暂存区
git add README.md

# 5. 提交
git commit -m "docs: 添加项目说明"

# 6. 查看历史
git log --oneline
```

### 案例3：撤销操作

```bash
# 1. 修改文件但还未添加到暂存区
echo "错误内容" >> README.md
git checkout -- README.md  # 撤销工作区修改

# 2. 已添加到暂存区但未提交
echo "错误内容" >> README.md
git add README.md
git reset HEAD README.md  # 取消暂存
git checkout -- README.md  # 撤销工作区修改

# 3. 已提交但想修改提交说明
git commit --amend -m "新的提交说明"
```

---

## 9. 常见问题

### 问题1：中文文件名显示乱码

```bash
# 解决方案
git config --global core.quotepath false
```

### 问题2：换行符问题

```bash
# Windows 系统
git config --global core.autocrlf true

# Linux/Mac 系统
git config --global core.autocrlf input
```

### 问题3：忘记添加 .gitignore

```bash
# 1. 创建 .gitignore 文件
# 2. 清除缓存
git rm -r --cached .
# 3. 重新添加
git add .
# 4. 提交
git commit -m "chore: 添加 .gitignore"
```

### 问题4：提交了敏感信息

```bash
# 从历史中删除文件（谨慎使用）
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/sensitive/file' \
  --prune-empty --tag-name-filter cat -- --all
```

---

## 10. 练习题

### 练习1：基础操作
1. 创建一个新的 Git 仓库
2. 创建 3 个文件并提交
3. 修改其中一个文件并提交
4. 查看提交历史

### 练习2：文件管理
1. 创建 .gitignore 文件
2. 添加忽略规则
3. 创建一些应该被忽略的文件
4. 验证这些文件是否被忽略

### 练习3：撤销操作
1. 修改一个文件但不提交
2. 撤销工作区的修改
3. 再次修改并添加到暂存区
4. 取消暂存

---

## 11. 小结

本节学习了：

✅ 版本控制的概念和 Git 的优势  
✅ Git 的安装和配置  
✅ Git 的基本概念（工作区、暂存区、版本库）  
✅ Git 基础命令（init、add、commit、status、diff）  
✅ 查看提交历史  
✅ 忽略文件的方法  

**下一节**：我们将学习 Git 分支管理，这是 Git 最强大的功能之一！

---

**继续加油！** 💪🚀
