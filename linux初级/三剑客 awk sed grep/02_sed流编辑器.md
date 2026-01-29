# sed 流编辑器

## 什么是 sed

sed（Stream Editor）是流编辑器，用于对文本进行过滤和转换，特别擅长批量替换和编辑。

---

## 一、基本用法

### 基本语法

```bash
sed [选项] '命令' 文件
```

### 简单示例

```bash
# 打印文件内容
sed '' file.txt

# 打印特定行
sed -n '1p' file.txt              # 第1行
sed -n '1,5p' file.txt            # 第1-5行
sed -n '$p' file.txt              # 最后一行
```

---

## 二、常用选项

### -n 静默模式

```bash
# 默认会打印所有行
sed 's/old/new/' file.txt

# -n 只打印处理的行
sed -n 's/old/new/p' file.txt
```

### -i 直接修改文件

```bash
# 不加 -i，只显示结果，不修改文件
sed 's/old/new/' file.txt

# 加 -i，直接修改文件
sed -i 's/old/new/' file.txt

# 备份原文件
sed -i.bak 's/old/new/' file.txt  # 生成 file.txt.bak
```

### -e 多个命令

```bash
# 执行多个命令
sed -e 's/old/new/' -e 's/foo/bar/' file.txt

# 或使用分号
sed 's/old/new/; s/foo/bar/' file.txt
```

### -f 从文件读取命令

```bash
# 创建命令文件
cat > sed_commands.txt << 'EOF'
s/old/new/g
s/foo/bar/g
EOF

# 执行
sed -f sed_commands.txt file.txt
```

---

## 三、替换命令 s

### 基本替换

```bash
# 替换第一个匹配
sed 's/old/new/' file.txt

# 替换所有匹配（g 标志）
sed 's/old/new/g' file.txt

# 替换第2个匹配
sed 's/old/new/2' file.txt

# 替换第2个及之后的所有匹配
sed 's/old/new/2g' file.txt
```

### 分隔符

```bash
# 默认使用 /
sed 's/old/new/' file.txt

# 可以使用其他字符作为分隔符
sed 's|old|new|' file.txt
sed 's:old:new:' file.txt
sed 's#old#new#' file.txt

# 处理路径时很有用
sed 's#/usr/local#/opt#g' file.txt
```

### 替换标志

```bash
# g: 全局替换
sed 's/old/new/g' file.txt

# p: 打印替换的行
sed -n 's/old/new/p' file.txt

# i: 忽略大小写
sed 's/old/new/gi' file.txt

# w: 将替换的行写入文件
sed 's/old/new/w output.txt' file.txt
```

---

## 四、删除命令 d

### 删除行

```bash
# 删除第1行
sed '1d' file.txt

# 删除第1-5行
sed '1,5d' file.txt

# 删除最后一行
sed '$d' file.txt

# 删除空行
sed '/^$/d' file.txt

# 删除包含 pattern 的行
sed '/pattern/d' file.txt

# 删除不包含 pattern 的行
sed '/pattern/!d' file.txt
```

### 实用示例

```bash
# 删除注释行
sed '/^#/d' file.txt

# 删除注释和空行
sed '/^#/d; /^$/d' file.txt

# 删除行首空格
sed 's/^[ \t]*//' file.txt

# 删除行尾空格
sed 's/[ \t]*$//' file.txt
```

---

## 五、插入和追加

### a 追加（在行后）

```bash
# 在第2行后追加
sed '2a\New line' file.txt

# 在匹配行后追加
sed '/pattern/a\New line' file.txt

# 追加多行
sed '2a\Line 1\nLine 2\nLine 3' file.txt
```

### i 插入（在行前）

```bash
# 在第2行前插入
sed '2i\New line' file.txt

# 在匹配行前插入
sed '/pattern/i\New line' file.txt

# 在文件开头插入
sed '1i\Header line' file.txt
```

### c 替换整行

```bash
# 替换第2行
sed '2c\New line' file.txt

# 替换匹配的行
sed '/pattern/c\New line' file.txt

# 替换多行
sed '2,4c\New lines' file.txt
```

---

## 六、打印命令 p

### 打印行

```bash
# 打印第1行
sed -n '1p' file.txt

# 打印第1-5行
sed -n '1,5p' file.txt

# 打印奇数行
sed -n '1~2p' file.txt

# 打印偶数行
sed -n '2~2p' file.txt

# 打印匹配的行
sed -n '/pattern/p' file.txt
```

---

## 七、地址范围

### 行号范围

```bash
# 第1行
sed -n '1p' file.txt

# 第1-5行
sed -n '1,5p' file.txt

# 第1行到最后一行
sed -n '1,$p' file.txt

# 最后一行
sed -n '$p' file.txt

# 从第5行到文件末尾
sed -n '5,$p' file.txt
```

### 模式范围

```bash
# 从匹配 start 到匹配 end 的行
sed -n '/start/,/end/p' file.txt

# 从第5行到匹配 pattern 的行
sed -n '5,/pattern/p' file.txt

# 从匹配 pattern 到第10行
sed -n '/pattern/,10p' file.txt
```

### 步进

```bash
# 每隔2行（奇数行）
sed -n '1~2p' file.txt

# 从第2行开始，每隔3行
sed -n '2~3p' file.txt
```

---

## 八、实战案例

### 案例1：配置文件修改

```bash
# 修改 SSH 端口
sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config

# 禁用 root 登录
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 修改多个配置
sed -i -e 's/^#Port 22/Port 2222/' \
       -e 's/^PermitRootLogin yes/PermitRootLogin no/' \
       /etc/ssh/sshd_config
```

### 案例2：日志处理

```bash
# 提取特定时间的日志
sed -n '/2024-01-07 10:/,/2024-01-07 11:/p' /var/log/messages

# 删除旧日志
sed -i '/2024-01-01/,/2024-01-05/d' /var/log/app.log

# 替换敏感信息
sed -i 's/password=[^&]*/password=****/g' /var/log/app.log
```

### 案例3：批量重命名

```bash
# 生成重命名命令
ls *.txt | sed 's/\(.*\)\.txt/mv & \1.bak/' | bash

# 或使用 sed 配合 xargs
ls *.txt | sed 's/\.txt$//' | xargs -I {} mv {}.txt {}.bak
```

### 案例4：文本格式化

```bash
# 删除空行
sed '/^$/d' file.txt

# 删除行首空格
sed 's/^[ \t]*//' file.txt

# 删除行尾空格
sed 's/[ \t]*$//' file.txt

# 删除所有空格
sed 's/ //g' file.txt

# 将多个空格替换为一个
sed 's/  */ /g' file.txt
```

### 案例5：数据提取

```bash
# 提取 IP 地址
sed -n 's/.*\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/p' file.txt

# 提取邮箱
sed -n 's/.*\([a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}\).*/\1/p' file.txt

# 提取 URL
sed -n 's/.*\(https\?:\/\/[^ ]*\).*/\1/p' file.txt
```

---

## 九、高级技巧

### 反向引用

```bash
# 交换两个单词
echo "hello world" | sed 's/\(hello\) \(world\)/\2 \1/'
# world hello

# 提取并重组
echo "2024-01-07" | sed 's/\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)/\3\/\2\/\1/'
# 07/01/2024
```

### 多行处理

```bash
# N: 读取下一行到模式空间
sed 'N; s/\n/ /' file.txt        # 合并两行

# D: 删除模式空间中的第一行
sed 'N; /pattern/D' file.txt

# P: 打印模式空间中的第一行
sed 'N; P; D' file.txt
```

### 保持空间

```bash
# h: 复制模式空间到保持空间
# g: 复制保持空间到模式空间
# x: 交换模式空间和保持空间

# 倒序输出文件
sed '1!G; h; $!d' file.txt
```

---

## 十、sed 脚本

### 创建 sed 脚本

```bash
# 创建脚本文件
cat > process.sed << 'EOF'
# 删除注释和空行
/^#/d
/^$/d

# 替换配置
s/old_value/new_value/g
s/port=80/port=8080/g

# 添加注释
1i\# Configuration file
EOF

# 执行脚本
sed -f process.sed config.txt
```

### 实用脚本示例

```bash
# 清理配置文件
cat > clean_config.sed << 'EOF'
# 删除注释
/^#/d
/^;/d

# 删除空行
/^$/d

# 删除行首尾空格
s/^[ \t]*//
s/[ \t]*$//
EOF

sed -f clean_config.sed config.ini > config_clean.ini
```

---

## 十一、常见问题

### 1. 特殊字符转义

```bash
# 替换包含 / 的路径
sed 's#/usr/local#/opt#g' file.txt

# 替换包含 $ 的变量
sed 's/\$VAR/\$NEW_VAR/g' file.txt

# 替换包含 & 的字符
sed 's/\&/and/g' file.txt
```

### 2. 就地编辑安全

```bash
# 先备份再修改
cp file.txt file.txt.bak
sed -i 's/old/new/g' file.txt

# 或使用 -i.bak
sed -i.bak 's/old/new/g' file.txt
```

### 3. 性能优化

```bash
# 只处理匹配的行
sed '/pattern/s/old/new/g' file.txt

# 找到第一个匹配后退出
sed '/pattern/q' file.txt
```

---

## 练习题

1. 如何替换文件中所有的 old 为 new？
2. 如何删除文件中的空行？
3. 如何在文件开头插入一行？

<details>
<summary>答案</summary>

1. `sed -i 's/old/new/g' file.txt`
2. `sed -i '/^$/d' file.txt`
3. `sed -i '1i\New first line' file.txt`

</details>
