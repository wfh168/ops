# 01 - MySQL 架构原理

## 📚 本节目标

- 理解 MySQL 整体架构
- 掌握 InnoDB 存储引擎原理
- 理解 MySQL 日志系统
- 掌握缓冲池机制
- 理解查询执行流程
- 了解存储引擎对比

---

## 1. MySQL 架构概览

### 1.1 整体架构

```
┌─────────────────────────────────────────┐
│         客户端（Client）                  │
│   MySQL Workbench, Navicat, 应用程序     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         连接层（Connection Layer）        │
│   连接处理、认证、安全                     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         服务层（SQL Layer）               │
│  ┌──────────────────────────────────┐   │
│  │  查询缓存（Query Cache）          │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  解析器（Parser）                 │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  优化器（Optimizer）              │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  执行器（Executor）               │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         存储引擎层（Storage Engine）      │
│   InnoDB, MyISAM, Memory, Archive...    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         文件系统（File System）           │
│   数据文件、日志文件、配置文件             │
└─────────────────────────────────────────┘
```

### 1.2 各层功能

**连接层**：
- 处理客户端连接
- 用户认证和授权
- 连接池管理
- 线程管理

**服务层**：
- SQL 解析和语法分析
- 查询优化
- 缓存管理
- 内置函数
- 跨存储引擎功能

**存储引擎层**：
- 数据存储和读取
- 索引管理
- 事务支持
- 锁机制

---

## 2. InnoDB 存储引擎

### 2.1 InnoDB 架构

```
┌─────────────────────────────────────────┐
│           InnoDB 内存结构                 │
│  ┌──────────────────────────────────┐   │
│  │  Buffer Pool（缓冲池）            │   │
│  │  ├─ Data Pages                   │   │
│  │  ├─ Index Pages                  │   │
│  │  ├─ Insert Buffer                │   │
│  │  └─ Adaptive Hash Index          │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  Change Buffer（写缓冲）          │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  Log Buffer（日志缓冲）           │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│           InnoDB 磁盘结构                 │
│  ┌──────────────────────────────────┐   │
│  │  System Tablespace（系统表空间）  │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  File-Per-Table Tablespace       │   │
│  │  （独立表空间 .ibd）               │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  Redo Log（重做日志）             │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  Undo Log（回滚日志）             │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```


### 2.2 Buffer Pool（缓冲池）

**作用**：
- 缓存数据页和索引页
- 减少磁盘 I/O
- 提高查询性能

**配置**：
```sql
-- 查看缓冲池大小
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

-- 设置缓冲池大小（建议物理内存的 70-80%）
SET GLOBAL innodb_buffer_pool_size = 8589934592;  -- 8GB

-- 查看缓冲池实例数
SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';

-- 设置缓冲池实例数（建议 1GB 一个实例）
SET GLOBAL innodb_buffer_pool_instances = 8;
```

**监控缓冲池**：
```sql
-- 查看缓冲池状态
SHOW ENGINE INNODB STATUS\G

-- 查看缓冲池使用情况
SELECT 
    POOL_ID,
    POOL_SIZE,
    FREE_BUFFERS,
    DATABASE_PAGES,
    OLD_DATABASE_PAGES
FROM information_schema.INNODB_BUFFER_POOL_STATS;

-- 计算缓冲池命中率
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read%';
-- 命中率 = (Innodb_buffer_pool_read_requests - Innodb_buffer_pool_reads) 
--         / Innodb_buffer_pool_read_requests * 100%
```

### 2.3 Change Buffer（写缓冲）

**作用**：
- 缓存非唯一二级索引的修改
- 延迟写入磁盘
- 减少随机 I/O

**配置**：
```sql
-- 查看 Change Buffer 配置
SHOW VARIABLES LIKE 'innodb_change_buffer%';

-- 设置 Change Buffer 最大大小（占 Buffer Pool 的百分比）
SET GLOBAL innodb_change_buffer_max_size = 25;  -- 25%

-- 设置 Change Buffer 类型
SET GLOBAL innodb_change_buffering = 'all';
-- all: 缓存 insert, delete, purge
-- none: 不缓存
-- inserts: 只缓存 insert
```

### 2.4 Adaptive Hash Index（自适应哈希索引）

**作用**：
- InnoDB 自动创建的哈希索引
- 加速等值查询
- 无需手动维护

**配置**：
```sql
-- 查看自适应哈希索引状态
SHOW VARIABLES LIKE 'innodb_adaptive_hash_index';

-- 开启/关闭自适应哈希索引
SET GLOBAL innodb_adaptive_hash_index = ON;

-- 查看自适应哈希索引使用情况
SHOW ENGINE INNODB STATUS\G
```

---

## 3. MySQL 日志系统

### 3.1 Redo Log（重做日志）

**作用**：
- 保证事务的持久性（Durability）
- 实现崩溃恢复
- WAL（Write-Ahead Logging）机制

**工作原理**：
```
1. 事务修改数据时，先写 Redo Log
2. Redo Log 写入磁盘（顺序写，快）
3. 数据页在合适的时机刷入磁盘（随机写，慢）
4. 崩溃恢复时，使用 Redo Log 重做未完成的事务
```

**配置**：
```sql
-- 查看 Redo Log 配置
SHOW VARIABLES LIKE 'innodb_log%';

-- Redo Log 文件大小（建议 1-4GB）
innodb_log_file_size = 1G

-- Redo Log 文件数量
innodb_log_files_in_group = 2

-- Redo Log 缓冲区大小
innodb_log_buffer_size = 16M

-- 刷新策略
innodb_flush_log_at_trx_commit = 1
-- 0: 每秒刷新一次（性能最好，可能丢失 1 秒数据）
-- 1: 每次事务提交刷新（最安全，性能较差）
-- 2: 每次提交写入 OS 缓存，每秒刷新（折中方案）
```

**Redo Log 循环写入**：
```
┌─────────────────────────────────────┐
│  ib_logfile0                        │
│  ┌──────────────────────────────┐   │
│  │ write pos →                  │   │
│  │              ← checkpoint     │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  ib_logfile1                        │
│  ┌──────────────────────────────┐   │
│  │                              │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘

write pos: 当前写入位置
checkpoint: 已刷盘位置
可用空间 = checkpoint - write pos
```

### 3.2 Undo Log（回滚日志）

**作用**：
- 保证事务的原子性（Atomicity）
- 实现事务回滚
- 实现 MVCC（多版本并发控制）

**工作原理**：
```
1. 事务修改数据前，先记录 Undo Log
2. Undo Log 记录修改前的数据
3. 事务回滚时，使用 Undo Log 恢复数据
4. 事务提交后，Undo Log 用于 MVCC
```

**Undo Log 类型**：
- Insert Undo Log：插入操作的回滚日志
- Update Undo Log：更新和删除操作的回滚日志

**配置**：
```sql
-- 查看 Undo Log 配置
SHOW VARIABLES LIKE 'innodb_undo%';

-- Undo 表空间数量
innodb_undo_tablespaces = 2

-- Undo 日志段数量
innodb_undo_logs = 128

-- Undo 日志截断
innodb_undo_log_truncate = ON
innodb_max_undo_log_size = 1G
```

### 3.3 Binlog（二进制日志）

**作用**：
- 主从复制
- 数据恢复
- 审计

**Binlog 格式**：
```sql
-- 查看 Binlog 格式
SHOW VARIABLES LIKE 'binlog_format';

-- 三种格式
-- STATEMENT: 记录 SQL 语句（体积小，可能不一致）
-- ROW: 记录每行数据变化（体积大，完全一致）
-- MIXED: 混合模式（自动选择）

-- 设置 Binlog 格式
SET GLOBAL binlog_format = 'ROW';
```

**配置**：
```sql
-- my.cnf 配置
[mysqld]
# 开启 Binlog
log_bin = /var/log/mysql/mysql-bin
server_id = 1

# Binlog 格式
binlog_format = ROW

# Binlog 过期时间（天）
expire_logs_days = 7

# Binlog 缓存大小
binlog_cache_size = 4M

# 每次事务提交同步 Binlog
sync_binlog = 1
```

**查看 Binlog**：
```sql
-- 查看 Binlog 列表
SHOW BINARY LOGS;

-- 查看当前使用的 Binlog
SHOW MASTER STATUS;

-- 查看 Binlog 内容
SHOW BINLOG EVENTS IN 'mysql-bin.000001';

-- 使用 mysqlbinlog 工具
-- mysqlbinlog mysql-bin.000001
```

### 3.4 三种日志对比

| 日志类型 | 作用 | 层级 | 格式 |
|---------|------|------|------|
| Redo Log | 崩溃恢复、持久性 | InnoDB 引擎层 | 物理日志 |
| Undo Log | 事务回滚、MVCC | InnoDB 引擎层 | 逻辑日志 |
| Binlog | 主从复制、数据恢复 | Server 层 | 逻辑日志 |

---

## 4. 查询执行流程

### 4.1 完整执行流程

```
客户端
  ↓
连接器（验证身份、管理连接）
  ↓
查询缓存（MySQL 8.0 已移除）
  ↓
分析器（词法分析、语法分析）
  ↓
优化器（选择索引、生成执行计划）
  ↓
执行器（调用存储引擎接口）
  ↓
存储引擎（读取/写入数据）
  ↓
返回结果
```

### 4.2 详细步骤

**1. 连接器**
```sql
-- 查看当前连接
SHOW PROCESSLIST;

-- 查看连接数
SHOW STATUS LIKE 'Threads_connected';

-- 查看最大连接数
SHOW VARIABLES LIKE 'max_connections';

-- 连接超时时间
SHOW VARIABLES LIKE 'wait_timeout';
```

**2. 查询缓存（MySQL 8.0 已移除）**
```sql
-- MySQL 5.7 查看查询缓存
SHOW VARIABLES LIKE 'query_cache%';

-- MySQL 8.0 不再支持查询缓存
-- 原因：缓存失效频繁，收益不高
```

**3. 分析器**
```sql
-- 词法分析：识别关键字、表名、字段名
-- 语法分析：检查 SQL 语法是否正确

-- 示例：语法错误
SELECT * FORM users;  -- 错误：FORM 应该是 FROM
-- ERROR 1064: You have an error in your SQL syntax
```

**4. 优化器**
```sql
-- 优化器决定：
-- 1. 使用哪个索引
-- 2. 多表 JOIN 的顺序
-- 3. 子查询的执行方式

-- 查看优化器选择
EXPLAIN SELECT * FROM users WHERE id = 1;

-- 强制使用索引
SELECT * FROM users FORCE INDEX(idx_name) WHERE name = '张三';

-- 忽略索引
SELECT * FROM users IGNORE INDEX(idx_name) WHERE name = '张三';
```

**5. 执行器**
```sql
-- 执行器流程：
-- 1. 检查权限
-- 2. 调用存储引擎接口
-- 3. 返回结果

-- 查看执行统计
SHOW STATUS LIKE 'Handler_read%';
```

### 4.3 查询示例

```sql
-- 创建测试表
CREATE TABLE query_test (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    age INT,
    city VARCHAR(50),
    INDEX idx_name (name),
    INDEX idx_age (age)
);

-- 插入测试数据
INSERT INTO query_test (name, age, city)
SELECT 
    CONCAT('user', n),
    18 + (n % 50),
    CASE (n % 5)
        WHEN 0 THEN '北京'
        WHEN 1 THEN '上海'
        WHEN 2 THEN '广州'
        WHEN 3 THEN '深圳'
        ELSE '杭州'
    END
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

-- 分析查询执行
EXPLAIN SELECT * FROM query_test WHERE name = 'user100';
EXPLAIN SELECT * FROM query_test WHERE age > 30;
EXPLAIN SELECT * FROM query_test WHERE name = 'user100' AND age > 30;
```

---

## 5. 存储引擎对比

### 5.1 InnoDB vs MyISAM

| 特性 | InnoDB | MyISAM |
|------|--------|--------|
| 事务支持 | ✅ 支持 | ❌ 不支持 |
| 外键约束 | ✅ 支持 | ❌ 不支持 |
| 行级锁 | ✅ 支持 | ❌ 表级锁 |
| MVCC | ✅ 支持 | ❌ 不支持 |
| 崩溃恢复 | ✅ 支持 | ❌ 不支持 |
| 全文索引 | ✅ 5.6+ 支持 | ✅ 支持 |
| 存储空间 | 较大 | 较小 |
| 适用场景 | OLTP（事务处理） | OLAP（分析查询） |

### 5.2 查看和设置存储引擎

```sql
-- 查看支持的存储引擎
SHOW ENGINES;

-- 查看默认存储引擎
SHOW VARIABLES LIKE 'default_storage_engine';

-- 设置默认存储引擎
SET default_storage_engine = InnoDB;

-- 查看表的存储引擎
SHOW TABLE STATUS LIKE 'users';

-- 修改表的存储引擎
ALTER TABLE users ENGINE = InnoDB;
```

### 5.3 其他存储引擎

**Memory 引擎**：
```sql
-- 特点：数据存储在内存中，速度快，重启后数据丢失
CREATE TABLE temp_data (
    id INT PRIMARY KEY,
    data VARCHAR(100)
) ENGINE = Memory;

-- 适用场景：临时表、缓存表
```

**Archive 引擎**：
```sql
-- 特点：高压缩比，只支持 INSERT 和 SELECT
CREATE TABLE log_archive (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_time DATETIME,
    log_content TEXT
) ENGINE = Archive;

-- 适用场景：日志归档、历史数据
```

**CSV 引擎**：
```sql
-- 特点：数据以 CSV 格式存储
CREATE TABLE csv_data (
    id INT,
    name VARCHAR(50),
    value DECIMAL(10,2)
) ENGINE = CSV;

-- 适用场景：数据导入导出
```

---

## 6. InnoDB 关键特性

### 6.1 聚簇索引

**概念**：
- InnoDB 的主键索引是聚簇索引
- 数据和索引存储在一起
- 叶子节点存储完整的行数据

**优点**：
- 主键查询速度快
- 范围查询效率高

**缺点**：
- 二级索引需要回表
- 插入顺序影响性能

```sql
-- 主键索引（聚簇索引）
CREATE TABLE clustered_example (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    age INT
);

-- 二级索引
CREATE INDEX idx_name ON clustered_example(name);

-- 主键查询（直接从聚簇索引获取数据）
SELECT * FROM clustered_example WHERE id = 1;

-- 二级索引查询（需要回表）
SELECT * FROM clustered_example WHERE name = '张三';
```

### 6.2 外键约束

```sql
-- 创建父表
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
) ENGINE = InnoDB;

-- 创建子表（带外键）
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- 外键约束选项
-- ON DELETE CASCADE: 删除父表记录时，自动删除子表记录
-- ON DELETE SET NULL: 删除父表记录时，子表外键设为 NULL
-- ON DELETE RESTRICT: 有子表记录时，不允许删除父表记录
-- ON UPDATE CASCADE: 更新父表主键时，自动更新子表外键
```

### 6.3 自增锁

```sql
-- 查看自增锁模式
SHOW VARIABLES LIKE 'innodb_autoinc_lock_mode';

-- 三种模式
-- 0: 传统模式（表级锁）
-- 1: 连续模式（默认，性能好）
-- 2: 交错模式（性能最好，但 Binlog 为 STATEMENT 时不安全）

-- 设置自增锁模式
SET GLOBAL innodb_autoinc_lock_mode = 1;
```

---

## 7. 性能监控

### 7.1 查看 InnoDB 状态

```sql
-- 查看 InnoDB 详细状态
SHOW ENGINE INNODB STATUS\G

-- 主要关注：
-- SEMAPHORES: 信号量信息
-- TRANSACTIONS: 事务信息
-- BUFFER POOL AND MEMORY: 缓冲池信息
-- ROW OPERATIONS: 行操作统计
```

### 7.2 性能指标

```sql
-- 查看 InnoDB 性能指标
SELECT * FROM performance_schema.global_status
WHERE VARIABLE_NAME LIKE 'Innodb%';

-- 关键指标
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read%';
SHOW GLOBAL STATUS LIKE 'Innodb_rows%';
SHOW GLOBAL STATUS LIKE 'Innodb_data%';
```

### 7.3 监控工具

```bash
# mysqladmin
mysqladmin -u root -p extended-status | grep Innodb

# innotop（实时监控工具）
innotop -u root -p

# Percona Toolkit
pt-mysql-summary
pt-query-digest slow.log
```

---

## 8. 实战案例

### 案例1：优化缓冲池配置

```sql
-- 1. 查看当前配置
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

-- 2. 计算合适的大小（物理内存的 70-80%）
-- 假设服务器有 16GB 内存
-- 缓冲池大小 = 16GB * 0.75 = 12GB

-- 3. 动态调整（MySQL 5.7+）
SET GLOBAL innodb_buffer_pool_size = 12884901888;  -- 12GB

-- 4. 监控命中率
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read%';

-- 5. 计算命中率
-- 命中率 = (read_requests - reads) / read_requests * 100%
-- 目标：命中率 > 99%
```

### 案例2：分析慢查询

```sql
-- 1. 开启慢查询日志
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 1;

-- 2. 执行查询
SELECT * FROM query_test WHERE city = '北京' ORDER BY age;

-- 3. 分析执行计划
EXPLAIN SELECT * FROM query_test WHERE city = '北京' ORDER BY age;

-- 4. 优化：创建联合索引
CREATE INDEX idx_city_age ON query_test(city, age);

-- 5. 再次分析
EXPLAIN SELECT * FROM query_test WHERE city = '北京' ORDER BY age;
```

---

## 9. 练习题

### 练习1：架构理解
画出 MySQL 的整体架构图，标注各层的主要功能。

### 练习2：日志系统
解释 Redo Log、Undo Log、Binlog 的区别和作用。

### 练习3：缓冲池优化
根据服务器配置，计算并设置合适的缓冲池大小。

### 练习4：查询分析
使用 EXPLAIN 分析一个复杂查询，找出性能瓶颈并优化。

---

## 📝 本节总结

### 核心要点

1. **MySQL 架构**：连接层、服务层、存储引擎层、文件系统
2. **InnoDB 引擎**：Buffer Pool、Change Buffer、Adaptive Hash Index
3. **日志系统**：Redo Log（持久性）、Undo Log（原子性）、Binlog（复制）
4. **查询流程**：连接器 → 分析器 → 优化器 → 执行器 → 存储引擎
5. **存储引擎**：InnoDB（事务）、MyISAM（查询）、Memory（临时）

### 最佳实践

```
✅ 使用 InnoDB 存储引擎
✅ 合理配置缓冲池大小
✅ 开启 Binlog 用于备份和复制
✅ 设置合适的日志刷新策略
✅ 定期监控性能指标
✅ 使用 EXPLAIN 分析查询
```

### 下一步

学习完 MySQL 架构后，继续学习：
- 主从复制配置
- 读写分离实现
- 高可用架构设计

---

**深入理解 MySQL 架构，是成为高级 DBA 的基础！** 🚀
