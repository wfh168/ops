package com.wfh.ecommerce.vo;

import lombok.Data;
import java.math.BigDecimal;

/**
 * 产品分析VO
 */
@Data
public class ProductAnalysisVO {
    
    private String sku;
    
    private String productName;
    
    private BigDecimal price;
    
    private Integer totalSales;
    
    private BigDecimal totalRevenue;
    
    private Integer totalOrders;
    
    private BigDecimal avgOrderValue;
    
    private Integer totalViews;
    
    private BigDecimal conversionRate;
    
    private BigDecimal profit;
    
    private BigDecimal profitRate;
}
