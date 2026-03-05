-- ==========================================
-- 02. 销售数据分析查询
-- ==========================================

USE ecommerce_analysis;

-- 1. 每日销售趋势（最近7天）
SELECT 
    sale_date AS '日期',
    SUM(revenue) AS '销售额',
    SUM(quantity) AS '销量',
    SUM(order_count) AS '订单数',
    ROUND(SUM(revenue) / SUM(order_count), 2) AS '客单价',
    SUM(views) AS '浏览量',
    ROUND(SUM(order_count) / SUM(views) * 100, 2) AS '转化率(%)'
FROM sales
WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY sale_date
ORDER BY sale_date DESC;

-- 2. 销售额环比增长分析
SELECT 
    sale_date AS '日期',
    SUM(revenue) AS '当日销售额',
    LAG(SUM(revenue)) OVER (ORDER BY sale_date) AS '前日销售额',
    SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY sale_date) AS '环比增长额',
    ROUND((SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY sale_date)) / 
          LAG(SUM(revenue)) OVER (ORDER BY sale_date) * 100, 2) AS '环比增长率(%)'
FROM sales
WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY sale_date
ORDER BY sale_date DESC;

-- 3. 产品销售贡献度分析（最近7天）
SELECT 
    p.product_name AS '产品名称',
    SUM(s.revenue) AS '销售额',
    ROUND(SUM(s.revenue) / (SELECT SUM(revenue) FROM sales 
                             WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)) * 100, 2) AS '销售额占比(%)',
    SUM(s.quantity) AS '销量',
    ROUND(SUM(s.quantity) / (SELECT SUM(quantity) FROM sales 
                              WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)) * 100, 2) AS '销量占比(%)'
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.product_name
ORDER BY SUM(s.revenue) DESC;

-- 4. 销售峰值分析（找出最佳销售日）
SELECT 
    sale_date AS '日期',
    DAYNAME(sale_date) AS '星期',
    SUM(revenue) AS '销售额',
    SUM(order_count) AS '订单数',
    RANK() OVER (ORDER BY SUM(revenue) DESC) AS '销售额排名'
FROM sales
WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY sale_date
ORDER BY SUM(revenue) DESC;

-- 5. 转化率分析（按产品）
SELECT 
    p.product_name AS '产品名称',
    SUM(s.views) AS '总浏览量',
    SUM(s.order_count) AS '总订单数',
    ROUND(SUM(s.order_count) / SUM(s.views) * 100, 2) AS '转化率(%)',
    CASE 
        WHEN SUM(s.order_count) / SUM(s.views) * 100 >= 5 THEN '优秀'
        WHEN SUM(s.order_count) / SUM(s.views) * 100 >= 3 THEN '良好'
        WHEN SUM(s.order_count) / SUM(s.views) * 100 >= 1 THEN '一般'
        ELSE '需优化'
    END AS '转化率评级'
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.product_name
ORDER BY (SUM(s.order_count) / SUM(s.views)) DESC;

-- 6. 客单价分析（按产品）
SELECT 
    p.product_name AS '产品名称',
    p.price AS '标价',
    ROUND(SUM(s.revenue) / SUM(s.order_count), 2) AS '实际客单价',
    ROUND((SUM(s.revenue) / SUM(s.order_count)) / p.price, 2) AS '客单价/标价比',
    CASE 
        WHEN (SUM(s.revenue) / SUM(s.order_count)) / p.price >= 1.5 THEN '多件购买'
        WHEN (SUM(s.revenue) / SUM(s.order_count)) / p.price >= 1.0 THEN '单件购买'
        ELSE '可能有折扣'
    END AS '购买模式'
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.product_name, p.price
ORDER BY (SUM(s.revenue) / SUM(s.order_count)) DESC;

-- 7. 销售趋势预测（基于7天平均）
SELECT 
    p.product_name AS '产品名称',
    ROUND(AVG(s.quantity), 2) AS '日均销量',
    ROUND(AVG(s.revenue), 2) AS '日均销售额',
    ROUND(AVG(s.quantity) * 30, 0) AS '预测月销量',
    ROUND(AVG(s.revenue) * 30, 2) AS '预测月销售额'
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.product_name
ORDER BY AVG(s.revenue) DESC;

-- 8. 销售波动分析（标准差）
SELECT 
    p.product_name AS '产品名称',
    ROUND(AVG(s.quantity), 2) AS '平均日销量',
    ROUND(STDDEV(s.quantity), 2) AS '销量标准差',
    ROUND(STDDEV(s.quantity) / AVG(s.quantity) * 100, 2) AS '变异系数(%)',
    CASE 
        WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 20 THEN '销售稳定'
        WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 50 THEN '销售波动正常'
        ELSE '销售波动较大'
    END AS '稳定性评价'
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.product_name
HAVING COUNT(s.sale_id) >= 5
ORDER BY (STDDEV(s.quantity) / AVG(s.quantity)) ASC;
