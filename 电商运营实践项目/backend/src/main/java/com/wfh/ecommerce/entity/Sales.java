package com.wfh.ecommerce.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 销售记录实体类
 */
@Data
@TableName("sales")
public class Sales {
    
    @TableId(type = IdType.AUTO)
    private Integer saleId;
    
    private Integer productId;
    
    private LocalDate saleDate;
    
    private Integer quantity;
    
    private BigDecimal revenue;
    
    private Integer orderCount;
    
    private Integer views;
    
    private LocalDateTime createdAt;
}
