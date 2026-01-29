# 数据操作（DML）

## 一、INSERT 插入数据

### 1.1 基本语法

```sql
-- 插入完整数据
INSERT INTO table_name (column1, column2, ...) 
VALUES (value1, value2, ...);

-- 插入部分数据
INSERT INTO table_name (column1, column3) 
VALUES (value1, value3);

-- 不指定列名（按表结构顺序）
INSERT INTO table_name 
VALUES (value1, value2, value3, ...);
```

### 1.2 插入单条数据

```sql
-- 示例：插入学生数据
INSERT INTO students (name, gender, age, email) 
VALUES ('张三', '男', 20, 'zhangsan@example.com');

-- 自增主键可以不指定
INSERT INTO students (name, gender, age) 
VALUES ('李四', '女', 19);

-- 使用 DEFAULT 关键字
INSERT INTO students (name, gender, age, status) 
VALUES ('王五', '男', 21, DEFAULT);
```

### 1.3 插入多条数据

```sql
-- 批量插入（推荐）
INSERT INTO students (name, gender, age, email) 
VALUES 
    ('赵六', '男', 20, 'zhaoliu@example.com'),
    ('孙七', '女', 19, 'sunqi@example.com'),
    ('周八', '男', 21, 'zhouba@example.com');
```

### 1.4 插入查询结果

```sql
-- 从其他表插入数据
INSERT INTO students_backup (name, gender, age)
SELECT name, gender, age FROM students WHERE age > 20;

-- 创建表并插入数据
CREATE TABLE students_copy AS 
SELECT * FROM students WHERE age > 18;
```

### 1.5 INSERT IGNORE

```sql
-- 忽略重复键错误
INSERT IGNORE INTO students (id, name, email) 
VALUES (1, '张三', 'zhangsan@example.com');

-- 如果主键或唯一键冲突，则忽略该行
```

### 1.6 ON DUPLICATE KEY UPDATE

```sql
-- 如果存在则更新
INSERT INTO students (id, name, age) 
VALUES (1, '张三', 21)
ON DUPLICATE KEY UPDATE age = 21;

-- 使用 VALUES() 函数
INSERT INTO students (id, name, age) 
VALUES (1, '张三', 21)
ON DUPLICATE KEY UPDATE 
    name = VALUES(name),
    age = VALUES(age);
```

### 1.7 REPLACE INTO

```sql
-- 替换数据（先删除后插入）
REPLACE INTO students (id, name, age) 
VALUES (1, '张三', 21);

-- 如果主键或唯一键存在，先删除旧记录，再插入新记录
```

---

## 二、UPDATE 更新数据

### 2.1 基本语法

```sql
UPDATE table_name 
SET column1 = value1, column2 = value2, ...
WHERE condition;
```

### 2.2 更新单列

```sql
-- 更新单个字段
UPDATE students 
SET age = 21 
WHERE id = 1;

-- 更新所有记录（危险操作！）
UPDATE students 
SET status = 'active';
```

### 2.3 更新多列

```sql
-- 更新多个字段
UPDATE students 
SET age = 22, email = 'new@example.com' 
WHERE id = 1;

-- 使用表达式
UPDATE students 
SET age = age + 1 
WHERE id = 1;
```

### 2.4 条件更新

```sql
-- 单条件
UPDATE students 
SET status = 'inactive' 
WHERE age < 18;

-- 多条件
UPDATE students 
SET status = 'vip' 
WHERE age >= 20 AND gender = '男';

-- IN 条件
UPDATE students 
SET status = 'active' 
WHERE id IN (1, 2, 3, 4, 5);

-- BETWEEN 条件
UPDATE students 
SET level = 'senior' 
WHERE age BETWEEN 20 AND 25;
```

### 2.5 使用子查询更新

```sql
-- 根据子查询结果更新
UPDATE students 
SET class_id = (
    SELECT id FROM classes WHERE name = '一班'
)
WHERE name = '张三';

-- 使用 JOIN 更新
UPDATE students s
JOIN classes c ON s.class_id = c.id
SET s.class_name = c.name;
```

### 2.6 限制更新数量

```sql
-- 限制更新行数
UPDATE students 
SET status = 'active' 
WHERE age > 18 
LIMIT 10;
```

---

## 三、DELETE 删除数据

### 3.1 基本语法

```sql
DELETE FROM table_name 
WHERE condition;
```

### 3.2 删除指定数据

```sql
-- 删除单条记录
DELETE FROM students 
WHERE id = 1;

-- 删除多条记录
DELETE FROM students 
WHERE age < 18;

-- 使用 IN
DELETE FROM students 
WHERE id IN (1, 2, 3);

-- 使用 BETWEEN
DELETE FROM students 
WHERE age BETWEEN 10 AND 15;
```

### 3.3 删除所有数据

```sql
-- 删除所有记录（保留表结构）
DELETE FROM students;

-- 注意：这会逐行删除，速度较慢
```

### 3.4 使用子查询删除

```sql
-- 根据子查询结果删除
DELETE FROM students 
WHERE class_id IN (
    SELECT id FROM classes WHERE name = '已毕业班级'
);
```

### 3.5 限制删除数量

```sql
-- 限制删除行数
DELETE FROM students 
WHERE status = 'inactive' 
LIMIT 10;
```

### 3.6 使用 JOIN 删除

```sql
-- 删除关联数据
DELETE s 
FROM students s
JOIN classes c ON s.class_id = c.id
WHERE c.name = '已毕业班级';
```

---

## 四、TRUNCATE 清空表

### 4.1 基本语法

```sql
TRUNCATE TABLE table_name;
```

### 4.2 TRUNCATE vs DELETE

| 特性 | TRUNCATE | DELETE |
|------|----------|--------|
| 速度 | 快 | 慢 |
| 自增计数器 | 重置 | 不重置 |
| WHERE 条件 | 不支持 | 支持 |
| 事务回滚 | 不能回滚 | 可以回滚 |
| 触发器 | 不触发 | 触发 |
| 日志记录 | 少 | 多 |

```sql
-- 清空表（快速）
TRUNCATE TABLE students;

-- 等价于（但更快）
DELETE FROM students;
```

---

## 五、事务基础

### 5.1 什么是事务

事务是一组 SQL 操作的集合，要么全部成功，要么全部失败。

**ACID 特性**：
- **原子性（Atomicity）**：事务是不可分割的最小单位
- **一致性（Consistency）**：事务前后数据保持一致
- **隔离性（Isolation）**：事务之间相互隔离
- **持久性（Durability）**：事务提交后永久保存

### 5.2 事务控制

```sql
-- 开始事务
START TRANSACTION;
-- 或
BEGIN;

-- 提交事务
COMMIT;

-- 回滚事务
ROLLBACK;

-- 设置保存点
SAVEPOINT savepoint_name;

-- 回滚到保存点
ROLLBACK TO savepoint_name;
```

### 5.3 事务示例

```sql
-- 转账示例
START TRANSACTION;

-- 扣除 A 账户金额
UPDATE accounts SET balance = balance - 100 WHERE id = 1;

-- 增加 B 账户金额
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

-- 检查是否成功
-- 如果成功
COMMIT;
-- 如果失败
-- ROLLBACK;
```

### 5.4 自动提交

```sql
-- 查看自动提交状态
SHOW VARIABLES LIKE 'autocommit';

-- 关闭自动提交
SET autocommit = 0;

-- 开启自动提交
SET autocommit = 1;
```

---

## 六、批量操作

### 6.1 批量插入

```sql
-- 方式1：多行插入（推荐）
INSERT INTO students (name, age) VALUES
    ('学生1', 20),
    ('学生2', 21),
    ('学生3', 22),
    ('学生4', 23),
    ('学生5', 24);

-- 方式2：使用事务
START TRANSACTION;
INSERT INTO students (name, age) VALUES ('学生1', 20);
INSERT INTO students (name, age) VALUES ('学生2', 21);
INSERT INTO students (name, age) VALUES ('学生3', 22);
COMMIT;

-- 方式3：LOAD DATA（最快）
LOAD DATA INFILE '/path/to/data.csv'
INTO TABLE students
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
(name, age, email);
```

### 6.2 批量更新

```sql
-- 使用 CASE WHEN
UPDATE students
SET age = CASE id
    WHEN 1 THEN 21
    WHEN 2 THEN 22
    WHEN 3 THEN 23
    ELSE age
END
WHERE id IN (1, 2, 3);

-- 使用临时表
CREATE TEMPORARY TABLE temp_updates (
    id INT,
    new_age INT
);

INSERT INTO temp_updates VALUES (1, 21), (2, 22), (3, 23);

UPDATE students s
JOIN temp_updates t ON s.id = t.id
SET s.age = t.new_age;

DROP TEMPORARY TABLE temp_updates;
```

### 6.3 批量删除

```sql
-- 使用 IN
DELETE FROM students WHERE id IN (1, 2, 3, 4, 5);

-- 使用子查询
DELETE FROM students 
WHERE id IN (
    SELECT id FROM (
        SELECT id FROM students WHERE age < 18
    ) AS temp
);
```

---

## 七、实战练习

### 练习1：学生数据管理

```sql
-- 1. 插入学生数据
INSERT INTO students (name, gender, age, email) VALUES
    ('张三', '男', 20, 'zhangsan@example.com'),
    ('李四', '女', 19, 'lisi@example.com'),
    ('王五', '男', 21, 'wangwu@example.com'),
    ('赵六', '女', 20, 'zhaoliu@example.com'),
    ('孙七', '男', 22, 'sunqi@example.com');

-- 2. 更新学生年龄
UPDATE students SET age = age + 1 WHERE id = 1;

-- 3. 更新学生邮箱
UPDATE students SET email = 'newemail@example.com' WHERE name = '张三';

-- 4. 删除年龄小于 18 的学生
DELETE FROM students WHERE age < 18;

-- 5. 清空测试数据
TRUNCATE TABLE students;
```

### 练习2：转账事务

```sql
-- 创建账户表
CREATE TABLE accounts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    balance DECIMAL(10,2)
);

-- 插入测试数据
INSERT INTO accounts (name, balance) VALUES
    ('张三', 1000.00),
    ('李四', 500.00);

-- 转账操作（张三转给李四 100 元）
START TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

-- 检查余额
SELECT * FROM accounts;

-- 提交事务
COMMIT;
```

### 练习3：批量操作

```sql
-- 1. 批量插入课程
INSERT INTO courses (name, credit, teacher) VALUES
    ('数学', 4.0, '王老师'),
    ('英语', 3.0, '李老师'),
    ('物理', 4.5, '张老师'),
    ('化学', 4.0, '赵老师'),
    ('生物', 3.5, '孙老师');

-- 2. 批量更新学分
UPDATE courses
SET credit = CASE name
    WHEN '数学' THEN 4.5
    WHEN '英语' THEN 3.5
    WHEN '物理' THEN 5.0
    ELSE credit
END
WHERE name IN ('数学', '英语', '物理');

-- 3. 批量删除
DELETE FROM courses WHERE credit < 3.0;
```

---

## 八、注意事项

### 8.1 安全建议

```sql
-- ❌ 危险：删除所有数据
DELETE FROM students;

-- ✅ 安全：使用 WHERE 条件
DELETE FROM students WHERE id = 1;

-- ❌ 危险：更新所有数据
UPDATE students SET age = 20;

-- ✅ 安全：使用 WHERE 条件
UPDATE students SET age = 20 WHERE id = 1;
```

### 8.2 性能建议

```sql
-- ✅ 推荐：批量插入
INSERT INTO students (name, age) VALUES
    ('学生1', 20),
    ('学生2', 21),
    ('学生3', 22);

-- ❌ 不推荐：逐条插入
INSERT INTO students (name, age) VALUES ('学生1', 20);
INSERT INTO students (name, age) VALUES ('学生2', 21);
INSERT INTO students (name, age) VALUES ('学生3', 22);

-- ✅ 推荐：使用 TRUNCATE 清空表
TRUNCATE TABLE students;

-- ❌ 不推荐：使用 DELETE 清空表
DELETE FROM students;
```

### 8.3 数据完整性

```sql
-- 使用事务保证数据一致性
START TRANSACTION;

-- 执行多个相关操作
INSERT INTO orders (user_id, total) VALUES (1, 100);
UPDATE users SET balance = balance - 100 WHERE id = 1;

-- 检查结果
-- 如果正确则提交
COMMIT;
-- 如果错误则回滚
-- ROLLBACK;
```

---

## 九、总结

本节学习了：

✅ INSERT 插入数据的多种方式  
✅ UPDATE 更新数据  
✅ DELETE 删除数据  
✅ TRUNCATE 清空表  
✅ 事务的基本概念和使用  
✅ 批量操作技巧  
✅ 数据操作的注意事项  

**下一节**：学习数据查询（DQL）。
