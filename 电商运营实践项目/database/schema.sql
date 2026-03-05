-- 创建数据库
CREATE DATABASE IF NOT EXISTS ecommerce_analysis CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce_analysis;

-- 1. 产品表
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '产品ID',
    sku VARCHAR(50) UNIQUE NOT NULL COMMENT '产品SKU',
    product_name VARCHAR(200) NOT NULL COMMENT '产品名称',
    category VARCHAR(50) NOT NULL COMMENT '产品分类',
    price DECIMAL(10, 2) NOT NULL COMMENT '售价',
    cost DECIMAL(10, 2) NOT NULL COMMENT '成本',
    current_stock INT NOT NULL DEFAULT 0 COMMENT '当前库存',
    safe_stock INT NOT NULL DEFAULT 50 COMMENT '安全库存',
    status ENUM('在售', '缺货', '下架') DEFAULT '在售' COMMENT '产品状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_category (category),
    INDEX idx_status (status)
) COMMENT='产品信息表';

-- 2. 销售记录表
CREATE TABLE sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '销售ID',
    product_id INT NOT NULL COMMENT '产品ID',
    sale_date DATE NOT NULL COMMENT '销售日期',
    quantity INT NOT NULL COMMENT '销量',
    revenue DECIMAL(10, 2) NOT NULL COMMENT '销售额',
    order_count INT NOT NULL COMMENT '订单数',
    views INT DEFAULT 0 COMMENT '浏览量',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_sale_date (sale_date),
    INDEX idx_product_date (product_id, sale_date)
) COMMENT='销售记录表';

-- 3. 竞品表
CREATE TABLE competitors (
    competitor_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '竞品ID',
    product_id INT NOT NULL COMMENT '对应产品ID',
    competitor_name VARCHAR(200) NOT NULL COMMENT '竞品名称',
    competitor_sku VARCHAR(50) COMMENT '竞品SKU',
    price DECIMAL(10, 2) NOT NULL COMMENT '竞品价格',
    estimated_sales INT DEFAULT 0 COMMENT '估算月销量',
    rating DECIMAL(3, 2) DEFAULT 0 COMMENT '评分',
    review_count INT DEFAULT 0 COMMENT '评论数',
    last_updated DATE NOT NULL COMMENT '最后更新日期',
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_product (product_id)
) COMMENT='竞品信息表';

-- 4. 库存记录表
CREATE TABLE inventory_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '记录ID',
    product_id INT NOT NULL COMMENT '产品ID',
    log_date DATE NOT NULL COMMENT '日期',
    stock_quantity INT NOT NULL COMMENT '库存数量',
    change_quantity INT NOT NULL COMMENT '变化数量',
    change_type ENUM('入库', '出库', '盘点') NOT NULL COMMENT '变化类型',
    note VARCHAR(200) COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_product_date (product_id, log_date)
) COMMENT='库存变动记录表';

-- 5. 运营指标表（每日汇总）
CREATE TABLE daily_metrics (
    metric_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '指标ID',
    metric_date DATE NOT NULL COMMENT '日期',
    total_revenue DECIMAL(12, 2) NOT NULL COMMENT '总销售额',
    total_orders INT NOT NULL COMMENT '总订单数',
    total_quantity INT NOT NULL COMMENT '总销量',
    avg_order_value DECIMAL(10, 2) NOT NULL COMMENT '客单价',
    total_views INT DEFAULT 0 COMMENT '总浏览量',
    conversion_rate DECIMAL(5, 2) DEFAULT 0 COMMENT '转化率(%)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY uk_date (metric_date),
    INDEX idx_date (metric_date)
) COMMENT='每日运营指标表';
