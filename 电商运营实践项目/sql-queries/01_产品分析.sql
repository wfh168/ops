-- ==========================================
-- 01. 产品数据分析查询
-- ==========================================

USE ecommerce_analysis;

-- 1. 查看所有产品基本信息
SELECT 
    sku AS 'SKU',
    product_name AS '产品名称',
    category AS '分类',
    price AS '售价',
    cost AS '成本',
    (price - cost) AS '毛利',
    ROUND((price - cost) / price * 100, 2) AS '毛利率(%)',
    current_stock AS '当前库存',
    safe_stock AS '安全库存',
    status AS '状态'
FROM products
ORDER BY price DESC;

-- 2. 产品库存预警（库存低于安全库存）
SELECT 
    sku AS 'SKU',
    product_name AS '产品名称',
    current_stock AS '当前库存',
    safe_stock AS '安全库存',
    (safe_stock - current_stock) AS '缺口数量',
    CASE 
        WHEN current_stock = 0 THEN '紧急补货'
        WHEN current_stock < safe_stock * 0.5 THEN '高优先级补货'
        ELSE '正常补货'
    END AS '补货优先级'
FROM products
WHERE current_stock < safe_stock
ORDER BY (safe_stock - current_stock) DESC;

-- 3. 产品价格竞争力分析（与竞品对比）
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    p.price AS '我方价格',
    ROUND(AVG(c.price), 2) AS '竞品平均价格',
    ROUND(p.price - AVG(c.price), 2) AS '价格差',
    CASE 
        WHEN p.price < AVG(c.price) * 0.8 THEN '价格优势明显'
        WHEN p.price < AVG(c.price) THEN '价格有优势'
        WHEN p.price <= AVG(c.price) * 1.2 THEN '价格持平'
        ELSE '价格偏高'
    END AS '价格竞争力'
FROM products p
LEFT JOIN competitors c ON p.product_id = c.product_id
GROUP BY p.product_id, p.sku, p.product_name, p.price
ORDER BY p.price DESC;

-- 4. 产品销售表现排行（最近7天）
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    SUM(s.quantity) AS '总销量',
    SUM(s.revenue) AS '总销售额',
    SUM(s.order_count) AS '总订单数',
    ROUND(SUM(s.revenue) / SUM(s.order_count), 2) AS '客单价',
    SUM(s.views) AS '总浏览量',
    ROUND(SUM(s.order_count) / SUM(s.views) * 100, 2) AS '转化率(%)'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.sku, p.product_name
ORDER BY SUM(s.revenue) DESC;

-- 5. 产品利润分析（最近7天）
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    SUM(s.quantity) AS '销量',
    SUM(s.revenue) AS '销售额',
    SUM(s.quantity * p.cost) AS '成本',
    SUM(s.revenue) - SUM(s.quantity * p.cost) AS '毛利润',
    ROUND((SUM(s.revenue) - SUM(s.quantity * p.cost)) / SUM(s.revenue) * 100, 2) AS '毛利率(%)'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.sku, p.product_name
ORDER BY (SUM(s.revenue) - SUM(s.quantity * p.cost)) DESC;

-- 6. 产品分类汇总分析
SELECT 
    p.category AS '产品分类',
    COUNT(DISTINCT p.product_id) AS '产品数量',
    SUM(s.quantity) AS '总销量',
    SUM(s.revenue) AS '总销售额',
    ROUND(AVG(p.price), 2) AS '平均售价',
    ROUND(SUM(s.revenue) / SUM(s.quantity), 2) AS '平均成交价'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.category
ORDER BY SUM(s.revenue) DESC;

-- 7. 产品库存周转率分析（最近7天）
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    p.current_stock AS '当前库存',
    SUM(s.quantity) AS '7天销量',
    ROUND(SUM(s.quantity) / 7, 2) AS '日均销量',
    CASE 
        WHEN SUM(s.quantity) = 0 THEN '无销售'
        ELSE ROUND(p.current_stock / (SUM(s.quantity) / 7), 1)
    END AS '可售天数',
    CASE 
        WHEN SUM(s.quantity) = 0 THEN '滞销'
        WHEN p.current_stock / (SUM(s.quantity) / 7) < 7 THEN '库存不足'
        WHEN p.current_stock / (SUM(s.quantity) / 7) <= 30 THEN '库存正常'
        ELSE '库存过多'
    END AS '库存状态'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.sku, p.product_name, p.current_stock
ORDER BY SUM(s.quantity) DESC;
