package com.wfh.ecommerce.vo;

import lombok.Data;
import java.math.BigDecimal;

/**
 * 每日销售VO
 */
@Data
public class DailySalesVO {
    
    private String saleDate;
    
    private BigDecimal revenue;
    
    private Integer quantity;
    
    private Integer orderCount;
    
    private BigDecimal avgOrderValue;
    
    private Integer views;
    
    private BigDecimal conversionRate;
}
