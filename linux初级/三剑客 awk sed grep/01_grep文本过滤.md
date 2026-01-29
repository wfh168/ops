# grep 文本过滤

## 什么是 grep

grep（Global Regular Expression Print）是 Linux 最常用的文本搜索工具，用于在文件中查找匹配的行。

---

## 一、基本用法

### 基本语法

```bash
grep [选项] 模式 文件
```

### 简单搜索

```bash
# 在文件中搜索
grep "root" /etc/passwd

# 在多个文件中搜索
grep "error" /var/log/*.log

# 从标准输入搜索
ps aux | grep nginx
cat file.txt | grep "keyword"
```

---

## 二、常用选项

### -i 忽略大小写

```bash
grep -i "error" /var/log/messages
# 匹配 error、Error、ERROR 等
```

### -v 反向匹配（排除）

```bash
# 显示不包含 root 的行
grep -v "root" /etc/passwd

# 排除注释行
grep -v "^#" /etc/ssh/sshd_config

# 排除空行
grep -v "^$" file.txt

# 排除注释和空行
grep -v "^#" file.txt | grep -v "^$"
```

### -n 显示行号

```bash
grep -n "error" /var/log/messages
# 10:error message
# 25:another error
```

### -c 统计匹配行数

```bash
grep -c "error" /var/log/messages
# 15

# 统计不匹配的行数
grep -vc "error" /var/log/messages
```

### -l 只显示文件名

```bash
# 显示包含 error 的文件名
grep -l "error" /var/log/*.log

# 显示不包含 error 的文件名
grep -L "error" /var/log/*.log
```

### -r 递归搜索

```bash
# 递归搜索目录
grep -r "error" /var/log/

# 递归搜索，显示行号
grep -rn "error" /var/log/

# 递归搜索，只显示文件名
grep -rl "error" /var/log/
```

### -w 匹配整个单词

```bash
# 只匹配完整的 root，不匹配 groot
grep -w "root" /etc/passwd

# 对比
grep "root" /etc/passwd      # 匹配 root 和 groot
grep -w "root" /etc/passwd   # 只匹配 root
```

### -A/-B/-C 显示上下文

```bash
# -A n: 显示匹配行及后面 n 行
grep -A 3 "error" /var/log/messages

# -B n: 显示匹配行及前面 n 行
grep -B 3 "error" /var/log/messages

# -C n: 显示匹配行及前后各 n 行
grep -C 3 "error" /var/log/messages
```

### -o 只显示匹配部分

```bash
# 只显示匹配的文本
echo "hello world" | grep -o "world"
# world

# 提取 IP 地址
grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" access.log
```

### --color 高亮显示

```bash
# 高亮显示匹配内容
grep --color "error" /var/log/messages

# 设置别名（永久高亮）
alias grep='grep --color=auto'
```

---

## 三、正则表达式

### 基本正则表达式（BRE）

```bash
# ^ 行首
grep "^root" /etc/passwd      # 以 root 开头的行

# $ 行尾
grep "bash$" /etc/passwd      # 以 bash 结尾的行

# . 任意单个字符
grep "r..t" /etc/passwd       # r 和 t 之间有两个字符

# * 前面字符重复0次或多次
grep "ro*t" file.txt          # rt, rot, root, rooot...

# [] 字符集合
grep "[Rr]oot" /etc/passwd    # Root 或 root
grep "[0-9]" file.txt         # 包含数字的行
grep "[a-z]" file.txt         # 包含小写字母的行

# [^] 排除字符集合
grep "[^0-9]" file.txt        # 不包含数字的行

# \ 转义字符
grep "\." file.txt            # 匹配点号本身
```

### 扩展正则表达式（ERE）

使用 `grep -E` 或 `egrep`

```bash
# + 前面字符重复1次或多次
grep -E "ro+t" file.txt       # rot, root, rooot...

# ? 前面字符重复0次或1次
grep -E "ro?t" file.txt       # rt, rot

# | 或
grep -E "root|admin" /etc/passwd

# () 分组
grep -E "(root|admin):" /etc/passwd

# {n} 重复n次
grep -E "o{2}" file.txt       # oo

# {n,} 重复至少n次
grep -E "o{2,}" file.txt      # oo, ooo, oooo...

# {n,m} 重复n到m次
grep -E "o{2,4}" file.txt     # oo, ooo, oooo
```

---

## 四、实战案例

### 案例1：日志分析

```bash
# 查找错误日志
grep -i "error" /var/log/messages

# 查找最近的错误（显示后10行）
grep -A 10 "error" /var/log/messages | tail -20

# 统计错误数量
grep -c "error" /var/log/messages

# 查找特定时间的日志
grep "Jan  7 10:" /var/log/messages

# 查找多个关键词
grep -E "error|warning|critical" /var/log/messages
```

### 案例2：查找进程

```bash
# 查找 nginx 进程
ps aux | grep nginx

# 排除 grep 自身
ps aux | grep nginx | grep -v grep

# 更好的方式
ps aux | grep [n]ginx

# 查找并统计
ps aux | grep nginx | grep -v grep | wc -l
```

### 案例3：配置文件分析

```bash
# 查看有效配置（排除注释和空行）
grep -v "^#" /etc/ssh/sshd_config | grep -v "^$"

# 查找特定配置
grep "^Port" /etc/ssh/sshd_config

# 查找未注释的配置
grep "^[^#]" /etc/nginx/nginx.conf
```

### 案例4：网络分析

```bash
# 查找监听端口
netstat -tunlp | grep LISTEN

# 查找特定端口
netstat -tunlp | grep ":80"

# 统计连接数
netstat -an | grep ESTABLISHED | wc -l

# 查找 IP 地址
grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" access.log | sort | uniq -c | sort -rn
```

### 案例5：用户管理

```bash
# 查找特定用户
grep "^username:" /etc/passwd

# 查找 UID 大于 1000 的用户
awk -F: '$3 >= 1000' /etc/passwd

# 查找有登录 shell 的用户
grep -v "nologin" /etc/passwd | grep -v "false"

# 查找属于特定组的用户
grep "wheel" /etc/group
```

---

## 五、高级技巧

### 组合使用

```bash
# 多个条件（AND）
grep "error" /var/log/messages | grep "mysql"

# 多个条件（OR）
grep -E "error|warning" /var/log/messages

# 排除多个模式
grep -v "error" file.txt | grep -v "warning"
```

### 性能优化

```bash
# 使用 -F 进行固定字符串搜索（更快）
grep -F "exact string" large_file.txt

# 限制搜索深度
grep -r --max-depth=2 "pattern" /var/log/

# 只搜索文本文件
grep -r --include="*.log" "pattern" /var/log/
grep -r --exclude="*.gz" "pattern" /var/log/
```

### 输出控制

```bash
# 静默模式（只返回状态码）
grep -q "pattern" file.txt
if [ $? -eq 0 ]; then
    echo "Found"
fi

# 限制输出行数
grep "error" /var/log/messages | head -10

# 只显示第一个匹配
grep -m 1 "error" /var/log/messages
```

---

## 六、grep 变体

### egrep（等同于 grep -E）

```bash
# 扩展正则表达式
egrep "root|admin" /etc/passwd
grep -E "root|admin" /etc/passwd  # 等同
```

### fgrep（等同于 grep -F）

```bash
# 固定字符串搜索（不解析正则）
fgrep "." file.txt                # 匹配点号本身
grep -F "." file.txt              # 等同
```

### zgrep

```bash
# 搜索压缩文件
zgrep "error" /var/log/messages.gz
```

---

## 七、实用脚本

### 脚本1：日志监控

```bash
#!/bin/bash

LOGFILE="/var/log/messages"
KEYWORD="error"
ALERT_EMAIL="admin@example.com"

# 查找最近5分钟的错误
if grep "$KEYWORD" $LOGFILE | grep "$(date '+%b %d %H:%M')" > /dev/null; then
    grep "$KEYWORD" $LOGFILE | tail -10 | mail -s "Error Alert" $ALERT_EMAIL
fi
```

### 脚本2：批量查找

```bash
#!/bin/bash

# 在多个文件中查找关键词
KEYWORD="$1"
DIRECTORY="${2:-.}"

echo "Searching for '$KEYWORD' in $DIRECTORY"
grep -rn --color "$KEYWORD" "$DIRECTORY"
```

### 脚本3：提取信息

```bash
#!/bin/bash

# 提取访问日志中的 IP 地址并统计
grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" /var/log/nginx/access.log | \
    sort | uniq -c | sort -rn | head -10
```

---

## 八、常见问题

### 1. 搜索特殊字符

```bash
# 搜索包含 $ 的行
grep '\$' file.txt

# 搜索包含 . 的行
grep '\.' file.txt

# 搜索包含 * 的行
grep '\*' file.txt
```

### 2. 搜索多行模式

```bash
# grep 默认按行匹配，多行需要其他工具
# 使用 pcregrep
pcregrep -M "pattern1.*\n.*pattern2" file.txt

# 或使用 awk/sed
```

### 3. 性能问题

```bash
# 大文件搜索慢
# 使用 -F 固定字符串搜索
grep -F "string" large_file.txt

# 限制搜索范围
grep "pattern" file.txt | head -100
```

---

## 练习题

1. 如何查找不包含 root 的行？
2. 如何递归搜索目录中的所有文件？
3. 如何显示匹配行的前后3行？

<details>
<summary>答案</summary>

1. `grep -v "root" /etc/passwd`
2. `grep -r "pattern" /path/to/directory`
3. `grep -C 3 "pattern" file.txt`

</details>
