-- ==========================================
-- 04. 竞品对比分析
-- ==========================================

USE ecommerce_analysis;

-- 1. 竞品价格对比
SELECT 
    p.product_name AS '我方产品',
    p.price AS '我方价格',
    c.competitor_name AS '竞品名称',
    c.price AS '竞品价格',
    p.price - c.price AS '价格差',
    ROUND((p.price - c.price) / c.price * 100, 2) AS '价格差异(%)',
    CASE 
        WHEN p.price < c.price * 0.8 THEN '价格优势明显'
        WHEN p.price < c.price THEN '价格有优势'
        WHEN p.price = c.price THEN '价格持平'
        WHEN p.price <= c.price * 1.2 THEN '价格略高'
        ELSE '价格偏高'
    END AS '价格竞争力'
FROM products p
JOIN competitors c ON p.product_id = c.product_id
ORDER BY p.product_name, c.price;

-- 2. 竞品销量对比（估算）
SELECT 
    p.product_name AS '我方产品',
    COALESCE(SUM(s.quantity), 0) AS '我方7天销量',
    ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) AS '我方预估月销量',
    c.competitor_name AS '竞品名称',
    c.estimated_sales AS '竞品月销量',
    ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) - c.estimated_sales AS '销量差距',
    CASE 
        WHEN ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) > c.estimated_sales THEN '销量领先'
        WHEN ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) >= c.estimated_sales * 0.8 THEN '销量接近'
        ELSE '销量落后'
    END AS '销量对比'
FROM products p
JOIN competitors c ON p.product_id = c.product_id
LEFT JOIN sales s ON p.product_id = s.product_id 
    AND s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.product_name, c.competitor_id, c.competitor_name, c.estimated_sales
ORDER BY p.product_name, c.estimated_sales DESC;

-- 3. 竞品评分对比
SELECT 
    p.product_name AS '我方产品',
    '暂无评分' AS '我方评分',
    c.competitor_name AS '竞品名称',
    c.rating AS '竞品评分',
    c.review_count AS '竞品评论数',
    CASE 
        WHEN c.rating >= 4.8 THEN '竞品口碑优秀'
        WHEN c.rating >= 4.5 THEN '竞品口碑良好'
        WHEN c.rating >= 4.0 THEN '竞品口碑一般'
        ELSE '竞品口碑较差'
    END AS '竞品口碑评价'
FROM products p
JOIN competitors c ON p.product_id = c.product_id
ORDER BY p.product_name, c.rating DESC;

-- 4. 竞品市场份额分析（基于销量）
SELECT 
    p.product_name AS '产品类别',
    ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) AS '我方预估月销量',
    SUM(c.estimated_sales) AS '竞品总月销量',
    ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) + SUM(c.estimated_sales) AS '市场总销量',
    ROUND(ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) / 
          (ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) + SUM(c.estimated_sales)) * 100, 2) AS '我方市场份额(%)',
    ROUND(SUM(c.estimated_sales) / 
          (ROUND(COALESCE(SUM(s.quantity), 0) * 30 / 7, 0) + SUM(c.estimated_sales)) * 100, 2) AS '竞品市场份额(%)'
FROM products p
JOIN competitors c ON p.product_id = c.product_id
LEFT JOIN sales s ON p.product_id = s.product_id 
    AND s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.product_name
ORDER BY '我方市场份额(%)' DESC;

-- 5. 价格竞争力综合分析
SELECT 
    p.product_name AS '产品名称',
    p.price AS '我方价格',
    MIN(c.price) AS '竞品最低价',
    MAX(c.price) AS '竞品最高价',
    ROUND(AVG(c.price), 2) AS '竞品平均价',
    CASE 
        WHEN p.price < MIN(c.price) THEN '价格最低'
        WHEN p.price <= AVG(c.price) THEN '价格有竞争力'
        WHEN p.price <= MAX(c.price) THEN '价格中等'
        ELSE '价格最高'
    END AS '价格定位',
    CASE 
        WHEN p.price < MIN(c.price) THEN '可考虑适当提价'
        WHEN p.price <= AVG(c.price) THEN '价格策略合理'
        WHEN p.price <= MAX(c.price) THEN '需提升产品价值'
        ELSE '建议降价或突出差异化'
    END AS '定价建议'
FROM products p
JOIN competitors c ON p.product_id = c.product_id
GROUP BY p.product_id, p.product_name, p.price
ORDER BY p.price;

-- 6. 竞品威胁度评估
SELECT 
    p.product_name AS '我方产品',
    c.competitor_name AS '竞品名称',
    c.price AS '竞品价格',
    p.price AS '我方价格',
    c.estimated_sales AS '竞品月销量',
    c.rating AS '竞品评分',
    c.review_count AS '评论数',
    -- 威胁度评分计算
    (CASE 
        WHEN c.price < p.price * 0.8 THEN 30
        WHEN c.price < p.price THEN 20
        WHEN c.price <= p.price * 1.2 THEN 10
        ELSE 0
    END +
    CASE 
        WHEN c.estimated_sales > 500 THEN 30
        WHEN c.estimated_sales > 200 THEN 20
        WHEN c.estimated_sales > 100 THEN 10
        ELSE 5
    END +
    CASE 
        WHEN c.rating >= 4.8 THEN 20
        WHEN c.rating >= 4.5 THEN 15
        WHEN c.rating >= 4.0 THEN 10
        ELSE 5
    END +
    CASE 
        WHEN c.review_count > 2000 THEN 20
        WHEN c.review_count > 1000 THEN 15
        WHEN c.review_count > 500 THEN 10
        ELSE 5
    END) AS '威胁度评分',
    CASE 
        WHEN (CASE 
            WHEN c.price < p.price * 0.8 THEN 30
            WHEN c.price < p.price THEN 20
            WHEN c.price <= p.price * 1.2 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN c.estimated_sales > 500 THEN 30
            WHEN c.estimated_sales > 200 THEN 20
            WHEN c.estimated_sales > 100 THEN 10
            ELSE 5
        END +
        CASE 
            WHEN c.rating >= 4.8 THEN 20
            WHEN c.rating >= 4.5 THEN 15
            WHEN c.rating >= 4.0 THEN 10
            ELSE 5
        END +
        CASE 
            WHEN c.review_count > 2000 THEN 20
            WHEN c.review_count > 1000 THEN 15
            WHEN c.review_count > 500 THEN 10
            ELSE 5
        END) >= 70 THEN '🔴 高威胁'
        WHEN (CASE 
            WHEN c.price < p.price * 0.8 THEN 30
            WHEN c.price < p.price THEN 20
            WHEN c.price <= p.price * 1.2 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN c.estimated_sales > 500 THEN 30
            WHEN c.estimated_sales > 200 THEN 20
            WHEN c.estimated_sales > 100 THEN 10
            ELSE 5
        END +
        CASE 
            WHEN c.rating >= 4.8 THEN 20
            WHEN c.rating >= 4.5 THEN 15
            WHEN c.rating >= 4.0 THEN 10
            ELSE 5
        END +
        CASE 
            WHEN c.review_count > 2000 THEN 20
            WHEN c.review_count > 1000 THEN 15
            WHEN c.review_count > 500 THEN 10
            ELSE 5
        END) >= 50 THEN '🟡 中威胁'
        ELSE '🟢 低威胁'
    END AS '威胁等级'
FROM products p
JOIN competitors c ON p.product_id = c.product_id
ORDER BY '威胁度评分' DESC;

-- 7. 竞品策略建议
SELECT 
    p.product_name AS '产品名称',
    COUNT(c.competitor_id) AS '竞品数量',
    ROUND(AVG(c.price), 2) AS '竞品平均价',
    p.price AS '我方价格',
    ROUND(AVG(c.estimated_sales), 0) AS '竞品平均月销',
    CASE 
        WHEN p.price > AVG(c.price) * 1.2 AND COUNT(c.competitor_id) > 3 THEN '价格压力大，建议降价或突出差异化'
        WHEN p.price < AVG(c.price) * 0.8 THEN '价格优势明显，可适当提价增加利润'
        WHEN COUNT(c.competitor_id) > 5 THEN '竞争激烈，建议加强营销和产品优化'
        WHEN COUNT(c.competitor_id) <= 2 THEN '竞争较小，可保持现有策略'
        ELSE '竞争适中，持续优化产品和服务'
    END AS '竞争策略建议'
FROM products p
LEFT JOIN competitors c ON p.product_id = c.product_id
GROUP BY p.product_id, p.product_name, p.price
ORDER BY COUNT(c.competitor_id) DESC;
