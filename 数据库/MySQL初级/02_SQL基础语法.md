# SQL 基础语法

## 一、SQL 语言概述

### 1.1 什么是 SQL

SQL（Structured Query Language）结构化查询语言，是用于管理关系型数据库的标准语言。

**特点**：
- 简单易学
- 功能强大
- 标准统一
- 非过程化语言

### 1.2 SQL 语言分类

**DDL（Data Definition Language）数据定义语言**：
- CREATE：创建数据库对象
- ALTER：修改数据库对象
- DROP：删除数据库对象
- TRUNCATE：清空表数据

**DML（Data Manipulation Language）数据操作语言**：
- INSERT：插入数据
- UPDATE：更新数据
- DELETE：删除数据

**DQL（Data Query Language）数据查询语言**：
- SELECT：查询数据

**DCL（Data Control Language）数据控制语言**：
- GRANT：授予权限
- REVOKE：撤销权限

**TCL（Transaction Control Language）事务控制语言**：
- COMMIT：提交事务
- ROLLBACK：回滚事务
- SAVEPOINT：设置保存点

---

## 二、数据库操作

### 2.1 创建数据库

```sql
-- 基本语法
CREATE DATABASE database_name;

-- 指定字符集
CREATE DATABASE mydb 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 判断不存在再创建
CREATE DATABASE IF NOT EXISTS mydb;

-- 示例
CREATE DATABASE school 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;
```

### 2.2 查看数据库

```sql
-- 查看所有数据库
SHOW DATABASES;

-- 查看数据库创建语句
SHOW CREATE DATABASE mydb;

-- 查看当前使用的数据库
SELECT DATABASE();
```

### 2.3 选择数据库

```sql
-- 使用数据库
USE mydb;
```

### 2.4 修改数据库

```sql
-- 修改字符集
ALTER DATABASE mydb 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;
```

### 2.5 删除数据库

```sql
-- 删除数据库
DROP DATABASE mydb;

-- 判断存在再删除
DROP DATABASE IF EXISTS mydb;
```

---

## 三、数据表操作

### 3.1 创建表

```sql
-- 基本语法
CREATE TABLE table_name (
    column1 datatype constraints,
    column2 datatype constraints,
    ...
);

-- 示例：创建学生表
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    age INT,
    gender ENUM('男', '女'),
    email VARCHAR(100),
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 示例：创建课程表
CREATE TABLE courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    teacher VARCHAR(50),
    credit DECIMAL(3,1),
    description TEXT
);
```

### 3.2 查看表

```sql
-- 查看所有表
SHOW TABLES;

-- 查看表结构
DESC students;
-- 或
DESCRIBE students;
-- 或
SHOW COLUMNS FROM students;

-- 查看建表语句
SHOW CREATE TABLE students;

-- 查看表状态
SHOW TABLE STATUS LIKE 'students';
```

### 3.3 修改表

```sql
-- 添加列
ALTER TABLE students ADD COLUMN phone VARCHAR(20);

-- 添加列（指定位置）
ALTER TABLE students ADD COLUMN address VARCHAR(200) AFTER email;

-- 修改列类型
ALTER TABLE students MODIFY COLUMN age TINYINT;

-- 修改列名和类型
ALTER TABLE students CHANGE COLUMN phone mobile VARCHAR(20);

-- 删除列
ALTER TABLE students DROP COLUMN address;

-- 修改表名
ALTER TABLE students RENAME TO stu;
-- 或
RENAME TABLE stu TO students;

-- 修改表字符集
ALTER TABLE students CHARACTER SET utf8mb4;
```

### 3.4 删除表

```sql
-- 删除表
DROP TABLE students;

-- 判断存在再删除
DROP TABLE IF EXISTS students;

-- 清空表数据（保留表结构）
TRUNCATE TABLE students;
```

### 3.5 复制表

```sql
-- 复制表结构和数据
CREATE TABLE students_copy AS SELECT * FROM students;

-- 只复制表结构
CREATE TABLE students_copy LIKE students;

-- 复制部分数据
CREATE TABLE students_copy AS 
SELECT * FROM students WHERE age > 18;
```

---

## 四、数据类型

### 4.1 数值类型

**整数类型**：

| 类型 | 字节 | 范围（有符号） | 范围（无符号） |
|------|------|----------------|----------------|
| TINYINT | 1 | -128 ~ 127 | 0 ~ 255 |
| SMALLINT | 2 | -32768 ~ 32767 | 0 ~ 65535 |
| MEDIUMINT | 3 | -8388608 ~ 8388607 | 0 ~ 16777215 |
| INT | 4 | -2147483648 ~ 2147483647 | 0 ~ 4294967295 |
| BIGINT | 8 | -2^63 ~ 2^63-1 | 0 ~ 2^64-1 |

```sql
-- 示例
CREATE TABLE numbers (
    tiny_num TINYINT,
    small_num SMALLINT,
    medium_num MEDIUMINT,
    int_num INT,
    big_num BIGINT,
    unsigned_num INT UNSIGNED
);
```

**浮点类型**：

| 类型 | 字节 | 说明 |
|------|------|------|
| FLOAT | 4 | 单精度浮点数 |
| DOUBLE | 8 | 双精度浮点数 |
| DECIMAL(M,D) | 变长 | 精确小数 |

```sql
-- 示例
CREATE TABLE decimals (
    price DECIMAL(10,2),      -- 总共10位，小数2位
    weight FLOAT,
    distance DOUBLE
);
```

### 4.2 字符串类型

| 类型 | 最大长度 | 说明 |
|------|----------|------|
| CHAR(M) | 255 | 定长字符串 |
| VARCHAR(M) | 65535 | 变长字符串 |
| TINYTEXT | 255 | 短文本 |
| TEXT | 65535 | 文本 |
| MEDIUMTEXT | 16777215 | 中等文本 |
| LONGTEXT | 4294967295 | 长文本 |

```sql
-- 示例
CREATE TABLE strings (
    code CHAR(10),            -- 定长，如：身份证号
    name VARCHAR(50),         -- 变长，如：姓名
    description TEXT,         -- 长文本
    content LONGTEXT          -- 超长文本
);
```

### 4.3 日期时间类型

| 类型 | 格式 | 范围 |
|------|------|------|
| DATE | YYYY-MM-DD | 1000-01-01 ~ 9999-12-31 |
| TIME | HH:MM:SS | -838:59:59 ~ 838:59:59 |
| DATETIME | YYYY-MM-DD HH:MM:SS | 1000-01-01 00:00:00 ~ 9999-12-31 23:59:59 |
| TIMESTAMP | YYYY-MM-DD HH:MM:SS | 1970-01-01 00:00:01 ~ 2038-01-19 03:14:07 |
| YEAR | YYYY | 1901 ~ 2155 |

```sql
-- 示例
CREATE TABLE dates (
    birth_date DATE,
    work_time TIME,
    create_time DATETIME,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    year YEAR
);
```

### 4.4 其他类型

**枚举类型**：
```sql
CREATE TABLE users (
    id INT PRIMARY KEY,
    gender ENUM('男', '女', '未知') DEFAULT '未知',
    status ENUM('active', 'inactive', 'banned')
);
```

**集合类型**：
```sql
CREATE TABLE permissions (
    id INT PRIMARY KEY,
    roles SET('admin', 'editor', 'viewer', 'guest')
);
```

**二进制类型**：
```sql
CREATE TABLE files (
    id INT PRIMARY KEY,
    file_data BLOB,           -- 二进制数据
    large_file LONGBLOB       -- 大型二进制数据
);
```

---

## 五、约束条件

### 5.1 主键约束（PRIMARY KEY）

```sql
-- 方式1：创建表时指定
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

-- 方式2：自增主键
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50)
);

-- 方式3：表级约束
CREATE TABLE students (
    id INT,
    name VARCHAR(50),
    PRIMARY KEY (id)
);

-- 方式4：复合主键
CREATE TABLE scores (
    student_id INT,
    course_id INT,
    score DECIMAL(5,2),
    PRIMARY KEY (student_id, course_id)
);

-- 添加主键
ALTER TABLE students ADD PRIMARY KEY (id);

-- 删除主键
ALTER TABLE students DROP PRIMARY KEY;
```

### 5.2 非空约束（NOT NULL）

```sql
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL
);

-- 添加非空约束
ALTER TABLE students MODIFY COLUMN name VARCHAR(50) NOT NULL;

-- 删除非空约束
ALTER TABLE students MODIFY COLUMN name VARCHAR(50);
```

### 5.3 唯一约束（UNIQUE）

```sql
-- 列级约束
CREATE TABLE students (
    id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20) UNIQUE
);

-- 表级约束
CREATE TABLE students (
    id INT PRIMARY KEY,
    email VARCHAR(100),
    phone VARCHAR(20),
    UNIQUE (email),
    UNIQUE (phone)
);

-- 复合唯一约束
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    id_card VARCHAR(18),
    UNIQUE (name, id_card)
);

-- 添加唯一约束
ALTER TABLE students ADD UNIQUE (email);

-- 删除唯一约束
ALTER TABLE students DROP INDEX email;
```

### 5.4 默认值约束（DEFAULT）

```sql
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    age INT DEFAULT 18,
    gender ENUM('男', '女') DEFAULT '男',
    status VARCHAR(20) DEFAULT 'active',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 添加默认值
ALTER TABLE students ALTER COLUMN age SET DEFAULT 18;

-- 删除默认值
ALTER TABLE students ALTER COLUMN age DROP DEFAULT;
```

### 5.5 检查约束（CHECK）

```sql
-- MySQL 8.0+ 支持
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    age INT CHECK (age >= 0 AND age <= 150),
    email VARCHAR(100) CHECK (email LIKE '%@%'),
    score DECIMAL(5,2) CHECK (score >= 0 AND score <= 100)
);

-- 添加检查约束
ALTER TABLE students ADD CONSTRAINT chk_age CHECK (age >= 0 AND age <= 150);

-- 删除检查约束
ALTER TABLE students DROP CHECK chk_age;
```

### 5.6 外键约束（FOREIGN KEY）

```sql
-- 创建父表
CREATE TABLE classes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL
);

-- 创建子表（带外键）
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    class_id INT,
    FOREIGN KEY (class_id) REFERENCES classes(id)
);

-- 外键约束选项
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    class_id INT,
    FOREIGN KEY (class_id) REFERENCES classes(id)
        ON DELETE CASCADE      -- 级联删除
        ON UPDATE CASCADE      -- 级联更新
);

-- 外键约束选项说明
-- CASCADE：级联操作
-- SET NULL：设置为 NULL
-- NO ACTION：不做任何操作（默认）
-- RESTRICT：限制（不允许删除/更新）

-- 添加外键
ALTER TABLE students 
ADD CONSTRAINT fk_class 
FOREIGN KEY (class_id) REFERENCES classes(id);

-- 删除外键
ALTER TABLE students DROP FOREIGN KEY fk_class;
```

---

## 六、字符集和校对规则

### 6.1 查看字符集

```sql
-- 查看支持的字符集
SHOW CHARACTER SET;

-- 查看当前字符集
SHOW VARIABLES LIKE 'character%';

-- 查看校对规则
SHOW COLLATION;
```

### 6.2 设置字符集

```sql
-- 数据库级别
CREATE DATABASE mydb 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 表级别
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(50)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 列级别
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
);

-- 修改字符集
ALTER DATABASE mydb CHARACTER SET utf8mb4;
ALTER TABLE students CHARACTER SET utf8mb4;
ALTER TABLE students MODIFY COLUMN name VARCHAR(50) CHARACTER SET utf8mb4;
```

### 6.3 常用字符集

- **utf8mb4**：推荐使用，支持所有 Unicode 字符（包括 Emoji）
- **utf8**：只支持 3 字节 UTF-8 字符
- **gbk**：中文字符集
- **latin1**：西欧字符集（MySQL 默认）

---

## 七、实战练习

### 练习1：创建学生管理系统数据库

```sql
-- 1. 创建数据库
CREATE DATABASE school CHARACTER SET utf8mb4;
USE school;

-- 2. 创建班级表
CREATE TABLE classes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    teacher VARCHAR(50),
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. 创建学生表
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    gender ENUM('男', '女') DEFAULT '男',
    age INT CHECK (age >= 6 AND age <= 100),
    class_id INT,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id)
);

-- 4. 创建课程表
CREATE TABLE courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    credit DECIMAL(3,1),
    teacher VARCHAR(50)
);

-- 5. 创建成绩表
CREATE TABLE scores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    score DECIMAL(5,2) CHECK (score >= 0 AND score <= 100),
    exam_date DATE,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

### 练习2：修改表结构

```sql
-- 1. 给学生表添加地址字段
ALTER TABLE students ADD COLUMN address VARCHAR(200);

-- 2. 修改年龄字段类型
ALTER TABLE students MODIFY COLUMN age TINYINT;

-- 3. 删除电话字段
ALTER TABLE students DROP COLUMN phone;

-- 4. 添加唯一约束
ALTER TABLE students ADD UNIQUE (email);
```

---

## 八、总结

本节学习了：

✅ SQL 语言分类  
✅ 数据库的创建、查看、修改、删除  
✅ 数据表的创建、查看、修改、删除  
✅ 数据类型详解  
✅ 约束条件使用  
✅ 字符集和校对规则  

**下一节**：学习数据操作（DML）。
