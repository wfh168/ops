# 电商数据分析系统

## 项目简介

这是一个完整的电商数据分析系统，包含后端API和前端可视化界面。模拟亚马逊产品运营场景，实现产品数据管理、销售数据统计、库存预警、竞品分析等核心功能。

**🎯 项目亮点**：
- ✅ 完整的前后端分离架构
- ✅ 真实可运行的Spring Boot项目
- ✅ 精美的数据可视化界面
- ✅ 20+ 条实用SQL查询
- ✅ 可直接用于面试展示

## 技术栈

### 后端
- **Spring Boot 2.7.18**: 快速开发框架
- **MyBatis Plus 3.5.3**: ORM框架
- **MySQL 8.0**: 关系型数据库
- **Lombok**: 简化Java代码

### 前端
- **Vue 2.6**: JavaScript框架
- **ECharts 5.4**: 数据可视化
- **Axios**: HTTP客户端

## 项目结构

```
电商运营实践项目/
├── backend/                          # Spring Boot 后端
│   ├── pom.xml                       # Maven配置
│   └── src/main/
│       ├── java/com/wfh/ecommerce/
│       │   ├── EcommerceAnalysisApplication.java  # 启动类
│       │   ├── entity/               # 实体类
│       │   ├── vo/                   # 视图对象
│       │   ├── mapper/               # 数据访问层
│       │   ├── service/              # 业务逻辑层
│       │   └── controller/           # 控制器
│       └── resources/
│           └── application.yml       # 配置文件
├── frontend/                         # Vue 前端
│   └── index.html                    # 单页面应用
├── database/                         # 数据库脚本
│   ├── schema.sql                    # 表结构
│   └── sample_data.sql               # 示例数据
├── sql-queries/                      # SQL查询集合
│   ├── 01_产品分析.sql
│   ├── 02_销售分析.sql
│   ├── 03_库存分析.sql
│   └── 04_竞品分析.sql
├── reports/                          # 报表模板
│   └── 每日运营报表模板.md
├── README.md                         # 项目说明
├── 启动指南.md                       # 详细启动说明
└── 快速开始指南.md                   # SQL查询使用指南
```

## 核心功能

### 1. 产品数据管理
- 产品基本信息（SKU、名称、分类、价格）
- 产品状态管理（在售、缺货、下架）
- 产品标签和分类

### 2. 销售数据分析
- 每日/每周/每月销售统计
- 销售额、销量、订单数分析
- 转化率、客单价计算
- 同比、环比增长分析

### 3. 库存预警系统
- 当前库存监控
- 安全库存预警
- 库存周转率计算
- 智能补货建议

### 4. 竞品分析
- 竞品价格对比
- 竞品销量对比
- 市场份额分析
- 价格竞争力分析

### 5. 数据可视化
- ECharts 图表展示
- 产品销售额对比图
- 销售趋势折线图
- 实时数据刷新

## 数据模型

### 产品表 (products)
- 产品ID、SKU、产品名称、分类、价格、成本、库存、状态

### 销售记录表 (sales)
- 销售ID、产品ID、销售日期、销量、销售额、订单数

### 竞品表 (competitors)
- 竞品ID、竞品名称、对应产品ID、价格、销量估算

### 库存记录表 (inventory_logs)
- 记录ID、产品ID、日期、库存数量、入库/出库

## 快速开始（3步）

### 第1步：创建数据库
```bash
mysql -u root -p < database/schema.sql
mysql -u root -p ecommerce_analysis < database/sample_data.sql
```

### 第2步：启动后端
```bash
cd backend
mvn spring-boot:run
```

### 第3步：打开前端
用浏览器打开 `frontend/index.html`

**详细启动说明请查看**: [启动指南.md](启动指南.md)

## 功能展示

### 📊 数据概览
- 总销售额、总订单数统计
- 平均转化率分析
- 库存预警数量

### 📦 产品分析
- 产品销售排行
- 利润分析
- 转化率分析
- 销售额对比图表

### 💰 销售趋势
- 每日销售数据
- 销售趋势折线图
- 订单数趋势分析

### ⚠️ 库存预警
- 库存预警列表
- 可售天数计算
- 智能补货建议

## 项目亮点

1. **完整的前后端分离架构**: Spring Boot RESTful API + Vue前端
2. **真实业务场景**: 模拟亚马逊运营的真实数据分析需求
3. **完整数据模型**: 涵盖产品、销售、库存、竞品四大核心模块
4. **实用SQL查询**: 20+ 条实用的数据分析SQL，可直接用于工作
5. **数据可视化**: ECharts图表，直观展示数据趋势
6. **自动化思维**: 可扩展为定时任务，自动生成每日报表
7. **可直接运行**: 完整的示例数据，开箱即用

## API接口

### 1. 产品销售分析
```
GET http://localhost:8080/api/analysis/products
```

### 2. 每日销售趋势
```
GET http://localhost:8080/api/analysis/sales/daily
```

### 3. 库存预警
```
GET http://localhost:8080/api/analysis/stock/warning
```

### 4. 健康检查
```
GET http://localhost:8080/api/analysis/health
```

## 学习成果

通过这个项目，你将掌握：
- ✅ Spring Boot + MyBatis Plus 开发
- ✅ RESTful API 设计
- ✅ 电商运营的核心指标和数据模型
- ✅ 复杂的 SQL 数据分析查询（窗口函数、多表关联）
- ✅ Vue + ECharts 数据可视化
- ✅ 前后端分离架构
- ✅ 库存管理和预警机制
- ✅ 竞品分析的方法论
- ✅ 数据驱动的运营决策思维

## 截图展示

### 数据概览
![数据概览](screenshots/overview.png)

### 产品分析
![产品分析](screenshots/products.png)

### 销售趋势
![销售趋势](screenshots/sales.png)

### 库存预警
![库存预警](screenshots/stock.png)

## 面试演示建议

1. **启动项目**: 展示完整的启动流程（3步启动）
2. **功能演示**: 
   - 数据概览：展示核心指标
   - 产品分析：展示销售排行和图表
   - 销售趋势：展示趋势图
   - 库存预警：展示预警列表
3. **代码讲解**: 
   - 后端：SQL查询、MyBatis Plus使用、RESTful API设计
   - 前端：Vue数据绑定、ECharts图表、Axios请求
4. **技术亮点**: 
   - 复杂SQL查询（窗口函数、CASE WHEN、多表关联）
   - 前后端分离架构
   - 数据可视化
   - 运营思维（不只是技术，还有业务分析）

## 下一步计划

- [ ] 添加用户认证功能
- [ ] 实现数据导出（Excel）
- [ ] 添加更多图表类型（饼图、雷达图）
- [ ] 实现实时数据推送（WebSocket）
- [ ] 添加移动端适配
- [ ] 集成 Prometheus、Grafana 监控
- [ ] 添加价格优化建议算法
- [ ] 实现自动化库存补货建议

## 联系方式

- **作者**: 吴付红
- **邮箱**: wu2740461899@163.com
- **GitHub**: https://github.com/wfh168

---

**如果这个项目对你有帮助，请给个 Star ⭐️**
