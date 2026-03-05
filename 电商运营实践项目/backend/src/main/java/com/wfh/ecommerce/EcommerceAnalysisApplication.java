package com.wfh.ecommerce;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 电商数据分析系统启动类
 * @author 吴付红
 */
@SpringBootApplication
@MapperScan("com.wfh.ecommerce.mapper")
public class EcommerceAnalysisApplication {

    public static void main(String[] args) {
        SpringApplication.run(EcommerceAnalysisApplication.class, args);
        System.out.println("========================================");
        System.out.println("电商数据分析系统启动成功！");
        System.out.println("访问地址: http://localhost:8080");
        System.out.println("========================================");
    }
}
