package com.wfh.ecommerce.service;

import com.wfh.ecommerce.mapper.ProductMapper;
import com.wfh.ecommerce.mapper.SalesMapper;
import com.wfh.ecommerce.vo.DailySalesVO;
import com.wfh.ecommerce.vo.ProductAnalysisVO;
import com.wfh.ecommerce.vo.StockWarningVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 数据分析服务
 */
@Service
public class AnalysisService {
    
    @Autowired
    private ProductMapper productMapper;
    
    @Autowired
    private SalesMapper salesMapper;
    
    /**
     * 获取产品销售分析
     */
    public List<ProductAnalysisVO> getProductAnalysis() {
        return productMapper.getProductAnalysis();
    }
    
    /**
     * 获取每日销售趋势
     */
    public List<DailySalesVO> getDailySalesTrend() {
        return salesMapper.getDailySalesTrend();
    }
    
    /**
     * 获取库存预警
     */
    public List<StockWarningVO> getStockWarning() {
        return productMapper.getStockWarning();
    }
}
