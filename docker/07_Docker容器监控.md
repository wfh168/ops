# 07 - Docker 容器监控

## 📚 本节目标

- 掌握容器资源监控
- 使用 Prometheus 监控
- 配置 Grafana 可视化
- 实现日志收集
- 掌握性能优化
- 配置告警通知

---

## 1. 容器监控基础

### 1.1 为什么需要监控

```
✅ 了解资源使用情况
✅ 及时发现性能问题
✅ 预防故障发生
✅ 优化资源分配
✅ 故障快速定位
```

### 1.2 监控指标

**容器指标**：
- CPU 使用率
- 内存使用量
- 网络 I/O
- 磁盘 I/O
- 容器状态

**应用指标**：
- 请求数量
- 响应时间
- 错误率
- 并发连接数

---

## 2. Docker 原生监控

### 2.1 docker stats

```bash
# 查看所有容器资源使用
docker stats

# 查看指定容器
docker stats nginx mysql

# 不持续刷新
docker stats --no-stream

# 格式化输出
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

**输出说明**：
```
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O         PIDS
abc123         nginx     0.50%     10.5MiB / 2GiB       0.51%     1.2kB / 648B      0B / 0B           2
```

### 2.2 docker top

```bash
# 查看容器内进程
docker top nginx

# 查看详细信息
docker top nginx aux
```

### 2.3 docker inspect

```bash
# 查看容器详细信息
docker inspect nginx

# 查看特定字段
docker inspect --format='{{.State.Status}}' nginx
docker inspect --format='{{.NetworkSettings.IPAddress}}' nginx
docker inspect --format='{{.HostConfig.Memory}}' nginx
```

---

## 3. Prometheus 监控

### 3.1 Prometheus 简介

Prometheus 是开源的监控和告警系统。

**核心组件**：
```
Prometheus Server：数据采集和存储
Exporters：指标导出器
Alertmanager：告警管理
Grafana：数据可视化
```

### 3.2 部署 Prometheus

**docker-compose.yml**：
```yaml
version: '3'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    restart: always

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    restart: always

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: always

volumes:
  prometheus-data:
```

**prometheus.yml**：
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Prometheus 自身
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter（主机监控）
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  # cAdvisor（容器监控）
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
```

**启动监控**：
```bash
docker-compose up -d

# 访问 Prometheus
# http://localhost:9090

# 访问 cAdvisor
# http://localhost:8080
```

### 3.3 常用 PromQL 查询

```promql
# CPU 使用率
rate(container_cpu_usage_seconds_total[5m])

# 内存使用量
container_memory_usage_bytes

# 网络接收字节数
rate(container_network_receive_bytes_total[5m])

# 网络发送字节数
rate(container_network_transmit_bytes_total[5m])

# 磁盘读取字节数
rate(container_fs_reads_bytes_total[5m])

# 磁盘写入字节数
rate(container_fs_writes_bytes_total[5m])
```

---

## 4. Grafana 可视化

### 4.1 部署 Grafana

**添加到 docker-compose.yml**：
```yaml
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    restart: always
    depends_on:
      - prometheus

volumes:
  grafana-data:
```

**启动 Grafana**：
```bash
docker-compose up -d grafana

# 访问 Grafana
# http://localhost:3000
# 用户名: admin
# 密码: admin
```

### 4.2 配置数据源

1. 登录 Grafana
2. 点击"Configuration" → "Data Sources"
3. 点击"Add data source"
4. 选择"Prometheus"
5. 配置 URL：`http://prometheus:9090`
6. 点击"Save & Test"

### 4.3 导入仪表板

**导入 Docker 监控仪表板**：
1. 点击"+" → "Import"
2. 输入仪表板 ID：`193`（Docker 监控）
3. 选择 Prometheus 数据源
4. 点击"Import"

**常用仪表板 ID**：
```
193: Docker 监控
1860: Node Exporter Full
8919: Docker 和系统监控
```

### 4.4 自定义仪表板

**创建面板**：
```
1. 点击"+" → "Dashboard"
2. 点击"Add new panel"
3. 输入 PromQL 查询
4. 选择可视化类型（图表、仪表盘、表格等）
5. 配置面板标题和描述
6. 点击"Apply"
```

**示例面板配置**：
```
标题: 容器 CPU 使用率
查询: rate(container_cpu_usage_seconds_total{name=~".*"}[5m]) * 100
可视化: Time series
单位: percent (0-100)
```

---

## 5. 日志管理

### 5.1 查看容器日志

```bash
# 查看日志
docker logs nginx

# 实时查看日志
docker logs -f nginx

# 查看最后 100 行
docker logs --tail 100 nginx

# 查看指定时间的日志
docker logs --since 2024-01-01T00:00:00 nginx
docker logs --until 2024-01-01T23:59:59 nginx

# 显示时间戳
docker logs -t nginx
```

### 5.2 日志驱动

**配置日志驱动**：
```bash
# 运行容器时指定
docker run -d \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    nginx

# 全局配置 /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

**日志驱动类型**：
- `json-file`：默认，JSON 格式
- `syslog`：系统日志
- `journald`：systemd 日志
- `gelf`：Graylog
- `fluentd`：Fluentd
- `awslogs`：AWS CloudWatch

### 5.3 ELK 日志收集

**docker-compose.yml**：
```yaml
version: '3'

services:
  elasticsearch:
    image: elasticsearch:7.17.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - es-data:/usr/share/elasticsearch/data

  logstash:
    image: logstash:7.17.0
    container_name: logstash
    ports:
      - "5000:5000"
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    depends_on:
      - elasticsearch

  kibana:
    image: kibana:7.17.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  es-data:
```

**logstash.conf**：
```
input {
  gelf {
    port => 5000
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "docker-logs-%{+YYYY.MM.dd}"
  }
}
```

**配置容器使用 GELF 日志**：
```bash
docker run -d \
    --log-driver=gelf \
    --log-opt gelf-address=udp://localhost:5000 \
    --log-opt tag="nginx" \
    nginx
```

---

## 6. 告警配置

### 6.1 Alertmanager 部署

**添加到 docker-compose.yml**：
```yaml
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
    restart: always
```

**alertmanager.yml**：
```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'email'

receivers:
  - name: 'email'
    email_configs:
      - to: 'admin@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'alertmanager@example.com'
        auth_password: 'password'
```

### 6.2 告警规则

**alert.rules.yml**：
```yaml
groups:
  - name: container_alerts
    interval: 30s
    rules:
      # 容器停止告警
      - alert: ContainerDown
        expr: up{job="cadvisor"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Container {{ $labels.instance }} is down"
          description: "Container has been down for more than 1 minute"

      # CPU 使用率过高
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.name }}"
          description: "CPU usage is above 80% for 5 minutes"

      # 内存使用率过高
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.name }}"
          description: "Memory usage is above 80% for 5 minutes"
```

**更新 prometheus.yml**：
```yaml
rule_files:
  - "alert.rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

---

## 7. 性能优化

### 7.1 资源限制

```bash
# 限制 CPU
docker run -d --cpus="1.5" nginx

# 限制内存
docker run -d --memory="512m" nginx

# 限制内存和交换空间
docker run -d --memory="512m" --memory-swap="1g" nginx

# CPU 权重
docker run -d --cpu-shares=512 nginx
```

### 7.2 监控资源使用

```bash
# 实时监控
docker stats

# 查看容器配置
docker inspect --format='{{.HostConfig.Memory}}' nginx
docker inspect --format='{{.HostConfig.NanoCpus}}' nginx
```

### 7.3 优化建议

```
✅ 设置合理的资源限制
✅ 使用精简的基础镜像
✅ 清理不必要的文件
✅ 使用多阶段构建
✅ 配置健康检查
✅ 使用数据卷持久化
✅ 定期清理未使用的资源
```

---

## 8. 实战案例

### 案例1：完整监控系统

**目录结构**：
```
monitoring/
├── docker-compose.yml
├── prometheus.yml
├── alert.rules.yml
├── alertmanager.yml
└── grafana/
    └── dashboards/
```

**部署命令**：
```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 访问服务
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000
# Alertmanager: http://localhost:9093
```

### 案例2：应用监控

**Python 应用示例**：
```python
# app.py
from flask import Flask
from prometheus_client import Counter, Histogram, generate_latest

app = Flask(__name__)

# 定义指标
REQUEST_COUNT = Counter('app_requests_total', 'Total requests')
REQUEST_LATENCY = Histogram('app_request_latency_seconds', 'Request latency')

@app.route('/')
@REQUEST_LATENCY.time()
def index():
    REQUEST_COUNT.inc()
    return 'Hello Docker!'

@app.route('/metrics')
def metrics():
    return generate_latest()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Prometheus 配置**：
```yaml
scrape_configs:
  - job_name: 'myapp'
    static_configs:
      - targets: ['myapp:5000']
```

---

## 9. 练习题

### 练习1：基础监控
使用 docker stats 监控容器资源使用情况。

### 练习2：Prometheus 监控
部署 Prometheus + Grafana 监控系统。

### 练习3：日志收集
搭建 ELK 日志收集系统。

### 练习4：告警配置
配置容器 CPU 和内存使用率告警。

---

## 📝 本节总结

### 核心要点

1. **原生监控**：docker stats、docker top
2. **Prometheus**：指标采集和存储
3. **Grafana**：数据可视化
4. **日志管理**：ELK、日志驱动
5. **告警配置**：Alertmanager

### 最佳实践

```
✅ 使用 Prometheus + Grafana 监控
✅ 配置合理的告警规则
✅ 集中管理容器日志
✅ 设置资源限制
✅ 定期查看监控数据
✅ 优化容器性能
```

### 下一步

学习完容器监控后，继续学习：
- Docker 实战应用部署
- Kubernetes 容器编排
- 微服务架构

---

**掌握容器监控，保障应用稳定运行！** 🚀
