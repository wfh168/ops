# KVM 虚拟化学习指南

## 📋 目录结构

```
kvm学习指南/
├── README.md                          # 本文件
├── 01_KVM基础入门.md                  # KVM 基础概念和架构
├── 02_环境检查和安装.md               # 检查硬件支持和安装 KVM
├── 03_创建第一个虚拟机.md             # 使用命令行创建虚拟机
├── 04_虚拟机管理.md                   # 启动、停止、删除虚拟机
├── 05_网络配置.md                     # 虚拟机网络配置
├── 06_存储管理.md                     # 磁盘和存储池管理
├── 07_快照和克隆.md                   # 虚拟机快照和克隆
├── 08_virt-manager图形界面.md         # 使用图形界面管理
├── 09_性能优化.md                     # 虚拟机性能调优
├── 10_实战案例.md                     # 实际应用场景
└── scripts/                           # 实用脚本
    ├── check-kvm.sh                   # 检查 KVM 环境
    ├── create-vm.sh                   # 快速创建虚拟机
    └── vm-manager.sh                  # 虚拟机管理脚本
```

## 🎯 学习路线

### 初级（1-3 天）
1. ✅ **KVM 基础概念**
   - 什么是 KVM
   - KVM vs VMware vs VirtualBox
   - 虚拟化技术原理

2. ✅ **环境准备**
   - 检查硬件支持
   - 安装 KVM 和相关工具
   - 验证安装

3. ✅ **创建第一个虚拟机**
   - 使用 virt-install 创建虚拟机
   - 安装操作系统
   - 基本操作

### 中级（4-7 天）
4. ✅ **虚拟机管理**
   - virsh 命令详解
   - 虚拟机生命周期管理
   - 资源配置调整

5. ✅ **网络配置**
   - NAT 网络
   - 桥接网络
   - 隔离网络

6. ✅ **存储管理**
   - 存储池
   - 存储卷
   - 磁盘格式（qcow2, raw）

### 高级（8-14 天）
7. ✅ **快照和克隆**
   - 创建快照
   - 恢复快照
   - 克隆虚拟机

8. ✅ **图形界面管理**
   - virt-manager 使用
   - 远程管理

9. ✅ **性能优化**
   - CPU 优化
   - 内存优化
   - 磁盘 I/O 优化

10. ✅ **实战案例**
    - 搭建测试环境
    - 部署 Web 服务
    - 集群环境搭建

## 🚀 快速开始

### 1. 检查系统支持

```bash
# 检查 CPU 是否支持虚拟化
egrep -c '(vmx|svm)' /proc/cpuinfo
# 输出大于 0 表示支持

# 查看虚拟化类型
lscpu | grep -i virtualization
# Intel: VT-x
# AMD: AMD-V
```

### 2. 验证 KVM 安装

```bash
# 检查 KVM 模块
lsmod | grep kvm

# 检查工具是否安装
which virsh qemu-system-x86_64 virt-manager
```

### 3. 运行环境检查脚本

```bash
bash kvm学习指南/scripts/check-kvm.sh
```

## 📚 核心概念

### KVM 架构

```
┌─────────────────────────────────────────┐
│         虚拟机 (Guest OS)                │
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │ VM 1 │  │ VM 2 │  │ VM 3 │          │
│  └──────┘  └──────┘  └──────┘          │
├─────────────────────────────────────────┤
│         QEMU (设备模拟)                  │
├─────────────────────────────────────────┤
│         KVM (内核模块)                   │
├─────────────────────────────────────────┤
│         Linux Kernel                     │
├─────────────────────────────────────────┤
│         物理硬件 (CPU, 内存, 磁盘)       │
└─────────────────────────────────────────┘
```

### 核心组件

1. **KVM (Kernel-based Virtual Machine)**
   - Linux 内核模块
   - 提供虚拟化基础设施
   - 负责 CPU 和内存虚拟化

2. **QEMU (Quick Emulator)**
   - 设备模拟器
   - 模拟硬件设备（网卡、磁盘等）
   - 提供虚拟机管理接口

3. **libvirt**
   - 虚拟化管理 API
   - 统一管理接口
   - 支持多种虚拟化技术

4. **virsh**
   - 命令行管理工具
   - 基于 libvirt
   - 功能强大

5. **virt-manager**
   - 图形界面管理工具
   - 易于使用
   - 适合初学者

## 🛠️ 常用命令速查

### 虚拟机管理

```bash
# 列出所有虚拟机
virsh list --all

# 启动虚拟机
virsh start vm-name

# 关闭虚拟机
virsh shutdown vm-name

# 强制关闭
virsh destroy vm-name

# 删除虚拟机
virsh undefine vm-name

# 查看虚拟机信息
virsh dominfo vm-name
```

### 网络管理

```bash
# 列出网络
virsh net-list --all

# 启动网络
virsh net-start default

# 查看网络信息
virsh net-info default
```

### 存储管理

```bash
# 列出存储池
virsh pool-list --all

# 列出存储卷
virsh vol-list default

# 查看存储池信息
virsh pool-info default
```

## 💡 学习建议

### 1. 循序渐进
- 先掌握基础概念
- 再学习命令行操作
- 最后使用图形界面

### 2. 动手实践
- 每个知识点都要实际操作
- 创建测试虚拟机练习
- 记录遇到的问题和解决方法

### 3. 理解原理
- 不要只记命令
- 理解虚拟化原理
- 了解网络和存储架构

### 4. 参考文档
- KVM 官方文档
- libvirt 文档
- QEMU 文档

## 🎓 学习目标

### 初级目标
- [ ] 理解 KVM 基本概念
- [ ] 能够创建和管理虚拟机
- [ ] 掌握基本的 virsh 命令
- [ ] 配置简单的网络

### 中级目标
- [ ] 熟练使用 virsh 管理虚拟机
- [ ] 配置各种网络模式
- [ ] 管理存储池和存储卷
- [ ] 创建和使用快照

### 高级目标
- [ ] 优化虚拟机性能
- [ ] 搭建复杂的网络环境
- [ ] 自动化虚拟机部署
- [ ] 故障排查和问题解决

## 📖 推荐资源

### 官方文档
- [KVM 官网](https://www.linux-kvm.org/)
- [libvirt 文档](https://libvirt.org/docs.html)
- [QEMU 文档](https://www.qemu.org/docs/master/)

### 在线教程
- Red Hat 虚拟化指南
- Ubuntu KVM 教程
- Arch Linux KVM Wiki

### 书籍推荐
- 《KVM 虚拟化技术实战与原理解析》
- 《Linux KVM 虚拟化架构实战指南》

## 🔧 实用工具

### 命令行工具
- `virsh` - 虚拟机管理
- `virt-install` - 创建虚拟机
- `virt-clone` - 克隆虚拟机
- `virt-viewer` - 连接虚拟机控制台
- `virt-top` - 虚拟机资源监控

### 图形界面工具
- `virt-manager` - 虚拟机管理器
- `virt-viewer` - 虚拟机查看器
- `gnome-boxes` - 简化的虚拟机管理

## 🎯 你的系统信息

根据检查，你的系统：
- ✅ CPU 支持虚拟化（AMD-V）
- ✅ 有 16 个虚拟 CPU 核心
- ✅ KVM 工具已安装
  - virsh
  - qemu-system-x86_64
  - virt-manager

可以直接开始学习和实践！

## 📝 学习进度追踪

创建一个学习进度文件来追踪你的学习：

```bash
# 查看学习进度
cat kvm学习指南/学习进度.md
```

## 🚦 下一步

1. **阅读基础入门**：`01_KVM基础入门.md`
2. **检查环境**：`02_环境检查和安装.md`
3. **创建虚拟机**：`03_创建第一个虚拟机.md`

开始你的 KVM 学习之旅吧！
