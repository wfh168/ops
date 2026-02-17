# Ubuntu 22.04.3 Server 安装与系统优化指南

## 目录
1. [系统安装](#系统安装)
2. [基础配置](#基础配置)
3. [系统优化](#系统优化)
4. [安全加固](#安全加固)
5. [性能监控](#性能监控)

## 系统安装

### 1. 准备工作

#### 下载镜像
```bash
# 官方下载地址
wget https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso

# 华为云镜像（国内推荐）
wget http://mirrors.huaweicloud.com/repository/ubuntu/ubuntu-22.04.3-live-server-amd64.iso
```

#### 制作启动盘
```bash
# Linux下使用dd命令
sudo dd if=ubuntu-22.04.3-live-server-amd64.iso of=/dev/sdX bs=4M status=progress

# 或使用Rufus（Windows）、Etcher（跨平台）等工具
```

### 2. 安装步骤

#### 启动安装程序
1. 从USB启动，选择"Try or Install Ubuntu Server"
2. 选择语言：English（推荐）或中文
3. 选择键盘布局：English (US)

#### 网络配置
```bash
# 如果使用DHCP，系统会自动获取IP
# 如果需要静态IP，在安装时配置或安装后修改
```

#### 磁盘分区（推荐方案）
```bash
# 生产环境推荐分区方案
/boot     - 1GB   (ext4)
/         - 20GB  (ext4)
/var      - 10GB  (ext4)
/home     - 10GB  (ext4)
/tmp      - 2GB   (ext4)
swap      - 内存的1-2倍
剩余空间  - /data (ext4) 或 LVM
```

#### 用户配置
- 创建管理员用户
- 设置强密码
- 启用SSH服务器

## 基础配置

### 1. 系统更新
```bash
# 更新软件包列表
sudo apt update

# 升级系统
sudo apt upgrade -y

# 安装必要工具
sudo apt install -y vim curl wget git htop tree net-tools
```

### 2. 配置软件源（使用华为云镜像）
```bash
# 备份原始源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 配置华为云镜像源
sudo tee /etc/apt/sources.list << 'EOF'
deb http://mirrors.huaweicloud.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ jammy-security main restricted universe multiverse
EOF

# 更新软件包列表
sudo apt update
```

### 3. 时区和时间同步
```bash
# 设置时区
sudo timedatectl set-timezone Asia/Shanghai

# 安装和配置NTP
sudo apt install -y chrony
sudo systemctl enable chrony
sudo systemctl start chrony

# 验证时间同步
timedatectl status
```

### 4. 主机名配置
```bash
# 设置主机名
sudo hostnamectl set-hostname your-server-name

# 编辑hosts文件
sudo vim /etc/hosts
# 添加：
# 127.0.0.1 your-server-name
```

## 系统优化

### 1. 内核参数优化
```bash
# 创建系统优化配置文件
sudo tee /etc/sysctl.d/99-optimization.conf << 'EOF'
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr

# 文件系统优化
fs.file-max = 1000000
fs.inotify.max_user_watches = 524288

# 内存管理优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# 安全优化
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# 进程优化
kernel.pid_max = 4194304
EOF

# 应用配置
sudo sysctl -p /etc/sysctl.d/99-optimization.conf
```

### 2. 系统限制优化
```bash
# 配置系统限制
sudo tee /etc/security/limits.d/99-optimization.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
root soft nofile 65535
root hard nofile 65535
root soft nproc 65535
root hard nproc 65535
EOF

# 配置systemd限制
sudo mkdir -p /etc/systemd/system.conf.d
sudo tee /etc/systemd/system.conf.d/limits.conf << 'EOF'
[Manager]
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
EOF
```

### 3. 磁盘I/O优化
```bash
# 配置磁盘调度器
echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"' | sudo tee /etc/udev/rules.d/60-ioschedulers.rules

# 配置文件系统挂载选项
sudo cp /etc/fstab /etc/fstab.backup
# 在/etc/fstab中为ext4文件系统添加noatime选项
# 例如：/dev/sda1 / ext4 defaults,noatime 0 1
```

### 4. 服务优化
```bash
# 禁用不必要的服务
sudo systemctl disable snapd
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon

# 启用必要的服务
sudo systemctl enable ssh
sudo systemctl enable cron
sudo systemctl enable rsyslog
```

## 安全加固

### 1. SSH安全配置
```bash
# 备份SSH配置
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# 优化SSH配置
sudo tee -a /etc/ssh/sshd_config << 'EOF'

# 安全配置
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10
EOF

# 重启SSH服务
sudo systemctl restart ssh
```

### 2. 防火墙配置
```bash
# 安装和配置UFW
sudo apt install -y ufw

# 默认策略
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 允许SSH
sudo ufw allow ssh

# 启用防火墙
sudo ufw enable

# 查看状态
sudo ufw status verbose
```

### 3. 自动安全更新
```bash
# 安装自动更新
sudo apt install -y unattended-upgrades

# 配置自动更新
sudo dpkg-reconfigure -plow unattended-upgrades

# 编辑配置文件
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
```

## 性能监控

### 1. 安装监控工具
```bash
# 安装系统监控工具
sudo apt install -y htop iotop nethogs iftop sysstat

# 启用sysstat
sudo systemctl enable sysstat
sudo systemctl start sysstat
```

### 2. 配置日志轮转
```bash
# 配置系统日志轮转
sudo tee /etc/logrotate.d/system-optimization << 'EOF'
/var/log/syslog {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 syslog adm
}
EOF
```

### 3. 系统信息脚本
```bash
# 创建系统信息查看脚本
sudo tee /usr/local/bin/sysinfo << 'EOF'
#!/bin/bash
echo "=== 系统信息 ==="
echo "主机名: $(hostname)"
echo "系统版本: $(lsb_release -d | cut -f2)"
echo "内核版本: $(uname -r)"
echo "运行时间: $(uptime -p)"
echo ""
echo "=== CPU信息 ==="
echo "CPU型号: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "CPU核心数: $(nproc)"
echo "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo ""
echo "=== 内存信息 ==="
free -h
echo ""
echo "=== 磁盘信息 ==="
df -h
echo ""
echo "=== 网络信息 ==="
ip addr show | grep -E "inet.*brd" | awk '{print $2}'
EOF

sudo chmod +x /usr/local/bin/sysinfo
```

## 验证和测试

### 1. 系统性能测试
```bash
# CPU性能测试
sysbench cpu --cpu-max-prime=20000 run

# 内存性能测试
sysbench memory --memory-total-size=1G run

# 磁盘I/O测试
sysbench fileio --file-total-size=1G prepare
sysbench fileio --file-total-size=1G --file-test-mode=rndrw run
sysbench fileio --file-total-size=1G cleanup
```

### 2. 网络性能测试
```bash
# 安装网络测试工具
sudo apt install -y iperf3

# 测试网络带宽（需要另一台机器作为服务端）
# 服务端：iperf3 -s
# 客户端：iperf3 -c server_ip
```

### 3. 系统状态检查
```bash
# 检查系统服务状态
systemctl list-units --failed

# 检查系统日志
journalctl -p err -b

# 检查网络连接
ss -tuln

# 检查进程状态
ps aux --sort=-%cpu | head -10
```

## 维护建议

### 1. 定期维护任务
```bash
# 创建维护脚本
sudo tee /usr/local/bin/system-maintenance << 'EOF'
#!/bin/bash
echo "开始系统维护..."

# 更新软件包
apt update && apt upgrade -y

# 清理系统
apt autoremove -y
apt autoclean

# 清理日志
journalctl --vacuum-time=7d

# 清理临时文件
find /tmp -type f -atime +7 -delete

echo "系统维护完成"
EOF

sudo chmod +x /usr/local/bin/system-maintenance
```

### 2. 定期备份
```bash
# 创建配置文件备份脚本
sudo tee /usr/local/bin/backup-configs << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/configs/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# 备份重要配置文件
cp -r /etc/ssh $BACKUP_DIR/
cp -r /etc/nginx $BACKUP_DIR/ 2>/dev/null || true
cp -r /etc/apache2 $BACKUP_DIR/ 2>/dev/null || true
cp /etc/fstab $BACKUP_DIR/
cp /etc/hosts $BACKUP_DIR/
cp -r /etc/systemd $BACKUP_DIR/

echo "配置文件备份完成: $BACKUP_DIR"
EOF

sudo chmod +x /usr/local/bin/backup-configs
```

## 总结

通过以上步骤，你将获得一个经过优化的Ubuntu 22.04.3 Server系统，具备：

- 优化的网络和I/O性能
- 增强的系统安全性
- 完善的监控和日志管理
- 自动化的维护机制

建议根据具体的应用场景进一步调整配置参数。