# 三剑客学习指南

## 学习路线

```
01_grep文本过滤.md      ──▶  掌握文本搜索和过滤
        │
        ▼
02_sed流编辑器.md       ──▶  掌握文本替换和编辑
        │
        ▼
03_awk文本处理.md       ──▶  掌握结构化数据处理
        │
        ▼
04_三剑客组合实战.md    ──▶  综合运用解决实际问题
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_grep文本过滤.md | grep 基本用法、正则表达式 | 1 天 |
| 02_sed流编辑器.md | sed 替换、删除、插入 | 1.5 天 |
| 03_awk文本处理.md | awk 字段处理、统计分析 | 2 天 |
| 04_三剑客组合实战.md | 综合实战案例 | 1 天 |

## 三剑客对比

| 工具 | 擅长 | 适用场景 | 学习难度 |
|------|------|----------|----------|
| grep | 过滤、查找 | 搜索关键词、提取匹配行 | ⭐ |
| sed | 替换、编辑 | 批量替换、删除行、插入行 | ⭐⭐ |
| awk | 分析、统计 | 处理结构化数据、统计计算 | ⭐⭐⭐ |

---

## grep 速查

### 常用选项

```bash
grep -i "pattern" file        # 忽略大小写
grep -v "pattern" file        # 反向匹配
grep -n "pattern" file        # 显示行号
grep -c "pattern" file        # 统计匹配行数
grep -r "pattern" dir         # 递归搜索
grep -w "word" file           # 匹配整个单词
grep -A 3 "pattern" file      # 显示后3行
grep -B 3 "pattern" file      # 显示前3行
grep -C 3 "pattern" file      # 显示前后3行
```

### 正则表达式

```bash
grep "^root" file             # 行首
grep "bash$" file             # 行尾
grep "r..t" file              # 任意字符
grep "ro*t" file              # 重复0次或多次
grep -E "root|admin" file     # 或
grep -E "ro+t" file           # 重复1次或多次
grep -E "ro?t" file           # 重复0次或1次
```

---

## sed 速查

### 替换命令

```bash
sed 's/old/new/' file         # 替换第一个
sed 's/old/new/g' file        # 替换所有
sed 's/old/new/2' file        # 替换第2个
sed -i 's/old/new/g' file     # 直接修改文件
sed 's#/usr/local#/opt#g'     # 使用其他分隔符
```

### 删除命令

```bash
sed '1d' file                 # 删除第1行
sed '1,5d' file               # 删除第1-5行
sed '/pattern/d' file         # 删除匹配行
sed '/^$/d' file              # 删除空行
sed '/^#/d' file              # 删除注释行
```

### 插入和追加

```bash
sed '2a\New line' file        # 在第2行后追加
sed '2i\New line' file        # 在第2行前插入
sed '2c\New line' file        # 替换第2行
```

### 打印命令

```bash
sed -n '1p' file              # 打印第1行
sed -n '1,5p' file            # 打印第1-5行
sed -n '/pattern/p' file      # 打印匹配行
```

---

## awk 速查

### 基本用法

```bash
awk '{print $1}' file         # 打印第1列
awk '{print $1, $3}' file     # 打印第1和第3列
awk '{print $NF}' file        # 打印最后一列
awk -F: '{print $1}' file     # 指定分隔符
awk 'NR==1' file              # 打印第1行
awk 'NR>=1 && NR<=5' file     # 打印第1-5行
```

### 模式匹配

```bash
awk '/pattern/' file          # 匹配包含 pattern 的行
awk '$1 ~ /pattern/' file     # 第1列匹配 pattern
awk '$3 > 1000' file          # 第3列大于1000
awk '$1 == "root"' file       # 第1列等于 root
```

### 统计计算

```bash
awk '{sum += $1} END{print sum}' file                    # 求和
awk '{sum += $1} END{print sum/NR}' file                 # 平均值
awk 'BEGIN{max=0} {if($1>max) max=$1} END{print max}'   # 最大值
awk '{count[$1]++} END{for(i in count) print i, count[i]}' # 统计
```

### BEGIN 和 END

```bash
awk 'BEGIN{print "Start"} {print $0} END{print "End"}' file
awk 'BEGIN{FS=":"} {print $1}' file
awk '{sum += $1} END{print sum}' file
```

---

## 实战场景

### 场景1：日志分析

```bash
# 统计访问最多的 IP
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10

# 查找错误日志
grep -i "error" /var/log/messages | tail -20

# 统计 HTTP 状态码
awk '{print $9}' access.log | sort | uniq -c | sort -rn
```

### 场景2：配置文件处理

```bash
# 提取有效配置
grep -v "^#" config.ini | grep -v "^$"

# 批量替换
sed -i 's/old_value/new_value/g' config.ini

# 提取特定配置
grep "^port" config.ini | awk -F'=' '{print $2}'
```

### 场景3：系统监控

```bash
# 查找占用 CPU 最高的进程
ps aux | sort -k3 -rn | head -10

# 统计每个用户的进程数
ps aux | awk 'NR>1 {user[$1]++} END{for(u in user) print u, user[u]}'

# 查看内存使用
free -m | awk 'NR==2{printf "Memory Usage: %.2f%%\n", $3/$2*100}'
```

### 场景4：数据处理

```bash
# CSV 转 TSV
awk -F',' '{print $1"\t"$2"\t"$3}' file.csv

# 计算总和
awk '{sum += $1} END{print sum}' numbers.txt

# 按列排序
sort -k2 -n file.txt
```

---

## 学习建议

### 1. 循序渐进

- 先学 grep（最简单）
- 再学 sed（中等难度）
- 最后学 awk（最复杂）

### 2. 多练习

- 每个命令都要实际操作
- 尝试解决实际问题
- 查看系统日志练习

### 3. 理解原理

- grep：逐行匹配模式
- sed：逐行读取、处理、输出
- awk：按字段处理结构化数据

### 4. 组合使用

- 单个工具解决简单问题
- 组合使用解决复杂问题
- 选择最合适的工具

---

## 常见问题

### 1. 何时用 grep？

- 简单的文本搜索
- 过滤日志
- 查找文件内容

### 2. 何时用 sed？

- 批量替换文本
- 删除特定行
- 插入或追加内容

### 3. 何时用 awk？

- 处理结构化数据（表格、CSV）
- 统计计算
- 复杂的文本分析

### 4. 如何选择？

```bash
# 简单搜索 → grep
grep "error" file.txt

# 简单替换 → sed
sed 's/old/new/g' file.txt

# 复杂处理 → awk
awk '{sum += $1} END{print sum}' file.txt

# 组合使用 → 管道
grep "error" file.txt | awk '{print $1}' | sort | uniq -c
```

---

## 性能优化

### 1. 减少管道

```bash
# ❌ 低效
cat file.txt | grep "pattern" | awk '{print $1}'

# ✅ 高效
awk '/pattern/ {print $1}' file.txt
```

### 2. 避免不必要的命令

```bash
# ❌ 低效
cat file.txt | grep "pattern"

# ✅ 高效
grep "pattern" file.txt
```

### 3. 使用合适的工具

```bash
# ❌ 低效
grep "pattern" file.txt | wc -l

# ✅ 高效
grep -c "pattern" file.txt
```

---

## 面试常考

1. grep、sed、awk 的区别和适用场景？
2. 如何用 awk 统计文件的行数？
3. 如何用 sed 批量替换文件内容？
4. 如何用 grep 查找不包含某个关键词的行？
5. 如何统计日志中访问最多的 IP？

## 下一步

完成三剑客学习后，进入「Linux系统优化」模块，学习系统性能调优和安全加固。
