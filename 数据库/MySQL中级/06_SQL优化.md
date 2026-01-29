# 06 - SQL 优化

## 📚 本节目标

- 掌握慢查询日志的使用
- 理解 EXPLAIN 执行计划
- 学会索引优化技巧
- 掌握查询优化方法
- 了解表结构优化
- 掌握配置优化参数

---

## 1. 慢查询日志

### 1.1 开启慢查询日志

```sql
-- 查看慢查询配置
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

-- 开启慢查询日志
SET GLOBAL slow_query_log = ON;

-- 设置慢查询阈值（秒）
SET GLOBAL long_query_time = 2;

-- 设置日志文件路径
SET GLOBAL slow_query_log_file = '/var/log/mysql/slow.log';

-- 记录未使用索引的查询
SET GLOBAL log_queries_not_using_indexes = ON;
```

### 1.2 配置文件设置

```ini
# my.cnf 或 my.ini
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_queries_not_using_indexes = 1
```

### 1.3 分析慢查询日志

```bash
# 使用 mysqldumpslow 分析
mysqldumpslow -s t -t 10 /var/log/mysql/slow.log

# 参数说明：
# -s：排序方式（t=时间，c=次数，l=锁定时间）
# -t：显示前 N 条
# -g：正则匹配

# 示例
mysqldumpslow -s t -t 10 -g "SELECT" slow.log
```

---

## 2. EXPLAIN 执行计划

### 2.1 EXPLAIN 基础

```sql
-- 查看执行计划
EXPLAIN SELECT * FROM users WHERE id = 1;

-- 查看详细信息
EXPLAIN FORMAT=JSON SELECT * FROM users WHERE id = 1;
```

### 2.2 EXPLAIN 输出字段详解

| 字段 | 说明 |
|------|------|
| id | 查询序列号 |
| select_type | 查询类型 |
| table | 表名 |
| partitions | 匹配的分区 |
| type | 访问类型（重要） |
| possible_keys | 可能使用的索引 |
| key | 实际使用的索引 |
| key_len | 索引长度 |
| ref | 索引引用 |
| rows | 扫描行数（重要） |
| filtered | 过滤百分比 |
| Extra | 额外信息（重要） |

### 2.3 type 访问类型（性能从好到差）

```sql
-- system：表只有一行（系统表）
-- const：主键或唯一索引查询
EXPLAIN SELECT * FROM users WHERE id = 1;

-- eq_ref：唯一索引扫描
EXPLAIN SELECT * FROM orders o 
JOIN users u ON o.user_id = u.id;

-- ref：非唯一索引扫描
EXPLAIN SELECT * FROM users WHERE name = '张三';

-- range：索引范围扫描
EXPLAIN SELECT * FROM users WHERE id BETWEEN 1 AND 100;

-- index：全索引扫描
EXPLAIN SELECT id FROM users;

-- ALL：全表扫描（最差）
EXPLAIN SELECT * FROM users WHERE email LIKE '%@gmail.com';
```

**性能排序**：
```
system > const > eq_ref > ref > range > index > ALL
```

### 2.4 Extra 字段详解

```sql
-- Using index：覆盖索引，不需要回表
EXPLAIN SELECT id, name FROM users WHERE name = '张三';

-- Using where：使用 WHERE 过滤
EXPLAIN SELECT * FROM users WHERE age > 18;

-- Using temporary：使用临时表
EXPLAIN SELECT DISTINCT name FROM users;

-- Using filesort：文件排序（需要优化）
EXPLAIN SELECT * FROM users ORDER BY email;

-- Using index condition：索引条件下推
EXPLAIN SELECT * FROM users WHERE name LIKE '张%' AND age > 18;
```

### 2.5 实战示例

```sql
-- 创建测试表
CREATE TABLE test_users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50),
    email VARCHAR(100),
    age INT,
    city VARCHAR(50),
    created_at DATETIME,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_age (age)
);

-- 插入测试数据
INSERT INTO test_users (username, email, age, city, created_at)
SELECT 
    CONCAT('user', n),
    CONCAT('user', n, '@example.com'),
    18 + (n % 50),
    CASE (n % 5)
        WHEN 0 THEN '北京'
        WHEN 1 THEN '上海'
        WHEN 2 THEN '广州'
        WHEN 3 THEN '深圳'
        ELSE '杭州'
    END,
    DATE_ADD('2020-01-01', INTERVAL n DAY)
FROM (
    SELECT a.N + b.N * 10 + c.N * 100 + d.N * 1000 AS n
    FROM 
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) d
) numbers
WHERE n < 10000;

-- 分析不同查询
EXPLAIN SELECT * FROM test_users WHERE id = 100;
-- type: const, rows: 1

EXPLAIN SELECT * FROM test_users WHERE username = 'user100';
-- type: ref, rows: 1

EXPLAIN SELECT * FROM test_users WHERE age > 30;
-- type: range, rows: ~3500

EXPLAIN SELECT * FROM test_users WHERE city = '北京';
-- type: ALL, rows: 10000（没有索引）
```

---

## 3. 索引优化

### 3.1 索引失效场景

```sql
-- 1. 使用函数或表达式
-- ❌ 索引失效
EXPLAIN SELECT * FROM test_users WHERE YEAR(created_at) = 2023;
-- ✅ 使用索引
EXPLAIN SELECT * FROM test_users 
WHERE created_at BETWEEN '2023-01-01' AND '2023-12-31';

-- 2. 隐式类型转换
-- ❌ username 是 VARCHAR，传入数字会失效
EXPLAIN SELECT * FROM test_users WHERE username = 123;
-- ✅ 使用字符串
EXPLAIN SELECT * FROM test_users WHERE username = '123';

-- 3. 前导模糊查询
-- ❌ 索引失效
EXPLAIN SELECT * FROM test_users WHERE email LIKE '%@gmail.com';
-- ✅ 使用索引
EXPLAIN SELECT * FROM test_users WHERE email LIKE 'user%';

-- 4. OR 条件
-- ❌ 如果 OR 的字段没有索引，整个查询不走索引
EXPLAIN SELECT * FROM test_users WHERE username = 'user1' OR city = '北京';
-- ✅ 改用 UNION
EXPLAIN 
SELECT * FROM test_users WHERE username = 'user1'
UNION
SELECT * FROM test_users WHERE city = '北京';

-- 5. 不等于操作
-- ❌ 可能不走索引
EXPLAIN SELECT * FROM test_users WHERE age != 30;
-- ✅ 改用范围查询
EXPLAIN SELECT * FROM test_users WHERE age < 30 OR age > 30;

-- 6. IS NULL / IS NOT NULL
-- 可能不走索引（取决于数据分布）
EXPLAIN SELECT * FROM test_users WHERE email IS NULL;

-- 7. 联合索引不满足最左前缀
CREATE INDEX idx_multi ON test_users(username, age, city);
-- ❌ 不走索引
EXPLAIN SELECT * FROM test_users WHERE age = 25;
-- ✅ 走索引
EXPLAIN SELECT * FROM test_users WHERE username = 'user1';
EXPLAIN SELECT * FROM test_users WHERE username = 'user1' AND age = 25;
```

### 3.2 联合索引优化

```sql
-- 创建联合索引
CREATE INDEX idx_username_age_city ON test_users(username, age, city);

-- 最左前缀原则
-- ✅ 使用索引
EXPLAIN SELECT * FROM test_users WHERE username = 'user1';
EXPLAIN SELECT * FROM test_users WHERE username = 'user1' AND age = 25;
EXPLAIN SELECT * FROM test_users WHERE username = 'user1' AND age = 25 AND city = '北京';

-- ❌ 不使用索引（跳过了 username）
EXPLAIN SELECT * FROM test_users WHERE age = 25 AND city = '北京';

-- ⚠️ 部分使用索引（只用到 username）
EXPLAIN SELECT * FROM test_users WHERE username = 'user1' AND city = '北京';
```

### 3.3 覆盖索引

```sql
-- 覆盖索引：查询的字段都在索引中，不需要回表
CREATE INDEX idx_username_email ON test_users(username, email);

-- ✅ 覆盖索引（Extra: Using index）
EXPLAIN SELECT username, email FROM test_users WHERE username = 'user1';

-- ❌ 需要回表
EXPLAIN SELECT * FROM test_users WHERE username = 'user1';
```

### 3.4 索引下推（ICP）

```sql
-- MySQL 5.6+ 支持索引条件下推
CREATE INDEX idx_username_age ON test_users(username, age);

-- 索引下推优化
EXPLAIN SELECT * FROM test_users 
WHERE username LIKE 'user1%' AND age > 30;
-- Extra: Using index condition
```

---

## 4. 查询优化

### 4.1 SELECT 优化

```sql
-- ❌ 避免 SELECT *
SELECT * FROM test_users WHERE id = 1;

-- ✅ 只查询需要的字段
SELECT id, username, email FROM test_users WHERE id = 1;

-- ❌ 避免重复查询
SELECT COUNT(*) FROM test_users;
SELECT * FROM test_users LIMIT 10;

-- ✅ 一次查询
SELECT SQL_CALC_FOUND_ROWS * FROM test_users LIMIT 10;
SELECT FOUND_ROWS();  -- 获取总数
```

### 4.2 JOIN 优化

```sql
-- 创建订单表
CREATE TABLE orders_opt (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    amount DECIMAL(10,2),
    status VARCHAR(20),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);

-- ❌ 笛卡尔积
SELECT * FROM test_users, orders_opt;

-- ✅ 使用 JOIN
SELECT u.username, o.amount
FROM test_users u
INNER JOIN orders_opt o ON u.id = o.user_id;

-- ✅ 小表驱动大表
-- 如果 orders 表小，users 表大
SELECT u.username, o.amount
FROM orders_opt o
INNER JOIN test_users u ON o.user_id = u.id;

-- ✅ 使用索引字段 JOIN
-- 确保 JOIN 字段有索引
```

### 4.3 子查询优化

```sql
-- ❌ 子查询性能差
SELECT * FROM test_users
WHERE id IN (
    SELECT user_id FROM orders_opt WHERE amount > 1000
);

-- ✅ 改用 JOIN
SELECT DISTINCT u.*
FROM test_users u
INNER JOIN orders_opt o ON u.id = o.user_id
WHERE o.amount > 1000;

-- ✅ 使用 EXISTS（适合外表大，内表小）
SELECT * FROM test_users u
WHERE EXISTS (
    SELECT 1 FROM orders_opt o 
    WHERE o.user_id = u.id AND o.amount > 1000
);
```

### 4.4 分页优化

```sql
-- ❌ 深分页性能差
SELECT * FROM test_users ORDER BY id LIMIT 9000, 10;

-- ✅ 使用子查询优化
SELECT * FROM test_users
WHERE id >= (
    SELECT id FROM test_users ORDER BY id LIMIT 9000, 1
)
ORDER BY id LIMIT 10;

-- ✅ 使用延迟关联
SELECT u.* FROM test_users u
INNER JOIN (
    SELECT id FROM test_users ORDER BY id LIMIT 9000, 10
) t ON u.id = t.id;

-- ✅ 记录上次位置（最优）
SELECT * FROM test_users 
WHERE id > 9000 
ORDER BY id LIMIT 10;
```

### 4.5 COUNT 优化

```sql
-- ❌ COUNT(*) 全表扫描
SELECT COUNT(*) FROM test_users;

-- ✅ 使用索引
SELECT COUNT(id) FROM test_users;

-- ✅ 使用近似值
EXPLAIN SELECT * FROM test_users;
-- 查看 rows 字段

-- ✅ 维护计数表
CREATE TABLE user_count (
    count INT
);

-- 使用触发器维护
DELIMITER $$
CREATE TRIGGER update_count_after_insert
AFTER INSERT ON test_users
FOR EACH ROW
BEGIN
    UPDATE user_count SET count = count + 1;
END$$
DELIMITER ;
```

### 4.6 DISTINCT 优化

```sql
-- ❌ DISTINCT 性能差
SELECT DISTINCT city FROM test_users;

-- ✅ 使用 GROUP BY
SELECT city FROM test_users GROUP BY city;

-- ✅ 使用 EXISTS
SELECT city FROM test_users u1
WHERE NOT EXISTS (
    SELECT 1 FROM test_users u2
    WHERE u2.city = u1.city AND u2.id < u1.id
);
```

---

## 5. 表结构优化

### 5.1 字段类型选择

```sql
-- ✅ 使用合适的数据类型
CREATE TABLE optimized_table (
    -- ✅ 使用 INT 而不是 BIGINT（如果范围够用）
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    
    -- ✅ 使用 VARCHAR 而不是 TEXT（如果长度确定）
    username VARCHAR(50) NOT NULL,
    
    -- ✅ 使用 TINYINT 存储状态
    status TINYINT DEFAULT 0,
    
    -- ✅ 使用 DECIMAL 存储金额
    amount DECIMAL(10,2),
    
    -- ✅ 使用 TIMESTAMP 而不是 DATETIME（如果范围够用）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 5.2 字段属性优化

```sql
CREATE TABLE field_optimized (
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    -- ✅ 设置 NOT NULL
    username VARCHAR(50) NOT NULL,
    
    -- ✅ 设置默认值
    status TINYINT NOT NULL DEFAULT 0,
    
    -- ✅ 使用 UNSIGNED
    age INT UNSIGNED,
    
    -- ✅ 合理的字段长度
    mobile CHAR(11),  -- 手机号固定 11 位
    
    -- ✅ 使用 ENUM（选项固定且少）
    gender ENUM('M', 'F', 'U') DEFAULT 'U'
);
```

### 5.3 表拆分

```sql
-- 垂直拆分：按字段拆分
-- 主表（常用字段）
CREATE TABLE users_main (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50),
    email VARCHAR(100),
    created_at DATETIME
);

-- 扩展表（不常用字段）
CREATE TABLE users_ext (
    user_id INT PRIMARY KEY,
    address TEXT,
    description TEXT,
    FOREIGN KEY (user_id) REFERENCES users_main(id)
);

-- 水平拆分：按数据拆分
-- 按时间拆分
CREATE TABLE orders_2023 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    amount DECIMAL(10,2),
    created_at DATETIME
);

CREATE TABLE orders_2024 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    amount DECIMAL(10,2),
    created_at DATETIME
);
```

---

## 6. 配置优化

### 6.1 连接相关

```ini
[mysqld]
# 最大连接数
max_connections = 500

# 连接超时时间
wait_timeout = 28800
interactive_timeout = 28800

# 连接错误次数
max_connect_errors = 100
```

### 6.2 缓冲区优化

```ini
[mysqld]
# InnoDB 缓冲池大小（建议物理内存的 70-80%）
innodb_buffer_pool_size = 4G

# 查询缓存（MySQL 8.0 已移除）
query_cache_size = 0
query_cache_type = 0

# 排序缓冲区
sort_buffer_size = 2M

# JOIN 缓冲区
join_buffer_size = 2M

# 读缓冲区
read_buffer_size = 1M
read_rnd_buffer_size = 1M
```

### 6.3 日志优化

```ini
[mysqld]
# 二进制日志
log_bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7

# 慢查询日志
slow_query_log = 1
long_query_time = 2
log_queries_not_using_indexes = 1

# 错误日志
log_error = /var/log/mysql/error.log
```

### 6.4 InnoDB 优化

```ini
[mysqld]
# 日志文件大小
innodb_log_file_size = 256M

# 日志缓冲区
innodb_log_buffer_size = 16M

# 刷新策略（1=最安全，2=性能好）
innodb_flush_log_at_trx_commit = 2

# IO 线程
innodb_read_io_threads = 4
innodb_write_io_threads = 4

# 文件格式
innodb_file_format = Barracuda
innodb_file_per_table = 1
```

---

## 7. 性能监控

### 7.1 查看状态变量

```sql
-- 查看所有状态
SHOW STATUS;

-- 查看连接数
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Max_used_connections';

-- 查看查询统计
SHOW STATUS LIKE 'Questions';
SHOW STATUS LIKE 'Queries';

-- 查看慢查询
SHOW STATUS LIKE 'Slow_queries';

-- 查看表锁
SHOW STATUS LIKE 'Table_locks%';

-- 查看 InnoDB 状态
SHOW ENGINE INNODB STATUS;
```

### 7.2 查看进程列表

```sql
-- 查看当前进程
SHOW PROCESSLIST;

-- 查看完整 SQL
SHOW FULL PROCESSLIST;

-- 杀死慢查询
KILL QUERY 123;  -- 123 是进程 ID
```

### 7.3 性能分析工具

```sql
-- 开启 profiling
SET profiling = 1;

-- 执行查询
SELECT * FROM test_users WHERE username = 'user1';

-- 查看 profile
SHOW PROFILES;

-- 查看详细信息
SHOW PROFILE FOR QUERY 1;

-- 查看 CPU、IO 信息
SHOW PROFILE CPU, BLOCK IO FOR QUERY 1;
```

---

## 8. 实战案例

### 案例1：电商订单查询优化

```sql
-- 原始查询（慢）
SELECT 
    o.id,
    o.order_no,
    u.username,
    p.name AS product_name,
    o.amount
FROM orders o
LEFT JOIN users u ON o.user_id = u.id
LEFT JOIN products p ON o.product_id = p.id
WHERE o.status = 'completed'
  AND o.created_at >= '2024-01-01'
ORDER BY o.created_at DESC
LIMIT 20;

-- 优化步骤
-- 1. 添加索引
CREATE INDEX idx_status_created ON orders(status, created_at);

-- 2. 使用覆盖索引
CREATE INDEX idx_order_info ON orders(id, order_no, user_id, product_id, amount, status, created_at);

-- 3. 优化查询
SELECT 
    o.id,
    o.order_no,
    u.username,
    p.name AS product_name,
    o.amount
FROM (
    SELECT id, order_no, user_id, product_id, amount
    FROM orders
    WHERE status = 'completed'
      AND created_at >= '2024-01-01'
    ORDER BY created_at DESC
    LIMIT 20
) o
LEFT JOIN users u ON o.user_id = u.id
LEFT JOIN products p ON o.product_id = p.id;
```

### 案例2：统计报表优化

```sql
-- 原始查询（慢）
SELECT 
    DATE(created_at) AS date,
    COUNT(*) AS order_count,
    SUM(amount) AS total_amount
FROM orders
WHERE created_at >= '2024-01-01'
GROUP BY DATE(created_at);

-- 优化方案：创建汇总表
CREATE TABLE order_daily_stats (
    stat_date DATE PRIMARY KEY,
    order_count INT,
    total_amount DECIMAL(12,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 使用存储过程定期更新
DELIMITER $$
CREATE PROCEDURE update_daily_stats()
BEGIN
    INSERT INTO order_daily_stats (stat_date, order_count, total_amount)
    SELECT 
        DATE(created_at),
        COUNT(*),
        SUM(amount)
    FROM orders
    WHERE DATE(created_at) = CURDATE() - INTERVAL 1 DAY
    GROUP BY DATE(created_at)
    ON DUPLICATE KEY UPDATE
        order_count = VALUES(order_count),
        total_amount = VALUES(total_amount);
END$$
DELIMITER ;

-- 定时任务每天执行
-- 查询时直接从汇总表读取
SELECT * FROM order_daily_stats 
WHERE stat_date >= '2024-01-01'
ORDER BY stat_date;
```

---

## 9. 优化检查清单

### 9.1 SQL 层面

```
✅ 避免 SELECT *
✅ 使用 LIMIT 限制结果集
✅ 避免在 WHERE 中使用函数
✅ 避免隐式类型转换
✅ 合理使用 JOIN
✅ 优化子查询
✅ 使用 UNION ALL 代替 UNION
✅ 避免使用 OR，改用 IN 或 UNION
```

### 9.2 索引层面

```
✅ 为 WHERE、ORDER BY、GROUP BY 字段创建索引
✅ 使用联合索引遵循最左前缀原则
✅ 使用覆盖索引避免回表
✅ 避免索引失效场景
✅ 定期分析和优化索引
✅ 删除冗余索引
```

### 9.3 表结构层面

```
✅ 选择合适的数据类型
✅ 字段设置 NOT NULL
✅ 使用 UNSIGNED 存储非负数
✅ 合理使用 TEXT 和 BLOB
✅ 考虑表拆分（垂直/水平）
✅ 定期优化表（OPTIMIZE TABLE）
```

### 9.4 配置层面

```
✅ 合理设置 innodb_buffer_pool_size
✅ 优化连接数配置
✅ 开启慢查询日志
✅ 调整日志刷新策略
✅ 监控系统资源使用
```

---

## 10. 练习题

### 练习1：分析慢查询
使用 EXPLAIN 分析一个慢查询，找出性能瓶颈并优化。

### 练习2：索引优化
为一个包含多个查询条件的 SQL 创建合适的索引。

### 练习3：分页优化
优化一个深分页查询，提升查询性能。

### 练习4：统计优化
优化一个复杂的统计查询，使用汇总表或其他方法。

---

## 📝 本节总结

### 核心要点

1. **慢查询分析**：开启慢查询日志，使用 mysqldumpslow 分析
2. **EXPLAIN 执行计划**：关注 type、rows、Extra 字段
3. **索引优化**：避免索引失效，使用覆盖索引，遵循最左前缀
4. **查询优化**：避免 SELECT *，优化 JOIN 和子查询，优化分页
5. **表结构优化**：选择合适的数据类型，考虑表拆分
6. **配置优化**：调整缓冲区、连接数、日志参数

### 最佳实践

```
✅ 定期分析慢查询日志
✅ 使用 EXPLAIN 分析所有查询
✅ 为常用查询创建合适的索引
✅ 避免全表扫描
✅ 监控数据库性能指标
✅ 定期优化表和索引
```

### 下一步

完成 MySQL 中级学习后，继续学习：
- MySQL 高级：主从复制、读写分离
- 性能调优：系统级优化
- 高可用架构：集群、分库分表

---

**恭喜你完成 MySQL 中级课程！继续加油！** 🎉🚀
