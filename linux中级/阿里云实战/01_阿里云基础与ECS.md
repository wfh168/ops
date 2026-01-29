# 阿里云基础与 ECS

## 一、阿里云产品体系

### 1.1 阿里云简介

阿里云（Alibaba Cloud）是阿里巴巴集团旗下的云计算品牌，是全球领先的云计算及人工智能科技公司。

**核心优势**：
- 国内市场份额第一
- 全球数据中心覆盖
- 丰富的产品线
- 完善的技术支持
- 与阿里生态深度整合

### 1.2 核心产品

#### 计算服务
- **ECS**（Elastic Compute Service）：云服务器
- **ECI**（Elastic Container Instance）：弹性容器实例
- **ACK**（Container Service for Kubernetes）：容器服务
- **函数计算**：Serverless 计算

#### 存储服务
- **OSS**（Object Storage Service）：对象存储
- **NAS**（Network Attached Storage）：文件存储
- **云盘**：块存储

#### 网络服务
- **VPC**（Virtual Private Cloud）：专有网络
- **SLB**（Server Load Balancer）：负载均衡
- **EIP**（Elastic IP）：弹性公网 IP
- **NAT 网关**：网络地址转换
- **CDN**：内容分发网络

#### 数据库服务
- **RDS**（Relational Database Service）：关系型数据库
- **Redis**：云数据库 Redis 版
- **MongoDB**：云数据库 MongoDB 版
- **PolarDB**：云原生数据库

#### 安全服务
- **云安全中心**：安全态势管理
- **DDoS 防护**：DDoS 攻击防护
- **Web 应用防火墙**：WAF
- **SSL 证书**：HTTPS 证书管理

#### 监控运维
- **云监控**：资源监控和告警
- **日志服务**：日志收集和分析
- **运维编排**：自动化运维

---

## 二、账号注册和准备

### 2.1 注册阿里云账号

1. 访问阿里云官网：https://www.aliyun.com/
2. 点击"免费注册"
3. 使用手机号或邮箱注册
4. 设置登录密码

### 2.2 实名认证

**个人认证**：
1. 登录阿里云控制台
2. 进入"账号管理" → "实名认证"
3. 选择"个人认证"
4. 上传身份证照片
5. 进行人脸识别验证

**企业认证**：
1. 选择"企业认证"
2. 填写企业信息
3. 上传营业执照
4. 法人授权或对公打款验证

### 2.3 账号安全设置

```
1. 设置强密码
   - 至少 8 位
   - 包含大小写字母、数字、特殊字符

2. 启用 MFA（多因素认证）
   - 下载"阿里云"APP
   - 绑定虚拟 MFA 设备

3. 设置安全手机
   - 绑定手机号
   - 用于接收验证码

4. 创建 RAM 子账号
   - 不要使用主账号进行日常操作
   - 为不同人员创建不同权限的子账号
```

### 2.4 充值和优惠

```bash
# 充值方式
1. 支付宝充值
2. 银行卡充值
3. 对公转账

# 新用户优惠
1. 领取代金券（控制台首页）
2. 新用户专享价（ECS、RDS 等）
3. 免费试用（部分产品）

# 建议
- 学习阶段充值 100-200 元即可
- 使用按量付费，用完及时释放
- 充分利用代金券
```

---

## 三、ECS 云服务器

### 3.1 ECS 简介

ECS（Elastic Compute Service）是阿里云提供的云服务器服务，提供安全可靠、弹性扩展的计算能力。

**核心特性**：
- 弹性伸缩：随时增加或减少实例
- 多种规格：满足不同业务需求
- 按需付费：按量付费或包年包月
- 快速部署：几分钟内创建实例
- 高可用：99.95% 的服务可用性

### 3.2 实例规格族

| 规格族 | 适用场景 | 特点 |
|--------|----------|------|
| **通用型** | 中小型网站、应用 | CPU 和内存比例均衡 |
| **计算型** | 高性能计算、科学计算 | 高 CPU 性能 |
| **内存型** | 数据库、缓存 | 高内存容量 |
| **大数据型** | Hadoop、Spark | 高存储吞吐 |
| **GPU 型** | 深度学习、图形渲染 | GPU 加速 |
| **突发性能型** | 轻量级应用、开发测试 | 性价比高 ⭐ |

**学习推荐**：
- **ecs.t5-lc1m2.small**：1核2GB，突发性能型，性价比高
- **ecs.n4.small**：1核2GB，通用型
- **ecs.c6.large**：2核4GB，计算型

### 3.3 计费方式

#### 1. 按量付费（推荐学习使用）

```
特点：
- 按小时计费
- 随时创建和释放
- 适合短期使用

价格示例（华东1-杭州）：
- ecs.t5-lc1m2.small：0.06 元/小时
- ecs.n4.small：0.12 元/小时
```

#### 2. 包年包月

```
特点：
- 预付费
- 价格更优惠
- 适合长期使用

价格示例：
- ecs.t5-lc1m2.small：
  - 1个月：约 40 元
  - 1年：约 400 元（有折扣）
```

#### 3. 抢占式实例

```
特点：
- 价格最低（约 1 折）
- 可能被回收
- 适合无状态应用
```

---

## 四、创建 ECS 实例

### 4.1 通过控制台创建

#### 步骤1：进入 ECS 控制台

```
1. 登录阿里云控制台
2. 产品与服务 → 云服务器 ECS
3. 点击"创建实例"
```

#### 步骤2：选择配置

**基础配置**：
```
付费模式：按量付费
地域：华东1（杭州）
可用区：随机分配
实例规格：ecs.t5-lc1m2.small（1核2GB）
镜像：CentOS 7.9 64位
存储：40GB 高效云盘
```

**网络配置**：
```
网络类型：专有网络 VPC
专有网络：默认 VPC（或新建）
交换机：默认交换机
公网 IP：分配公网 IPv4 地址
带宽计费：按使用流量
峰值带宽：5 Mbps
```

**系统配置**：
```
登录凭证：自定义密码
实例名称：web-server-01
主机名：web-server-01
描述：Web 服务器
```

**分组设置**：
```
安全组：默认安全组（或新建）
```

#### 步骤3：确认订单

```
1. 勾选"《云服务器 ECS 服务条款》"
2. 点击"确认下单"
3. 等待实例创建（约 1-2 分钟）
```

### 4.2 通过 CLI 创建

#### 安装阿里云 CLI

```bash
# Linux/macOS
wget https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz
tar -zxvf aliyun-cli-linux-latest-amd64.tgz
sudo mv aliyun /usr/local/bin/

# 配置 CLI
aliyun configure
# 输入 AccessKey ID
# 输入 AccessKey Secret
# 输入默认地域 ID：cn-hangzhou
# 输入默认输出格式：json
```

#### 创建实例

```bash
# 创建 ECS 实例
aliyun ecs CreateInstance \
  --RegionId cn-hangzhou \
  --ImageId centos_7_9_x64_20G_alibase_20210318.vhd \
  --InstanceType ecs.t5-lc1m2.small \
  --SecurityGroupId sg-xxxxx \
  --VSwitchId vsw-xxxxx \
  --InstanceName web-server-01 \
  --Password 'YourPassword123!' \
  --InternetMaxBandwidthOut 5 \
  --InternetChargeType PayByTraffic

# 启动实例
aliyun ecs StartInstance --InstanceId i-xxxxx

# 查询实例
aliyun ecs DescribeInstances --InstanceIds '["i-xxxxx"]'
```

---

## 五、连接 ECS 实例

### 5.1 使用 SSH 连接（Linux/macOS）

```bash
# 获取公网 IP
# 在 ECS 控制台查看实例的公网 IP

# SSH 连接
ssh root@公网IP

# 首次连接会提示确认指纹
# 输入密码登录
```

### 5.2 使用 PuTTY 连接（Windows）

```
1. 下载 PuTTY：https://www.putty.org/
2. 打开 PuTTY
3. Host Name：输入公网 IP
4. Port：22
5. Connection type：SSH
6. 点击 Open
7. 输入用户名：root
8. 输入密码
```

### 5.3 使用密钥对连接

#### 创建密钥对

```bash
# 在 ECS 控制台创建密钥对
1. 网络与安全 → 密钥对
2. 创建密钥对
3. 下载私钥文件（.pem）

# 或使用 ssh-keygen 生成
ssh-keygen -t rsa -b 2048 -f ~/.ssh/aliyun_key
```

#### 绑定密钥对

```bash
# 在控制台将密钥对绑定到实例
1. 选择实例
2. 更多 → 密钥对 → 绑定密钥对
3. 重启实例
```

#### 使用密钥连接

```bash
# 设置私钥权限
chmod 400 ~/.ssh/aliyun_key.pem

# SSH 连接
ssh -i ~/.ssh/aliyun_key.pem root@公网IP
```

### 5.4 使用 VNC 连接

```
1. 在 ECS 控制台选择实例
2. 远程连接 → VNC 连接
3. 输入 VNC 密码（首次需要设置）
4. 进入系统控制台
```

---

## 六、安全组配置

### 6.1 安全组概念

安全组是一种虚拟防火墙，用于控制 ECS 实例的入站和出站流量。

**规则类型**：
- **入方向**：控制外部访问 ECS 的流量
- **出方向**：控制 ECS 访问外部的流量

### 6.2 默认安全组规则

```
入方向：
- 允许 SSH（22）：0.0.0.0/0
- 允许 RDP（3389）：0.0.0.0/0（Windows）
- 允许 ICMP：0.0.0.0/0

出方向：
- 允许所有：0.0.0.0/0
```

### 6.3 添加安全组规则

#### 通过控制台添加

```
1. ECS 控制台 → 网络与安全 → 安全组
2. 选择安全组 → 配置规则
3. 添加安全组规则

示例：允许 HTTP 访问
- 规则方向：入方向
- 授权策略：允许
- 协议类型：TCP
- 端口范围：80/80
- 授权对象：0.0.0.0/0
- 描述：允许 HTTP 访问
```

#### 常用规则配置

```bash
# Web 服务器
HTTP：TCP 80
HTTPS：TCP 443

# 数据库
MySQL：TCP 3306
Redis：TCP 6379
MongoDB：TCP 27017

# 应用服务器
Tomcat：TCP 8080
Node.js：TCP 3000

# 管理服务
SSH：TCP 22
FTP：TCP 21
```

### 6.4 安全组最佳实践

```
1. 最小权限原则
   - 只开放必要的端口
   - 限制授权对象范围

2. 使用安全组模板
   - Web 服务器模板
   - 数据库服务器模板

3. 定期审查规则
   - 删除不用的规则
   - 更新授权对象

4. 使用多个安全组
   - 前端服务器安全组
   - 后端服务器安全组
   - 数据库服务器安全组
```

---

## 七、快照和镜像

### 7.1 快照管理

快照是某一时间点云盘数据的备份。

#### 创建快照

```bash
# 通过控制台
1. 存储与快照 → 云盘
2. 选择云盘 → 创建快照
3. 输入快照名称
4. 点击确定

# 通过 CLI
aliyun ecs CreateSnapshot \
  --DiskId d-xxxxx \
  --SnapshotName backup-20240129
```

#### 自动快照策略

```
1. 存储与快照 → 自动快照策略
2. 创建策略
   - 策略名称：daily-backup
   - 创建时间：每天 02:00
   - 重复日期：周一到周日
   - 保留时间：7 天
3. 应用到云盘
```

#### 从快照恢复

```bash
# 回滚云盘
1. 选择快照
2. 回滚云盘
3. 确认操作

# 注意：回滚会丢失快照之后的数据
```

### 7.2 自定义镜像

镜像是 ECS 实例的模板，包含操作系统和应用程序。

#### 创建自定义镜像

```bash
# 准备工作
1. 安装和配置应用程序
2. 清理临时文件和日志
3. 删除敏感信息

# 创建镜像
1. 选择实例
2. 更多 → 云盘和镜像 → 创建自定义镜像
3. 输入镜像名称和描述
4. 点击创建

# 通过 CLI
aliyun ecs CreateImage \
  --InstanceId i-xxxxx \
  --ImageName lnmp-image \
  --Description "LNMP 环境镜像"
```

#### 使用自定义镜像

```bash
# 创建实例时选择自定义镜像
1. 创建实例
2. 镜像 → 自定义镜像
3. 选择你的镜像
4. 完成创建
```

#### 共享镜像

```bash
# 共享给其他账号
1. 镜像 → 自定义镜像
2. 选择镜像 → 共享镜像
3. 输入目标账号 ID
4. 点击共享
```

---

## 八、实战练习

### 练习1：创建 ECS 实例

1. 注册阿里云账号并完成实名认证
2. 创建一台 ECS 实例（1核2GB）
3. 配置安全组，开放 22、80、443 端口
4. 使用 SSH 连接到实例
5. 安装 Nginx 并测试访问

### 练习2：配置 LNMP 环境

1. 在 ECS 上安装 Nginx
2. 安装 MySQL 8.0
3. 安装 PHP 7.4
4. 部署一个 PHP 测试页面
5. 创建自定义镜像

### 练习3：快照和恢复

1. 创建云盘快照
2. 配置自动快照策略
3. 修改系统文件
4. 从快照恢复

---

## 九、常见问题

### 9.1 无法连接 ECS

**排查步骤**：
```bash
# 1. 检查实例状态
# 确保实例处于"运行中"状态

# 2. 检查安全组
# 确保开放了 22 端口

# 3. 检查公网 IP
# 确保实例有公网 IP

# 4. 使用 VNC 连接
# 通过 VNC 检查系统状态

# 5. 检查 SSH 服务
systemctl status sshd
```

### 9.2 忘记密码

**解决方法**：
```
1. 停止实例
2. 更多 → 密码/密钥 → 重置实例密码
3. 输入新密码
4. 重启实例
```

### 9.3 磁盘空间不足

**解决方法**：
```bash
# 1. 清理日志和临时文件
du -sh /* | sort -rh | head -10
rm -rf /tmp/*
journalctl --vacuum-time=7d

# 2. 扩容云盘
# 在控制台扩容云盘
# 然后在系统内扩展文件系统
growpart /dev/vda 1
resize2fs /dev/vda1  # ext4
xfs_growfs /dev/vda1  # xfs
```

---

## 十、总结

本节学习了：

✅ 阿里云产品体系  
✅ 账号注册和安全设置  
✅ ECS 实例规格和计费  
✅ 创建和连接 ECS 实例  
✅ 安全组配置  
✅ 快照和镜像管理  
✅ 常见问题排查  

**下一节**：学习 SLB 负载均衡和 RDS 数据库配置。

---

## 参考资料

- [ECS 产品文档](https://help.aliyun.com/product/25365.html)
- [ECS 最佳实践](https://help.aliyun.com/document_detail/25430.html)
- [阿里云 CLI 文档](https://help.aliyun.com/document_detail/110244.html)
