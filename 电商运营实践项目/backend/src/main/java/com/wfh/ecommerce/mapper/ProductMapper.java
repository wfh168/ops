package com.wfh.ecommerce.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.wfh.ecommerce.entity.Product;
import com.wfh.ecommerce.vo.ProductAnalysisVO;
import com.wfh.ecommerce.vo.StockWarningVO;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 产品Mapper
 */
public interface ProductMapper extends BaseMapper<Product> {
    
    /**
     * 产品销售分析（最近7天）
     */
    @Select("SELECT " +
            "p.sku, " +
            "p.product_name AS productName, " +
            "p.price, " +
            "SUM(s.quantity) AS totalSales, " +
            "SUM(s.revenue) AS totalRevenue, " +
            "SUM(s.order_count) AS totalOrders, " +
            "ROUND(SUM(s.revenue) / SUM(s.order_count), 2) AS avgOrderValue, " +
            "SUM(s.views) AS totalViews, " +
            "ROUND(SUM(s.order_count) / SUM(s.views) * 100, 2) AS conversionRate, " +
            "SUM(s.revenue) - SUM(s.quantity * p.cost) AS profit, " +
            "ROUND((SUM(s.revenue) - SUM(s.quantity * p.cost)) / SUM(s.revenue) * 100, 2) AS profitRate " +
            "FROM products p " +
            "LEFT JOIN sales s ON p.product_id = s.product_id " +
            "WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) " +
            "GROUP BY p.product_id, p.sku, p.product_name, p.price " +
            "ORDER BY totalRevenue DESC")
    List<ProductAnalysisVO> getProductAnalysis();
    
    /**
     * 库存预警
     */
    @Select("SELECT " +
            "p.sku, " +
            "p.product_name AS productName, " +
            "p.current_stock AS currentStock, " +
            "p.safe_stock AS safeStock, " +
            "ROUND(AVG(s.quantity), 2) AS avgDailySales, " +
            "CASE " +
            "  WHEN AVG(s.quantity) = 0 THEN 0 " +
            "  ELSE ROUND(p.current_stock / AVG(s.quantity), 1) " +
            "END AS availableDays, " +
            "CASE " +
            "  WHEN p.current_stock = 0 THEN '紧急缺货' " +
            "  WHEN p.current_stock < p.safe_stock * 0.3 THEN '严重不足' " +
            "  WHEN p.current_stock < p.safe_stock * 0.5 THEN '库存偏低' " +
            "  WHEN p.current_stock < p.safe_stock THEN '需要补货' " +
            "  WHEN p.current_stock > p.safe_stock * 3 THEN '库存过多' " +
            "  ELSE '库存正常' " +
            "END AS stockStatus, " +
            "CASE " +
            "  WHEN AVG(s.quantity) * 30 > p.current_stock THEN " +
            "    ROUND(AVG(s.quantity) * 30 - p.current_stock + p.safe_stock, 0) " +
            "  ELSE 0 " +
            "END AS suggestedRestock " +
            "FROM products p " +
            "LEFT JOIN sales s ON p.product_id = s.product_id " +
            "WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) " +
            "GROUP BY p.product_id, p.sku, p.product_name, p.current_stock, p.safe_stock " +
            "ORDER BY " +
            "CASE " +
            "  WHEN p.current_stock = 0 THEN 1 " +
            "  WHEN p.current_stock < p.safe_stock * 0.3 THEN 2 " +
            "  WHEN p.current_stock < p.safe_stock * 0.5 THEN 3 " +
            "  WHEN p.current_stock < p.safe_stock THEN 4 " +
            "  ELSE 5 " +
            "END")
    List<StockWarningVO> getStockWarning();
}
