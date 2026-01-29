# Shell 基础语法

## 一、Shell 简介

### 1.1 什么是 Shell

Shell 是用户与 Linux 内核之间的接口程序，负责解释用户输入的命令并传递给内核执行。

**Shell 的作用**：
- 命令解释器
- 编程语言
- 用户界面

**常见的 Shell**：
```bash
# 查看系统支持的 Shell
cat /etc/shells

输出：
/bin/sh
/bin/bash
/bin/zsh
/bin/dash
```

**Shell 类型对比**：

| Shell | 特点 | 适用场景 |
|-------|------|----------|
| **Bash** | 功能强大，最常用 | 脚本编写、日常使用 ⭐ |
| **Zsh** | 功能丰富，可定制 | 交互式使用 |
| **Dash** | 轻量快速 | 系统脚本 |
| **Sh** | 标准 Shell | 兼容性脚本 |

### 1.2 第一个 Shell 脚本

```bash
#!/bin/bash
# 这是一个简单的 Shell 脚本
# 作者：Your Name
# 日期：2024-01-29

echo "Hello, World!"
echo "当前用户：$USER"
echo "当前目录：$PWD"
echo "当前时间：$(date)"
```

**脚本说明**：
- `#!/bin/bash`：Shebang，指定脚本解释器
- `#`：注释符号
- `echo`：输出命令
- `$USER`、`$PWD`：系统变量

**执行脚本**：
```bash
# 方法1：添加执行权限
chmod +x hello.sh
./hello.sh

# 方法2：使用 bash 执行
bash hello.sh

# 方法3：使用 source 执行（在当前 Shell 中执行）
source hello.sh
# 或
. hello.sh
```

---

## 二、变量

### 2.1 变量定义

```bash
#!/bin/bash

# 定义变量（注意：等号两边不能有空格）
name="张三"
age=25
salary=8000.50

# 使用变量
echo "姓名：$name"
echo "年龄：$age"
echo "工资：$salary"

# 使用 ${} 明确变量边界
echo "姓名是：${name}，年龄是：${age}岁"
```

**变量命名规则**：
- 只能包含字母、数字、下划线
- 不能以数字开头
- 不能使用 Shell 关键字
- 建议使用大写字母（常量）或小写字母（变量）

### 2.2 变量类型

#### 1. 局部变量

```bash
#!/bin/bash

function test_func() {
    local local_var="局部变量"
    echo "函数内：$local_var"
}

test_func
echo "函数外：$local_var"  # 无法访问
```

#### 2. 环境变量

```bash
#!/bin/bash

# 定义环境变量
export MY_VAR="环境变量"

# 查看环境变量
echo $PATH
echo $HOME
echo $USER
echo $SHELL

# 常用环境变量
echo "当前用户：$USER"
echo "主目录：$HOME"
echo "当前目录：$PWD"
echo "上一个目录：$OLDPWD"
echo "Shell 类型：$SHELL"
echo "主机名：$HOSTNAME"
```

#### 3. 位置参数

```bash
#!/bin/bash
# 文件名：params.sh

echo "脚本名称：$0"
echo "第一个参数：$1"
echo "第二个参数：$2"
echo "第三个参数：$3"
echo "所有参数：$@"
echo "所有参数：$*"
echo "参数个数：$#"
echo "上一个命令的退出状态：$?"
echo "当前进程 PID：$$"
echo "后台运行的最后一个进程 PID：$!"
```

执行测试：
```bash
bash params.sh arg1 arg2 arg3

输出：
脚本名称：params.sh
第一个参数：arg1
第二个参数：arg2
第三个参数：arg3
所有参数：arg1 arg2 arg3
所有参数：arg1 arg2 arg3
参数个数：3
```

**$@ 和 $* 的区别**：
```bash
#!/bin/bash

echo "使用 \$@："
for arg in "$@"; do
    echo "  $arg"
done

echo "使用 \$*："
for arg in "$*"; do
    echo "  $arg"
done
```

```bash
bash test.sh "arg 1" "arg 2" "arg 3"

输出：
使用 $@：
  arg 1
  arg 2
  arg 3
使用 $*：
  arg 1 arg 2 arg 3
```

### 2.3 变量操作

#### 1. 变量赋值

```bash
#!/bin/bash

# 直接赋值
var1="hello"

# 命令替换
var2=$(date)
var3=`date`  # 旧式写法

# 算术运算
var4=$((1 + 2))
var5=$[3 * 4]

# 读取用户输入
read -p "请输入你的名字：" name
echo "你好，$name"

# 读取文件内容
content=$(cat file.txt)
```

#### 2. 变量默认值

```bash
#!/bin/bash

# ${var:-default}：如果 var 未设置或为空，返回 default
echo ${undefined_var:-"默认值"}

# ${var:=default}：如果 var 未设置或为空，设置为 default 并返回
echo ${new_var:="新值"}
echo $new_var

# ${var:?error}：如果 var 未设置或为空，输出错误信息并退出
echo ${must_var:?"必须设置此变量"}

# ${var:+value}：如果 var 已设置且非空，返回 value
set_var="已设置"
echo ${set_var:+"变量已设置"}
```

#### 3. 变量删除

```bash
#!/bin/bash

# 删除变量
var="hello"
unset var
echo $var  # 输出为空

# 只读变量（不能删除和修改）
readonly const_var="常量"
const_var="新值"  # 报错
unset const_var   # 报错
```

---

## 三、字符串处理

### 3.1 字符串定义

```bash
#!/bin/bash

# 单引号：原样输出，不解析变量
str1='Hello $USER'
echo $str1  # 输出：Hello $USER

# 双引号：解析变量和转义字符
str2="Hello $USER"
echo $str2  # 输出：Hello root

# 无引号：可以解析变量，但不能包含空格
str3=Hello
echo $str3
```

### 3.2 字符串长度

```bash
#!/bin/bash

str="Hello World"

# 获取字符串长度
echo ${#str}  # 输出：11

# 中文字符串长度
chinese="你好世界"
echo ${#chinese}  # 输出：4（字符数）
```

### 3.3 字符串截取

```bash
#!/bin/bash

str="Hello World"

# ${string:position}：从 position 开始截取到末尾
echo ${str:6}  # 输出：World

# ${string:position:length}：从 position 开始截取 length 个字符
echo ${str:0:5}  # 输出：Hello

# ${string: -length}：从右边截取 length 个字符（注意空格）
echo ${str: -5}  # 输出：World

# ${string:position:-length}：从 position 到倒数第 length 个字符
echo ${str:0:-6}  # 输出：Hello
```

### 3.4 字符串替换

```bash
#!/bin/bash

str="hello world hello"

# ${string/pattern/replacement}：替换第一个匹配
echo ${str/hello/hi}  # 输出：hi world hello

# ${string//pattern/replacement}：替换所有匹配
echo ${str//hello/hi}  # 输出：hi world hi

# ${string/#pattern/replacement}：替换开头匹配
echo ${str/#hello/hi}  # 输出：hi world hello

# ${string/%pattern/replacement}：替换结尾匹配
str2="hello world"
echo ${str2/%world/universe}  # 输出：hello universe
```

### 3.5 字符串删除

```bash
#!/bin/bash

file="path/to/file.tar.gz"

# ${string#pattern}：从开头删除最短匹配
echo ${file#*/}  # 输出：to/file.tar.gz

# ${string##pattern}：从开头删除最长匹配
echo ${file##*/}  # 输出：file.tar.gz

# ${string%pattern}：从结尾删除最短匹配
echo ${file%.*}  # 输出：path/to/file.tar

# ${string%%pattern}：从结尾删除最长匹配
echo ${file%%.*}  # 输出：path/to/file
```

**实用示例**：
```bash
#!/bin/bash

# 获取文件名和扩展名
filepath="/home/user/document.txt"

# 获取目录
dir=${filepath%/*}
echo "目录：$dir"  # /home/user

# 获取文件名
filename=${filepath##*/}
echo "文件名：$filename"  # document.txt

# 获取文件名（不含扩展名）
basename=${filename%.*}
echo "基本名：$basename"  # document

# 获取扩展名
extension=${filename##*.}
echo "扩展名：$extension"  # txt
```

---

## 四、数组

### 4.1 数组定义

```bash
#!/bin/bash

# 方法1：直接定义
array1=(value1 value2 value3)

# 方法2：单独赋值
array2[0]="first"
array2[1]="second"
array2[2]="third"

# 方法3：使用 declare
declare -a array3=("a" "b" "c")

# 方法4：从命令输出创建
array4=($(ls))
```

### 4.2 数组访问

```bash
#!/bin/bash

fruits=("苹果" "香蕉" "橙子" "葡萄")

# 访问单个元素
echo ${fruits[0]}  # 苹果
echo ${fruits[2]}  # 橙子

# 访问所有元素
echo ${fruits[@]}  # 苹果 香蕉 橙子 葡萄
echo ${fruits[*]}  # 苹果 香蕉 橙子 葡萄

# 获取数组长度
echo ${#fruits[@]}  # 4

# 获取元素长度
echo ${#fruits[0]}  # 2（苹果的字符数）

# 获取数组索引
echo ${!fruits[@]}  # 0 1 2 3
```

### 4.3 数组操作

```bash
#!/bin/bash

array=("a" "b" "c")

# 添加元素
array+=("d")
array[4]="e"

# 删除元素
unset array[1]

# 数组切片
echo ${array[@]:1:2}  # 从索引1开始，取2个元素

# 数组替换
echo ${array[@]/a/A}  # 将 a 替换为 A

# 遍历数组
for item in "${array[@]}"; do
    echo $item
done

# 带索引遍历
for i in "${!array[@]}"; do
    echo "索引 $i: ${array[$i]}"
done
```

### 4.4 关联数组（字典）

```bash
#!/bin/bash

# 声明关联数组
declare -A user

# 赋值
user[name]="张三"
user[age]=25
user[city]="北京"

# 访问
echo ${user[name]}  # 张三
echo ${user[age]}   # 25

# 获取所有键
echo ${!user[@]}  # name age city

# 获取所有值
echo ${user[@]}   # 张三 25 北京

# 遍历
for key in "${!user[@]}"; do
    echo "$key: ${user[$key]}"
done
```

---

## 五、运算符

### 5.1 算术运算

```bash
#!/bin/bash

a=10
b=3

# 方法1：使用 $(())
echo $((a + b))   # 13
echo $((a - b))   # 7
echo $((a * b))   # 30
echo $((a / b))   # 3
echo $((a % b))   # 1
echo $((a ** b))  # 1000（幂运算）

# 方法2：使用 $[]
echo $[a + b]     # 13

# 方法3：使用 expr
echo $(expr $a + $b)  # 13（注意空格）

# 方法4：使用 let
let c=a+b
echo $c           # 13

# 自增自减
let a++
echo $a           # 11
let a--
echo $a           # 10

# 浮点运算（使用 bc）
echo "scale=2; 10 / 3" | bc  # 3.33
```

### 5.2 比较运算

#### 数值比较

```bash
#!/bin/bash

a=10
b=20

# 使用 [] 或 test
if [ $a -eq $b ]; then echo "相等"; fi
if [ $a -ne $b ]; then echo "不相等"; fi
if [ $a -gt $b ]; then echo "大于"; fi
if [ $a -lt $b ]; then echo "小于"; fi
if [ $a -ge $b ]; then echo "大于等于"; fi
if [ $a -le $b ]; then echo "小于等于"; fi

# 使用 (())
if (( a == b )); then echo "相等"; fi
if (( a != b )); then echo "不相等"; fi
if (( a > b )); then echo "大于"; fi
if (( a < b )); then echo "小于"; fi
if (( a >= b )); then echo "大于等于"; fi
if (( a <= b )); then echo "小于等于"; fi
```

#### 字符串比较

```bash
#!/bin/bash

str1="hello"
str2="world"

# 字符串相等
if [ "$str1" = "$str2" ]; then echo "相等"; fi
if [ "$str1" == "$str2" ]; then echo "相等"; fi

# 字符串不相等
if [ "$str1" != "$str2" ]; then echo "不相等"; fi

# 字符串为空
if [ -z "$str1" ]; then echo "字符串为空"; fi

# 字符串非空
if [ -n "$str1" ]; then echo "字符串非空"; fi

# 字符串长度大于0
if [ "$str1" ]; then echo "字符串非空"; fi

# 字典序比较
if [[ "$str1" < "$str2" ]]; then echo "str1 < str2"; fi
if [[ "$str1" > "$str2" ]]; then echo "str1 > str2"; fi
```

#### 文件测试

```bash
#!/bin/bash

file="/etc/passwd"

# 文件存在
if [ -e "$file" ]; then echo "文件存在"; fi

# 是普通文件
if [ -f "$file" ]; then echo "是普通文件"; fi

# 是目录
if [ -d "$file" ]; then echo "是目录"; fi

# 是符号链接
if [ -L "$file" ]; then echo "是符号链接"; fi

# 文件可读
if [ -r "$file" ]; then echo "文件可读"; fi

# 文件可写
if [ -w "$file" ]; then echo "文件可写"; fi

# 文件可执行
if [ -x "$file" ]; then echo "文件可执行"; fi

# 文件非空
if [ -s "$file" ]; then echo "文件非空"; fi

# 文件1比文件2新
if [ file1 -nt file2 ]; then echo "file1 更新"; fi

# 文件1比文件2旧
if [ file1 -ot file2 ]; then echo "file1 更旧"; fi
```

### 5.3 逻辑运算

```bash
#!/bin/bash

a=10
b=20

# 逻辑与
if [ $a -lt 20 ] && [ $b -gt 10 ]; then
    echo "条件成立"
fi

if [ $a -lt 20 -a $b -gt 10 ]; then
    echo "条件成立"
fi

# 逻辑或
if [ $a -lt 5 ] || [ $b -gt 10 ]; then
    echo "条件成立"
fi

if [ $a -lt 5 -o $b -gt 10 ]; then
    echo "条件成立"
fi

# 逻辑非
if [ ! -f "/tmp/test" ]; then
    echo "文件不存在"
fi
```

---

## 六、实战练习

### 练习1：用户信息脚本

```bash
#!/bin/bash
# 获取并显示用户信息

read -p "请输入用户名：" username

if [ -z "$username" ]; then
    echo "错误：用户名不能为空"
    exit 1
fi

if id "$username" &>/dev/null; then
    echo "用户信息："
    echo "  用户名：$username"
    echo "  UID：$(id -u $username)"
    echo "  GID：$(id -g $username)"
    echo "  主目录：$(eval echo ~$username)"
    echo "  Shell：$(getent passwd $username | cut -d: -f7)"
else
    echo "错误：用户 $username 不存在"
    exit 1
fi
```

### 练习2：文件统计脚本

```bash
#!/bin/bash
# 统计目录中的文件信息

dir=${1:-.}  # 默认当前目录

if [ ! -d "$dir" ]; then
    echo "错误：$dir 不是目录"
    exit 1
fi

echo "目录：$dir"
echo "------------------------"

# 统计文件数量
file_count=$(find "$dir" -maxdepth 1 -type f | wc -l)
echo "普通文件：$file_count"

# 统计目录数量
dir_count=$(find "$dir" -maxdepth 1 -type d | wc -l)
echo "子目录：$((dir_count - 1))"

# 统计总大小
total_size=$(du -sh "$dir" | cut -f1)
echo "总大小：$total_size"

# 最大的文件
echo "最大的文件："
find "$dir" -maxdepth 1 -type f -exec ls -lh {} \; | sort -k5 -hr | head -5
```

### 练习3：系统信息脚本

```bash
#!/bin/bash
# 显示系统信息

echo "========== 系统信息 =========="
echo "主机名：$HOSTNAME"
echo "操作系统：$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "内核版本：$(uname -r)"
echo "CPU 型号：$(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
echo "CPU 核心数：$(nproc)"
echo "总内存：$(free -h | grep Mem | awk '{print $2}')"
echo "可用内存：$(free -h | grep Mem | awk '{print $7}')"
echo "磁盘使用："
df -h | grep -E '^/dev/' | awk '{print "  " $1 ": " $5 " (" $3 "/" $2 ")"}'
echo "系统负载：$(uptime | awk -F'load average:' '{print $2}')"
echo "运行时间：$(uptime -p)"
```

---

## 七、总结

本节学习了：

✅ Shell 类型和选择  
✅ 变量定义和使用  
✅ 字符串处理技巧  
✅ 数组和关联数组  
✅ 各种运算符  
✅ 实战脚本编写  

**下一节**：学习流程控制和函数编写。

---

## 参考资料

- [Bash 官方手册](https://www.gnu.org/software/bash/manual/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [ShellCheck](https://www.shellcheck.net/)
