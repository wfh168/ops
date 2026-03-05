package com.wfh.ecommerce.vo;

import lombok.Data;
import java.math.BigDecimal;

/**
 * 库存预警VO
 */
@Data
public class StockWarningVO {
    
    private String sku;
    
    private String productName;
    
    private Integer currentStock;
    
    private Integer safeStock;
    
    private BigDecimal avgDailySales;
    
    private BigDecimal availableDays;
    
    private String stockStatus;
    
    private Integer suggestedRestock;
}
