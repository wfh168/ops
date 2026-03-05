package com.wfh.ecommerce.controller;

import com.wfh.ecommerce.service.AnalysisService;
import com.wfh.ecommerce.vo.DailySalesVO;
import com.wfh.ecommerce.vo.ProductAnalysisVO;
import com.wfh.ecommerce.vo.StockWarningVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 数据分析控制器
 */
@RestController
@RequestMapping("/api/analysis")
@CrossOrigin(origins = "*")
public class AnalysisController {
    
    @Autowired
    private AnalysisService analysisService;
    
    /**
     * 获取产品销售分析
     */
    @GetMapping("/products")
    public Map<String, Object> getProductAnalysis() {
        List<ProductAnalysisVO> data = analysisService.getProductAnalysis();
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        result.put("data", data);
        return result;
    }
    
    /**
     * 获取每日销售趋势
     */
    @GetMapping("/sales/daily")
    public Map<String, Object> getDailySalesTrend() {
        List<DailySalesVO> data = analysisService.getDailySalesTrend();
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        result.put("data", data);
        return result;
    }
    
    /**
     * 获取库存预警
     */
    @GetMapping("/stock/warning")
    public Map<String, Object> getStockWarning() {
        List<StockWarningVO> data = analysisService.getStockWarning();
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        result.put("data", data);
        return result;
    }
    
    /**
     * 健康检查
     */
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "系统运行正常");
        result.put("timestamp", System.currentTimeMillis());
        return result;
    }
}
