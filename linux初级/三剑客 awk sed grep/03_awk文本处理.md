# awk 文本处理

## 什么是 awk

awk 是强大的文本处理工具，特别擅长处理结构化数据（如表格、日志）。

---

## 一、基本概念

### 工作原理

```
输入 → 按行读取 → 按分隔符分割成字段 → 处理 → 输出
```

### 基本语法

```bash
awk [选项] '模式{动作}' 文件
```

### 内置变量

| 变量 | 说明 |
|------|------|
| $0 | 整行内容 |
| $1, $2, $3... | 第1、2、3...个字段 |
| NF | 字段数量 |
| NR | 当前行号 |
| FNR | 当前文件的行号 |
| FS | 字段分隔符（默认空格） |
| OFS | 输出字段分隔符 |
| RS | 记录分隔符（默认换行） |
| ORS | 输出记录分隔符 |
| FILENAME | 当前文件名 |

---

## 二、基本用法

### 打印字段

```bash
# 打印第1列
awk '{print $1}' file.txt

# 打印第1和第3列
awk '{print $1, $3}' file.txt

# 打印整行
awk '{print $0}' file.txt
awk '{print}' file.txt            # 简写

# 打印最后一列
awk '{print $NF}' file.txt

# 打印倒数第二列
awk '{print $(NF-1)}' file.txt
```

### 指定分隔符

```bash
# 使用 : 作为分隔符
awk -F: '{print $1}' /etc/passwd

# 使用多个分隔符
awk -F'[,:]' '{print $1}' file.txt

# 在 awk 内部指定
awk 'BEGIN{FS=":"} {print $1}' /etc/passwd
```

### 格式化输出

```bash
# 添加文本
awk '{print "User:", $1}' file.txt

# 使用 printf 格式化
awk '{printf "%-10s %s\n", $1, $2}' file.txt

# 添加行号
awk '{print NR, $0}' file.txt
```

---

## 三、模式匹配

### 正则表达式

```bash
# 匹配包含 root 的行
awk '/root/' /etc/passwd

# 匹配第1列包含 root
awk '$1 ~ /root/' file.txt

# 匹配第1列不包含 root
awk '$1 !~ /root/' file.txt

# 匹配以 root 开头的行
awk '/^root/' /etc/passwd
```

### 条件匹配

```bash
# 第3列等于0
awk -F: '$3 == 0' /etc/passwd

# 第3列大于1000
awk -F: '$3 > 1000' /etc/passwd

# 第3列在范围内
awk -F: '$3 >= 1000 && $3 <= 2000' /etc/passwd

# 第1列等于 root
awk -F: '$1 == "root"' /etc/passwd

# 字段数量大于5
awk 'NF > 5' file.txt
```

### 行号匹配

```bash
# 打印第1行
awk 'NR == 1' file.txt

# 打印第1-5行
awk 'NR >= 1 && NR <= 5' file.txt
awk 'NR <= 5' file.txt            # 简写

# 打印奇数行
awk 'NR % 2 == 1' file.txt

# 打印偶数行
awk 'NR % 2 == 0' file.txt
```

---

## 四、BEGIN 和 END

### BEGIN 块

```bash
# 在处理前执行
awk 'BEGIN{print "Start"} {print $0} END{print "End"}' file.txt

# 设置分隔符
awk 'BEGIN{FS=":"} {print $1}' /etc/passwd

# 打印表头
awk 'BEGIN{print "Name\tAge"} {print $1, $2}' file.txt
```

### END 块

```bash
# 统计行数
awk 'END{print NR}' file.txt

# 统计总和
awk '{sum += $1} END{print sum}' numbers.txt

# 计算平均值
awk '{sum += $1} END{print sum/NR}' numbers.txt
```

---

## 五、运算和变量

### 数学运算

```bash
# 加法
awk '{print $1 + $2}' file.txt

# 乘法
awk '{print $1 * $2}' file.txt

# 计算百分比
awk '{print $1/$2*100 "%"}' file.txt

# 累加
awk '{sum += $1} END{print sum}' file.txt
```

### 自定义变量

```bash
# 定义变量
awk '{total += $1; count++} END{print total/count}' file.txt

# 使用 -v 传递变量
awk -v name="John" '{print name, $0}' file.txt

# 多个变量
awk -v a=10 -v b=20 'BEGIN{print a+b}'
```

### 字符串操作

```bash
# 字符串连接
awk '{print $1 $2}' file.txt
awk '{print $1 "-" $2}' file.txt

# 字符串长度
awk '{print length($1)}' file.txt

# 子字符串
awk '{print substr($1, 1, 3)}' file.txt  # 从第1个字符开始，取3个

# 大小写转换
awk '{print toupper($1)}' file.txt       # 转大写
awk '{print tolower($1)}' file.txt       # 转小写
```

---

## 六、数组

### 关联数组

```bash
# 统计每个单词出现次数
awk '{for(i=1;i<=NF;i++) count[$i]++} END{for(word in count) print word, count[word]}' file.txt

# 统计 IP 访问次数
awk '{ip[$1]++} END{for(i in ip) print i, ip[i]}' access.log

# 按值排序
awk '{ip[$1]++} END{for(i in ip) print ip[i], i}' access.log | sort -rn
```

---

## 七、控制语句

### if-else

```bash
# if 语句
awk '{if($3 > 1000) print $1}' file.txt

# if-else
awk '{if($3 > 1000) print $1 " is large"; else print $1 " is small"}' file.txt

# 多条件
awk '{
    if($3 < 100) level="low"
    else if($3 < 1000) level="medium"
    else level="high"
    print $1, level
}' file.txt
```

### for 循环

```bash
# 遍历字段
awk '{for(i=1; i<=NF; i++) print $i}' file.txt

# 遍历数组
awk '{for(i=1;i<=NF;i++) count[$i]++} END{for(word in count) print word, count[word]}' file.txt

# 指定范围
awk 'BEGIN{for(i=1; i<=10; i++) print i}'
```

### while 循环

```bash
# while 循环
awk '{i=1; while(i<=NF) {print $i; i++}}' file.txt
```

---

## 八、实战案例

### 案例1：分析 /etc/passwd

```bash
# 提取用户名
awk -F: '{print $1}' /etc/passwd

# 提取 UID 大于 1000 的用户
awk -F: '$3 > 1000 {print $1, $3}' /etc/passwd

# 统计用户使用的 shell
awk -F: '{shell[$NF]++} END{for(s in shell) print s, shell[s]}' /etc/passwd

# 格式化输出
awk -F: 'BEGIN{printf "%-15s %-10s %s\n", "User", "UID", "Shell"} 
         {printf "%-15s %-10s %s\n", $1, $3, $NF}' /etc/passwd
```

### 案例2：日志分析

```bash
# 统计访问最多的 IP
awk '{ip[$1]++} END{for(i in ip) print ip[i], i}' access.log | sort -rn | head -10

# 统计 HTTP 状态码
awk '{status[$9]++} END{for(s in status) print s, status[s]}' access.log

# 统计访问的 URL
awk '{url[$7]++} END{for(u in url) print url[u], u}' access.log | sort -rn | head -10

# 计算平均响应时间
awk '{sum+=$NF; count++} END{print sum/count}' access.log
```

### 案例3：系统监控

```bash
# 查看内存使用
free -m | awk 'NR==2{printf "Memory Usage: %.2f%%\n", $3/$2*100}'

# 查看磁盘使用
df -h | awk 'NR>1 {print $NF, $5}'

# 查看 CPU 使用
top -bn1 | awk '/Cpu/ {print "CPU Usage:", 100-$8 "%"}'

# 统计进程数
ps aux | awk 'NR>1 {user[$1]++} END{for(u in user) print u, user[u]}'
```

### 案例4：数据处理

```bash
# 计算总和
awk '{sum += $1} END{print "Total:", sum}' numbers.txt

# 计算平均值
awk '{sum += $1; count++} END{print "Average:", sum/count}' numbers.txt

# 找最大值
awk 'BEGIN{max=0} {if($1>max) max=$1} END{print "Max:", max}' numbers.txt

# 找最小值
awk 'NR==1{min=$1} {if($1<min) min=$1} END{print "Min:", min}' numbers.txt
```

### 案例5：文本转换

```bash
# CSV 转 TSV
awk -F',' '{print $1"\t"$2"\t"$3}' file.csv

# 交换列
awk '{print $2, $1}' file.txt

# 合并行
awk '{printf "%s ", $0} END{print ""}' file.txt

# 添加行号
awk '{print NR, $0}' file.txt
```

---

## 九、高级技巧

### 多文件处理

```bash
# 处理多个文件
awk '{print FILENAME, $0}' file1.txt file2.txt

# 区分文件
awk 'FNR==1{print "--- " FILENAME " ---"} {print}' file1.txt file2.txt

# 合并文件
awk 'FNR==NR{a[NR]=$0; next} {print a[FNR], $0}' file1.txt file2.txt
```

### 函数

```bash
# 内置函数
awk '{print length($0)}' file.txt           # 字符串长度
awk '{print substr($1, 1, 3)}' file.txt     # 子字符串
awk '{print toupper($1)}' file.txt          # 转大写
awk '{print tolower($1)}' file.txt          # 转小写
awk '{print index($0, "pattern")}' file.txt # 查找位置
awk '{print split($0, arr, ",")}' file.txt  # 分割字符串

# 数学函数
awk '{print sqrt($1)}' file.txt             # 平方根
awk '{print int($1)}' file.txt              # 取整
awk '{print rand()}' file.txt               # 随机数
```

### 自定义函数

```bash
awk '
function max(a, b) {
    return a > b ? a : b
}
{
    print max($1, $2)
}' file.txt
```

---

## 十、awk 脚本

### 创建 awk 脚本

```bash
# 创建脚本文件
cat > process.awk << 'EOF'
BEGIN {
    FS = ":"
    print "User Report"
    print "==========="
}

$3 > 1000 {
    users++
    print $1, $3
}

END {
    print "==========="
    print "Total users:", users
}
EOF

# 执行脚本
awk -f process.awk /etc/passwd
```

### 复杂脚本示例

```bash
cat > analyze_log.awk << 'EOF'
BEGIN {
    print "Log Analysis Report"
    print "==================="
}

{
    # 统计 IP
    ip[$1]++
    
    # 统计状态码
    status[$9]++
    
    # 累计流量
    traffic += $10
}

END {
    print "\nTop 5 IPs:"
    for (i in ip) {
        print ip[i], i
    }
    
    print "\nStatus Codes:"
    for (s in status) {
        print s, status[s]
    }
    
    print "\nTotal Traffic:", traffic/1024/1024, "MB"
}
EOF

awk -f analyze_log.awk access.log
```

---

## 练习题

1. 如何打印文件的第2列？
2. 如何统计文件的行数？
3. 如何计算第1列的总和？

<details>
<summary>答案</summary>

1. `awk '{print $2}' file.txt`
2. `awk 'END{print NR}' file.txt`
3. `awk '{sum += $1} END{print sum}' file.txt`

</details>
