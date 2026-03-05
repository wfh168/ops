-- ==========================================
-- 03. 库存管理与预警分析
-- ==========================================

USE ecommerce_analysis;

-- 1. 库存预警总览
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    p.current_stock AS '当前库存',
    p.safe_stock AS '安全库存',
    ROUND(AVG(s.quantity), 2) AS '日均销量',
    CASE 
        WHEN AVG(s.quantity) = 0 THEN '无销售'
        ELSE ROUND(p.current_stock / AVG(s.quantity), 1)
    END AS '可售天数',
    CASE 
        WHEN p.current_stock = 0 THEN '🔴 紧急缺货'
        WHEN p.current_stock < p.safe_stock * 0.3 THEN '🟠 严重不足'
        WHEN p.current_stock < p.safe_stock * 0.5 THEN '🟡 库存偏低'
        WHEN p.current_stock < p.safe_stock THEN '🟢 需要补货'
        WHEN p.current_stock > p.safe_stock * 3 THEN '🔵 库存过多'
        ELSE '✅ 库存正常'
    END AS '库存状态'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.sku, p.product_name, p.current_stock, p.safe_stock
ORDER BY 
    CASE 
        WHEN p.current_stock = 0 THEN 1
        WHEN p.current_stock < p.safe_stock * 0.3 THEN 2
        WHEN p.current_stock < p.safe_stock * 0.5 THEN 3
        WHEN p.current_stock < p.safe_stock THEN 4
        ELSE 5
    END;

-- 2. 补货建议（基于销售速度）
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    p.current_stock AS '当前库存',
    ROUND(AVG(s.quantity), 2) AS '日均销量',
    ROUND(AVG(s.quantity) * 30, 0) AS '预计月销量',
    p.safe_stock AS '安全库存',
    CASE 
        WHEN AVG(s.quantity) * 30 > p.current_stock THEN 
            ROUND(AVG(s.quantity) * 30 - p.current_stock + p.safe_stock, 0)
        ELSE 0
    END AS '建议补货数量',
    CASE 
        WHEN AVG(s.quantity) * 30 > p.current_stock THEN '需要补货'
        ELSE '暂不需要'
    END AS '补货建议'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.sku, p.product_name, p.current_stock, p.safe_stock
HAVING AVG(s.quantity) > 0
ORDER BY (AVG(s.quantity) * 30 - p.current_stock) DESC;

-- 3. 库存周转率分析
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    SUM(s.quantity) AS '7天销量',
    p.current_stock AS '当前库存',
    ROUND(SUM(s.quantity) / p.current_stock, 2) AS '库存周转率',
    ROUND(7 / (SUM(s.quantity) / p.current_stock), 1) AS '库存周转天数',
    CASE 
        WHEN SUM(s.quantity) / p.current_stock >= 1 THEN '周转快'
        WHEN SUM(s.quantity) / p.current_stock >= 0.5 THEN '周转正常'
        WHEN SUM(s.quantity) / p.current_stock >= 0.2 THEN '周转慢'
        ELSE '周转很慢'
    END AS '周转评价'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
  AND p.current_stock > 0
GROUP BY p.product_id, p.sku, p.product_name, p.current_stock
ORDER BY (SUM(s.quantity) / p.current_stock) DESC;

-- 4. 库存成本分析
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    p.current_stock AS '当前库存',
    p.cost AS '单位成本',
    p.current_stock * p.cost AS '库存总成本',
    ROUND(AVG(s.quantity), 2) AS '日均销量',
    CASE 
        WHEN AVG(s.quantity) = 0 THEN 0
        ELSE ROUND(p.current_stock / AVG(s.quantity) * p.cost, 2)
    END AS '每日库存成本'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.sku, p.product_name, p.current_stock, p.cost
ORDER BY (p.current_stock * p.cost) DESC;

-- 5. 滞销产品识别
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    p.current_stock AS '当前库存',
    COALESCE(SUM(s.quantity), 0) AS '7天销量',
    p.current_stock * p.cost AS '库存成本',
    CASE 
        WHEN COALESCE(SUM(s.quantity), 0) = 0 THEN '完全滞销'
        WHEN COALESCE(SUM(s.quantity), 0) < 5 THEN '严重滞销'
        WHEN COALESCE(SUM(s.quantity), 0) < 10 THEN '轻微滞销'
        ELSE '正常'
    END AS '滞销等级',
    '考虑促销或清仓' AS '建议措施'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id 
    AND s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
WHERE p.current_stock > 0
GROUP BY p.product_id, p.sku, p.product_name, p.current_stock, p.cost
HAVING COALESCE(SUM(s.quantity), 0) < 10
ORDER BY COALESCE(SUM(s.quantity), 0) ASC;

-- 6. 库存变动历史
SELECT 
    il.log_date AS '日期',
    p.product_name AS '产品名称',
    il.change_type AS '变动类型',
    il.change_quantity AS '变动数量',
    il.stock_quantity AS '变动后库存',
    il.note AS '备注'
FROM inventory_logs il
JOIN products p ON il.product_id = p.product_id
WHERE il.log_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY il.log_date DESC, p.product_name;

-- 7. 库存健康度评分
SELECT 
    p.sku AS 'SKU',
    p.product_name AS '产品名称',
    p.current_stock AS '当前库存',
    p.safe_stock AS '安全库存',
    ROUND(AVG(s.quantity), 2) AS '日均销量',
    -- 库存充足度评分 (0-40分)
    CASE 
        WHEN p.current_stock >= p.safe_stock THEN 40
        WHEN p.current_stock >= p.safe_stock * 0.5 THEN 30
        WHEN p.current_stock >= p.safe_stock * 0.3 THEN 20
        ELSE 10
    END AS '库存充足度',
    -- 周转速度评分 (0-30分)
    CASE 
        WHEN AVG(s.quantity) = 0 THEN 0
        WHEN SUM(s.quantity) / p.current_stock >= 1 THEN 30
        WHEN SUM(s.quantity) / p.current_stock >= 0.5 THEN 25
        WHEN SUM(s.quantity) / p.current_stock >= 0.2 THEN 15
        ELSE 5
    END AS '周转速度',
    -- 销售稳定性评分 (0-30分)
    CASE 
        WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 20 THEN 30
        WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 50 THEN 20
        ELSE 10
    END AS '销售稳定性',
    -- 总分
    (CASE 
        WHEN p.current_stock >= p.safe_stock THEN 40
        WHEN p.current_stock >= p.safe_stock * 0.5 THEN 30
        WHEN p.current_stock >= p.safe_stock * 0.3 THEN 20
        ELSE 10
    END +
    CASE 
        WHEN AVG(s.quantity) = 0 THEN 0
        WHEN SUM(s.quantity) / p.current_stock >= 1 THEN 30
        WHEN SUM(s.quantity) / p.current_stock >= 0.5 THEN 25
        WHEN SUM(s.quantity) / p.current_stock >= 0.2 THEN 15
        ELSE 5
    END +
    CASE 
        WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 20 THEN 30
        WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 50 THEN 20
        ELSE 10
    END) AS '健康度总分',
    CASE 
        WHEN (CASE 
            WHEN p.current_stock >= p.safe_stock THEN 40
            WHEN p.current_stock >= p.safe_stock * 0.5 THEN 30
            WHEN p.current_stock >= p.safe_stock * 0.3 THEN 20
            ELSE 10
        END +
        CASE 
            WHEN AVG(s.quantity) = 0 THEN 0
            WHEN SUM(s.quantity) / p.current_stock >= 1 THEN 30
            WHEN SUM(s.quantity) / p.current_stock >= 0.5 THEN 25
            WHEN SUM(s.quantity) / p.current_stock >= 0.2 THEN 15
            ELSE 5
        END +
        CASE 
            WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 20 THEN 30
            WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 50 THEN 20
            ELSE 10
        END) >= 80 THEN '优秀'
        WHEN (CASE 
            WHEN p.current_stock >= p.safe_stock THEN 40
            WHEN p.current_stock >= p.safe_stock * 0.5 THEN 30
            WHEN p.current_stock >= p.safe_stock * 0.3 THEN 20
            ELSE 10
        END +
        CASE 
            WHEN AVG(s.quantity) = 0 THEN 0
            WHEN SUM(s.quantity) / p.current_stock >= 1 THEN 30
            WHEN SUM(s.quantity) / p.current_stock >= 0.5 THEN 25
            WHEN SUM(s.quantity) / p.current_stock >= 0.2 THEN 15
            ELSE 5
        END +
        CASE 
            WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 20 THEN 30
            WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 50 THEN 20
            ELSE 10
        END) >= 60 THEN '良好'
        WHEN (CASE 
            WHEN p.current_stock >= p.safe_stock THEN 40
            WHEN p.current_stock >= p.safe_stock * 0.5 THEN 30
            WHEN p.current_stock >= p.safe_stock * 0.3 THEN 20
            ELSE 10
        END +
        CASE 
            WHEN AVG(s.quantity) = 0 THEN 0
            WHEN SUM(s.quantity) / p.current_stock >= 1 THEN 30
            WHEN SUM(s.quantity) / p.current_stock >= 0.5 THEN 25
            WHEN SUM(s.quantity) / p.current_stock >= 0.2 THEN 15
            ELSE 5
        END +
        CASE 
            WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 20 THEN 30
            WHEN STDDEV(s.quantity) / AVG(s.quantity) * 100 < 50 THEN 20
            ELSE 10
        END) >= 40 THEN '一般'
        ELSE '较差'
    END AS '健康度评级'
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, p.sku, p.product_name, p.current_stock, p.safe_stock
ORDER BY '健康度总分' DESC;
