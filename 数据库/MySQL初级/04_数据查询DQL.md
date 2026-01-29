# 数据查询（DQL）

## 一、SELECT 基础查询

### 1.1 基本语法

```sql
SELECT column1, column2, ...
FROM table_name;
```

### 1.2 查询所有列

```sql
-- 查询所有列（不推荐在生产环境使用）
SELECT * FROM students;

-- 推荐：明确指定列名
SELECT id, name, age, gender, email FROM students;
```

### 1.3 查询指定列

```sql
-- 查询单列
SELECT name FROM students;

-- 查询多列
SELECT name, age, gender FROM students;
```

### 1.4 列别名

```sql
-- 使用 AS 关键字
SELECT name AS 姓名, age AS 年龄 FROM students;

-- 省略 AS
SELECT name 姓名, age 年龄 FROM students;

-- 别名包含空格（使用引号）
SELECT name AS '学生姓名', age AS '学生年龄' FROM students;
```

### 1.5 去重查询

```sql
-- 查询不重复的年龄
SELECT DISTINCT age FROM students;

-- 查询不重复的性别
SELECT DISTINCT gender FROM students;

-- 多列去重
SELECT DISTINCT age, gender FROM students;
```

### 1.6 计算列

```sql
-- 数值计算
SELECT name, age, age + 1 AS next_year_age FROM students;

-- 字符串拼接
SELECT CONCAT(name, '-', age) AS info FROM students;

-- 条件表达式
SELECT name, age,
    CASE 
        WHEN age >= 18 THEN '成年'
        ELSE '未成年'
    END AS age_status
FROM students;
```

---

## 二、WHERE 条件过滤

### 2.1 比较运算符

```sql
-- 等于
SELECT * FROM students WHERE age = 20;

-- 不等于
SELECT * FROM students WHERE age != 20;
SELECT * FROM students WHERE age <> 20;

-- 大于
SELECT * FROM students WHERE age > 18;

-- 小于
SELECT * FROM students WHERE age < 25;

-- 大于等于
SELECT * FROM students WHERE age >= 20;

-- 小于等于
SELECT * FROM students WHERE age <= 22;
```

### 2.2 逻辑运算符

```sql
-- AND（与）
SELECT * FROM students WHERE age >= 18 AND gender = '男';

-- OR（或）
SELECT * FROM students WHERE age < 18 OR age > 25;

-- NOT（非）
SELECT * FROM students WHERE NOT age = 20;

-- 组合使用
SELECT * FROM students 
WHERE (age >= 18 AND age <= 25) AND gender = '女';
```

### 2.3 范围查询

```sql
-- BETWEEN...AND（包含边界值）
SELECT * FROM students WHERE age BETWEEN 18 AND 25;

-- 等价于
SELECT * FROM students WHERE age >= 18 AND age <= 25;

-- NOT BETWEEN
SELECT * FROM students WHERE age NOT BETWEEN 18 AND 25;
```

### 2.4 IN 查询

```sql
-- IN（在列表中）
SELECT * FROM students WHERE age IN (18, 20, 22);

-- 等价于
SELECT * FROM students WHERE age = 18 OR age = 20 OR age = 22;

-- NOT IN
SELECT * FROM students WHERE age NOT IN (18, 20, 22);

-- 字符串 IN
SELECT * FROM students WHERE name IN ('张三', '李四', '王五');
```

### 2.5 NULL 值查询

```sql
-- IS NULL（为空）
SELECT * FROM students WHERE email IS NULL;

-- IS NOT NULL（不为空）
SELECT * FROM students WHERE email IS NOT NULL;

-- 注意：不能使用 = NULL 或 != NULL
-- ❌ 错误
SELECT * FROM students WHERE email = NULL;

-- ✅ 正确
SELECT * FROM students WHERE email IS NULL;
```

### 2.6 模糊查询

```sql
-- LIKE 模糊匹配
-- % 表示任意多个字符
-- _ 表示单个字符

-- 以"张"开头
SELECT * FROM students WHERE name LIKE '张%';

-- 以"三"结尾
SELECT * FROM students WHERE name LIKE '%三';

-- 包含"小"
SELECT * FROM students WHERE name LIKE '%小%';

-- 第二个字符是"小"
SELECT * FROM students WHERE name LIKE '_小%';

-- 名字是两个字
SELECT * FROM students WHERE name LIKE '__';

-- 名字是三个字
SELECT * FROM students WHERE name LIKE '___';

-- NOT LIKE
SELECT * FROM students WHERE name NOT LIKE '张%';

-- 转义特殊字符
SELECT * FROM students WHERE email LIKE '%\_%' ESCAPE '\';
```

---

## 三、ORDER BY 排序

### 3.1 单列排序

```sql
-- 升序排序（ASC，默认）
SELECT * FROM students ORDER BY age;
SELECT * FROM students ORDER BY age ASC;

-- 降序排序（DESC）
SELECT * FROM students ORDER BY age DESC;

-- 按姓名排序
SELECT * FROM students ORDER BY name;
```

### 3.2 多列排序

```sql
-- 先按年龄升序，年龄相同按姓名升序
SELECT * FROM students ORDER BY age ASC, name ASC;

-- 先按年龄降序，年龄相同按姓名升序
SELECT * FROM students ORDER BY age DESC, name ASC;

-- 多列排序
SELECT * FROM students ORDER BY gender, age DESC, name;
```

### 3.3 按列位置排序

```sql
-- 按第2列排序
SELECT name, age, gender FROM students ORDER BY 2;

-- 按第3列降序排序
SELECT name, age, gender FROM students ORDER BY 3 DESC;
```

### 3.4 按表达式排序

```sql
-- 按计算结果排序
SELECT name, age, age + 10 AS future_age 
FROM students 
ORDER BY age + 10;

-- 按别名排序
SELECT name, age, age + 10 AS future_age 
FROM students 
ORDER BY future_age;

-- 按函数结果排序
SELECT name, LENGTH(name) AS name_length 
FROM students 
ORDER BY LENGTH(name) DESC;
```

### 3.5 NULL 值排序

```sql
-- NULL 值默认排在最前面（升序）
SELECT * FROM students ORDER BY email;

-- NULL 值排在最后
SELECT * FROM students ORDER BY email IS NULL, email;
```

---

## 四、LIMIT 分页

### 4.1 限制返回行数

```sql
-- 返回前5条记录
SELECT * FROM students LIMIT 5;

-- 返回前10条记录
SELECT * FROM students LIMIT 10;
```

### 4.2 分页查询

```sql
-- LIMIT offset, count
-- offset：偏移量（从0开始）
-- count：返回的记录数

-- 第1页（每页10条）
SELECT * FROM students LIMIT 0, 10;

-- 第2页（每页10条）
SELECT * FROM students LIMIT 10, 10;

-- 第3页（每页10条）
SELECT * FROM students LIMIT 20, 10;

-- 通用公式：LIMIT (page-1)*pageSize, pageSize
```

### 4.3 LIMIT 和 OFFSET

```sql
-- MySQL 8.0+ 支持 OFFSET 关键字
SELECT * FROM students LIMIT 10 OFFSET 0;  -- 第1页
SELECT * FROM students LIMIT 10 OFFSET 10; -- 第2页
SELECT * FROM students LIMIT 10 OFFSET 20; -- 第3页
```

### 4.4 分页优化

```sql
-- ❌ 深分页性能差
SELECT * FROM students LIMIT 100000, 10;

-- ✅ 使用主键优化
SELECT * FROM students WHERE id > 100000 LIMIT 10;

-- ✅ 使用子查询优化
SELECT * FROM students 
WHERE id >= (SELECT id FROM students LIMIT 100000, 1)
LIMIT 10;
```

---

## 五、聚合函数

### 5.1 COUNT 计数

```sql
-- 统计总记录数
SELECT COUNT(*) FROM students;

-- 统计非空值数量
SELECT COUNT(email) FROM students;

-- 统计不重复值数量
SELECT COUNT(DISTINCT age) FROM students;

-- 统计满足条件的记录数
SELECT COUNT(*) FROM students WHERE age >= 18;
```

### 5.2 SUM 求和

```sql
-- 求年龄总和
SELECT SUM(age) FROM students;

-- 求满足条件的年龄总和
SELECT SUM(age) FROM students WHERE gender = '男';

-- SUM 忽略 NULL 值
SELECT SUM(score) FROM scores;
```

### 5.3 AVG 平均值

```sql
-- 求平均年龄
SELECT AVG(age) FROM students;

-- 求平均年龄（保留2位小数）
SELECT ROUND(AVG(age), 2) FROM students;

-- 求满足条件的平均值
SELECT AVG(age) FROM students WHERE gender = '女';
```

### 5.4 MAX 最大值

```sql
-- 求最大年龄
SELECT MAX(age) FROM students;

-- 求最高分数
SELECT MAX(score) FROM scores;

-- 求最晚的日期
SELECT MAX(create_time) FROM students;
```

### 5.5 MIN 最小值

```sql
-- 求最小年龄
SELECT MIN(age) FROM students;

-- 求最低分数
SELECT MIN(score) FROM scores;

-- 求最早的日期
SELECT MIN(create_time) FROM students;
```

### 5.6 组合使用

```sql
-- 同时使用多个聚合函数
SELECT 
    COUNT(*) AS total,
    AVG(age) AS avg_age,
    MAX(age) AS max_age,
    MIN(age) AS min_age,
    SUM(age) AS sum_age
FROM students;
```

---

## 六、GROUP BY 分组

### 6.1 基本分组

```sql
-- 按性别分组统计人数
SELECT gender, COUNT(*) AS count
FROM students
GROUP BY gender;

-- 按年龄分组统计人数
SELECT age, COUNT(*) AS count
FROM students
GROUP BY age;
```

### 6.2 多列分组

```sql
-- 按性别和年龄分组
SELECT gender, age, COUNT(*) AS count
FROM students
GROUP BY gender, age;

-- 按班级和性别分组
SELECT class_id, gender, COUNT(*) AS count
FROM students
GROUP BY class_id, gender;
```

### 6.3 分组聚合

```sql
-- 按班级统计平均年龄
SELECT class_id, AVG(age) AS avg_age
FROM students
GROUP BY class_id;

-- 按性别统计最大年龄和最小年龄
SELECT 
    gender,
    MAX(age) AS max_age,
    MIN(age) AS min_age,
    AVG(age) AS avg_age
FROM students
GROUP BY gender;
```

### 6.4 分组排序

```sql
-- 按班级分组，按人数降序排序
SELECT class_id, COUNT(*) AS count
FROM students
GROUP BY class_id
ORDER BY count DESC;

-- 按年龄分组，按年龄升序排序
SELECT age, COUNT(*) AS count
FROM students
GROUP BY age
ORDER BY age;
```

### 6.5 WITH ROLLUP

```sql
-- 在分组结果后添加汇总行
SELECT gender, COUNT(*) AS count
FROM students
GROUP BY gender WITH ROLLUP;

-- 多列分组汇总
SELECT class_id, gender, COUNT(*) AS count
FROM students
GROUP BY class_id, gender WITH ROLLUP;
```

---

## 七、HAVING 分组过滤

### 7.1 HAVING 基础

```sql
-- 查询人数大于5的班级
SELECT class_id, COUNT(*) AS count
FROM students
GROUP BY class_id
HAVING COUNT(*) > 5;

-- 查询平均年龄大于20的班级
SELECT class_id, AVG(age) AS avg_age
FROM students
GROUP BY class_id
HAVING AVG(age) > 20;
```

### 7.2 WHERE vs HAVING

```sql
-- WHERE：分组前过滤
-- HAVING：分组后过滤

-- ✅ 正确：先过滤再分组
SELECT class_id, COUNT(*) AS count
FROM students
WHERE age >= 18
GROUP BY class_id
HAVING COUNT(*) > 5;

-- ❌ 错误：WHERE 不能使用聚合函数
SELECT class_id, COUNT(*) AS count
FROM students
WHERE COUNT(*) > 5  -- 错误！
GROUP BY class_id;

-- ✅ 正确：使用 HAVING
SELECT class_id, COUNT(*) AS count
FROM students
GROUP BY class_id
HAVING COUNT(*) > 5;
```

### 7.3 HAVING 多条件

```sql
-- 多个 HAVING 条件
SELECT class_id, AVG(age) AS avg_age, COUNT(*) AS count
FROM students
GROUP BY class_id
HAVING AVG(age) > 20 AND COUNT(*) > 10;

-- 使用 OR
SELECT class_id, AVG(age) AS avg_age
FROM students
GROUP BY class_id
HAVING AVG(age) > 25 OR AVG(age) < 18;
```

---

## 八、查询执行顺序

### 8.1 SQL 执行顺序

```sql
SELECT column_list          -- 5. 选择列
FROM table_name             -- 1. 确定表
WHERE condition             -- 2. 过滤行
GROUP BY column_list        -- 3. 分组
HAVING condition            -- 4. 过滤分组
ORDER BY column_list        -- 6. 排序
LIMIT offset, count         -- 7. 限制结果
```

### 8.2 完整示例

```sql
-- 查询年龄大于18岁的学生，按班级分组，
-- 统计每个班级的人数和平均年龄，
-- 只显示人数大于5的班级，
-- 按人数降序排序，
-- 只显示前3条记录

SELECT 
    class_id,
    COUNT(*) AS student_count,
    ROUND(AVG(age), 2) AS avg_age
FROM students
WHERE age > 18
GROUP BY class_id
HAVING COUNT(*) > 5
ORDER BY student_count DESC
LIMIT 3;
```

---

## 九、实战练习

### 练习1：基础查询

```sql
-- 1. 查询所有学生的姓名和年龄
SELECT name, age FROM students;

-- 2. 查询年龄大于20岁的学生
SELECT * FROM students WHERE age > 20;

-- 3. 查询姓"张"的学生
SELECT * FROM students WHERE name LIKE '张%';

-- 4. 查询年龄在18到25岁之间的学生
SELECT * FROM students WHERE age BETWEEN 18 AND 25;

-- 5. 查询邮箱不为空的学生
SELECT * FROM students WHERE email IS NOT NULL;
```

### 练习2：排序和分页

```sql
-- 1. 按年龄降序查询学生
SELECT * FROM students ORDER BY age DESC;

-- 2. 查询年龄最大的5个学生
SELECT * FROM students ORDER BY age DESC LIMIT 5;

-- 3. 查询第2页的学生（每页10条）
SELECT * FROM students LIMIT 10, 10;

-- 4. 按性别和年龄排序
SELECT * FROM students ORDER BY gender, age DESC;
```

### 练习3：聚合统计

```sql
-- 1. 统计学生总数
SELECT COUNT(*) AS total FROM students;

-- 2. 统计男生和女生的人数
SELECT gender, COUNT(*) AS count
FROM students
GROUP BY gender;

-- 3. 计算平均年龄
SELECT AVG(age) AS avg_age FROM students;

-- 4. 查询最大年龄和最小年龄
SELECT MAX(age) AS max_age, MIN(age) AS min_age FROM students;

-- 5. 按班级统计人数和平均年龄
SELECT 
    class_id,
    COUNT(*) AS count,
    ROUND(AVG(age), 2) AS avg_age
FROM students
GROUP BY class_id;
```

### 练习4：综合查询

```sql
-- 1. 查询每个班级中年龄大于18岁的学生人数
SELECT class_id, COUNT(*) AS count
FROM students
WHERE age > 18
GROUP BY class_id;

-- 2. 查询人数大于10的班级
SELECT class_id, COUNT(*) AS count
FROM students
GROUP BY class_id
HAVING COUNT(*) > 10;

-- 3. 查询平均年龄最高的3个班级
SELECT class_id, AVG(age) AS avg_age
FROM students
GROUP BY class_id
ORDER BY avg_age DESC
LIMIT 3;

-- 4. 查询每个性别中年龄最大的学生
SELECT gender, MAX(age) AS max_age
FROM students
GROUP BY gender;
```

---

## 十、注意事项

### 10.1 性能优化

```sql
-- ✅ 推荐：只查询需要的列
SELECT id, name, age FROM students;

-- ❌ 不推荐：查询所有列
SELECT * FROM students;

-- ✅ 推荐：使用 LIMIT 限制结果
SELECT * FROM students LIMIT 100;

-- ✅ 推荐：在 WHERE 条件中使用索引列
SELECT * FROM students WHERE id = 1;

-- ❌ 不推荐：在索引列上使用函数
SELECT * FROM students WHERE YEAR(create_time) = 2024;
```

### 10.2 常见错误

```sql
-- ❌ 错误：SELECT 列表中的非聚合列必须出现在 GROUP BY 中
SELECT class_id, name, COUNT(*)
FROM students
GROUP BY class_id;

-- ✅ 正确
SELECT class_id, COUNT(*)
FROM students
GROUP BY class_id;

-- ❌ 错误：WHERE 中不能使用聚合函数
SELECT class_id, COUNT(*) AS count
FROM students
WHERE COUNT(*) > 5
GROUP BY class_id;

-- ✅ 正确：使用 HAVING
SELECT class_id, COUNT(*) AS count
FROM students
GROUP BY class_id
HAVING COUNT(*) > 5;
```

---

## 十一、总结

本节学习了：

✅ SELECT 基础查询和列别名  
✅ WHERE 条件过滤（比较、逻辑、范围、模糊）  
✅ ORDER BY 排序  
✅ LIMIT 分页  
✅ 聚合函数（COUNT、SUM、AVG、MAX、MIN）  
✅ GROUP BY 分组  
✅ HAVING 分组过滤  
✅ SQL 执行顺序  

**下一节**：学习多表查询。
