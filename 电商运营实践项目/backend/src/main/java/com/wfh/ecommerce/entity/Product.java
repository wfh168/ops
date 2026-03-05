package com.wfh.ecommerce.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 产品实体类
 */
@Data
@TableName("products")
public class Product {
    
    @TableId(type = IdType.AUTO)
    private Integer productId;
    
    private String sku;
    
    private String productName;
    
    private String category;
    
    private BigDecimal price;
    
    private BigDecimal cost;
    
    private Integer currentStock;
    
    private Integer safeStock;
    
    private String status;
    
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;
}
