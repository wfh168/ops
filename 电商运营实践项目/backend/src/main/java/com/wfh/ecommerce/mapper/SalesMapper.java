package com.wfh.ecommerce.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.wfh.ecommerce.entity.Sales;
import com.wfh.ecommerce.vo.DailySalesVO;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 销售Mapper
 */
public interface SalesMapper extends BaseMapper<Sales> {
    
    /**
     * 每日销售趋势（最近7天）
     */
    @Select("SELECT " +
            "sale_date AS saleDate, " +
            "SUM(revenue) AS revenue, " +
            "SUM(quantity) AS quantity, " +
            "SUM(order_count) AS orderCount, " +
            "ROUND(SUM(revenue) / SUM(order_count), 2) AS avgOrderValue, " +
            "SUM(views) AS views, " +
            "ROUND(SUM(order_count) / SUM(views) * 100, 2) AS conversionRate " +
            "FROM sales " +
            "WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) " +
            "GROUP BY sale_date " +
            "ORDER BY sale_date DESC")
    List<DailySalesVO> getDailySalesTrend();
}
