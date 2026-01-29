# Ansible 基础入门

## 什么是 Ansible？

Ansible 是一个开源的自动化运维工具，用于配置管理、应用部署、任务执行等。

### Ansible 的特点

```
✅ 无需客户端（Agentless）
✅ 基于 SSH 通信
✅ 使用 YAML 语法
✅ 幂等性（多次执行结果一致）
✅ 模块化设计
✅ 易于学习和使用
```

### Ansible vs 其他工具

| 特性 | Ansible | Puppet | SaltStack | Chef |
|------|---------|--------|-----------|------|
| 架构 | 无客户端 | C/S | C/S | C/S |
| 语言 | YAML | Ruby DSL | YAML | Ruby DSL |
| 学习曲线 | 低 | 高 | 中 | 高 |
| 性能 | 中 | 高 | 高 | 中 |
| 适用场景 | 中小规模 | 大规模 | 大规模 | 大规模 |

---

## Ansible 架构

### 核心组件

```
控制节点（Control Node）
    │
    ├─ Inventory（主机清单）
    ├─ Playbook（剧本）
    ├─ Module（模块）
    └─ Plugin（插件）
    │
    ▼
被管理节点（Managed Node）
```

### 工作流程

```
1. 读取 Inventory（主机列表）
2. 加载 Playbook（任务定义）
3. 通过 SSH 连接到目标主机
4. 执行 Module（具体任务）
5. 返回执行结果
6. 删除临时文件
```

---

## 安装 Ansible

### CentOS/RHEL

```bash
# 安装 EPEL 仓库
yum install epel-release -y

# 安装 Ansible
yum install ansible -y

# 查看版本
ansible --version
```

### Ubuntu/Debian

```bash
# 更新包列表
apt update

# 安装 Ansible
apt install ansible -y

# 查看版本
ansible --version
```

### 使用 pip 安装

```bash
# 安装 pip
yum install python3-pip -y

# 安装 Ansible
pip3 install ansible

# 查看版本
ansible --version
```

---

## Inventory（主机清单）

### 默认 Inventory

```bash
# 默认位置
/etc/ansible/hosts

# 查看
cat /etc/ansible/hosts
```

### INI 格式

```ini
# /etc/ansible/hosts

# 单个主机
192.168.1.101

# 主机组
[webservers]
web1 ansible_host=192.168.1.101
web2 ansible_host=192.168.1.102
web3 ansible_host=192.168.1.103

[dbservers]
db1 ansible_host=192.168.1.201
db2 ansible_host=192.168.1.202

# 主机范围
[servers]
server[01:10].example.com

# 主机变量
[webservers]
web1 ansible_host=192.168.1.101 ansible_port=22 ansible_user=root

# 组变量
[webservers:vars]
ansible_user=root
ansible_port=22
ansible_ssh_private_key_file=/root/.ssh/id_rsa

# 子组
[production:children]
webservers
dbservers
```

### YAML 格式

```yaml
# inventory.yml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.101
        web2:
          ansible_host: 192.168.1.102
      vars:
        ansible_user: root
        ansible_port: 22
    
    dbservers:
      hosts:
        db1:
          ansible_host: 192.168.1.201
        db2:
          ansible_host: 192.168.1.202
```

### 动态 Inventory

```python
#!/usr/bin/env python3
# dynamic_inventory.py

import json

inventory = {
    "webservers": {
        "hosts": ["192.168.1.101", "192.168.1.102"],
        "vars": {
            "ansible_user": "root"
        }
    },
    "_meta": {
        "hostvars": {}
    }
}

print(json.dumps(inventory))
```

---

## Ad-Hoc 命令

### 基本语法

```bash
ansible <host-pattern> -m <module> -a <arguments>
```

### 常用示例

```bash
# Ping 测试
ansible all -m ping

# 执行命令
ansible all -m command -a "uptime"
ansible all -a "uptime"  # command 是默认模块

# 使用 shell 模块
ansible all -m shell -a "df -h | grep /dev/sda1"

# 复制文件
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts"

# 安装软件
ansible all -m yum -a "name=nginx state=present"

# 启动服务
ansible all -m service -a "name=nginx state=started enabled=yes"

# 创建用户
ansible all -m user -a "name=deploy state=present"

# 执行脚本
ansible all -m script -a "/path/to/script.sh"
```

### 常用参数

```bash
-i <inventory>    # 指定 inventory 文件
-m <module>       # 指定模块
-a <arguments>    # 模块参数
-u <user>         # SSH 用户
-k                # 提示输入 SSH 密码
-K                # 提示输入 sudo 密码
-b                # 使用 sudo
--become-user     # sudo 到指定用户
-f <num>          # 并发数
-C                # 检查模式（不实际执行）
-v                # 详细输出
-vvv              # 更详细输出
```

---

## 常用模块

### 1. command 模块

```bash
# 执行命令（不支持管道、重定向）
ansible all -m command -a "ls -la /tmp"

# 切换目录
ansible all -m command -a "pwd" -a "chdir=/tmp"

# 创建文件
ansible all -m command -a "touch /tmp/test.txt creates=/tmp/test.txt"
```

### 2. shell 模块

```bash
# 执行 shell 命令（支持管道、重定向）
ansible all -m shell -a "ps aux | grep nginx"

# 使用变量
ansible all -m shell -a "echo $HOME"

# 执行脚本
ansible all -m shell -a "bash /tmp/script.sh"
```

### 3. copy 模块

```bash
# 复制文件
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts"

# 设置权限
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts mode=0644 owner=root group=root"

# 备份
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts backup=yes"

# 直接写入内容
ansible all -m copy -a "content='Hello World' dest=/tmp/hello.txt"
```

### 4. file 模块

```bash
# 创建文件
ansible all -m file -a "path=/tmp/test.txt state=touch"

# 创建目录
ansible all -m file -a "path=/tmp/testdir state=directory mode=0755"

# 删除文件
ansible all -m file -a "path=/tmp/test.txt state=absent"

# 创建软链接
ansible all -m file -a "src=/etc/hosts dest=/tmp/hosts state=link"

# 修改权限
ansible all -m file -a "path=/tmp/test.txt mode=0644 owner=root group=root"
```

### 5. yum 模块

```bash
# 安装软件
ansible all -m yum -a "name=nginx state=present"

# 安装指定版本
ansible all -m yum -a "name=nginx-1.20.1 state=present"

# 卸载软件
ansible all -m yum -a "name=nginx state=absent"

# 更新软件
ansible all -m yum -a "name=nginx state=latest"

# 安装多个软件
ansible all -m yum -a "name=nginx,mysql,php state=present"
```

### 6. service 模块

```bash
# 启动服务
ansible all -m service -a "name=nginx state=started"

# 停止服务
ansible all -m service -a "name=nginx state=stopped"

# 重启服务
ansible all -m service -a "name=nginx state=restarted"

# 重新加载
ansible all -m service -a "name=nginx state=reloaded"

# 开机自启
ansible all -m service -a "name=nginx enabled=yes"
```

### 7. user 模块

```bash
# 创建用户
ansible all -m user -a "name=deploy state=present"

# 创建用户并设置密码
ansible all -m user -a "name=deploy password={{ 'password' | password_hash('sha512') }}"

# 删除用户
ansible all -m user -a "name=deploy state=absent remove=yes"

# 修改用户
ansible all -m user -a "name=deploy shell=/bin/bash home=/home/deploy"
```

### 8. group 模块

```bash
# 创建组
ansible all -m group -a "name=deploy state=present"

# 删除组
ansible all -m group -a "name=deploy state=absent"
```

---

## 配置文件

### ansible.cfg

```ini
# /etc/ansible/ansible.cfg

[defaults]
# Inventory 文件位置
inventory = /etc/ansible/hosts

# SSH 连接超时
timeout = 30

# 并发数
forks = 5

# 日志文件
log_path = /var/log/ansible.log

# 主机密钥检查
host_key_checking = False

# 重试文件
retry_files_enabled = False

# 角色路径
roles_path = /etc/ansible/roles

[privilege_escalation]
# 使用 sudo
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
# SSH 参数
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

---

## 实战案例

### 案例1：批量安装 Nginx

```bash
# 1. 准备 Inventory
cat > /etc/ansible/hosts << EOF
[webservers]
web1 ansible_host=192.168.1.101
web2 ansible_host=192.168.1.102
web3 ansible_host=192.168.1.103

[webservers:vars]
ansible_user=root
EOF

# 2. 测试连接
ansible webservers -m ping

# 3. 安装 Nginx
ansible webservers -m yum -a "name=nginx state=present"

# 4. 启动 Nginx
ansible webservers -m service -a "name=nginx state=started enabled=yes"

# 5. 验证
ansible webservers -m shell -a "systemctl status nginx"
```

### 案例2：批量部署配置文件

```bash
# 1. 准备配置文件
cat > /tmp/nginx.conf << EOF
server {
    listen 80;
    server_name example.com;
    root /data/www;
}
EOF

# 2. 复制配置文件
ansible webservers -m copy -a "src=/tmp/nginx.conf dest=/etc/nginx/conf.d/example.conf"

# 3. 测试配置
ansible webservers -m shell -a "nginx -t"

# 4. 重新加载
ansible webservers -m service -a "name=nginx state=reloaded"
```

### 案例3：批量创建用户

```bash
# 创建部署用户
ansible all -m user -a "name=deploy shell=/bin/bash createhome=yes"

# 设置 sudo 权限
ansible all -m shell -a "echo 'deploy ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/deploy"

# 配置 SSH 密钥
ansible all -m authorized_key -a "user=deploy key='{{ lookup('file', '/root/.ssh/id_rsa.pub') }}'"
```

---

## 变量

### 定义变量

```bash
# 命令行定义
ansible all -m debug -a "msg={{ my_var }}" -e "my_var=hello"

# Inventory 中定义
[webservers]
web1 ansible_host=192.168.1.101 http_port=80

# 变量文件
# group_vars/webservers.yml
http_port: 80
max_clients: 200
```

### 使用变量

```bash
# 在命令中使用
ansible all -m shell -a "echo {{ ansible_hostname }}"

# 查看所有变量
ansible all -m setup

# 查看特定变量
ansible all -m setup -a "filter=ansible_hostname"
```

---

## Facts

### 收集系统信息

```bash
# 收集所有 facts
ansible all -m setup

# 过滤 facts
ansible all -m setup -a "filter=ansible_os_family"
ansible all -m setup -a "filter=ansible_distribution*"
ansible all -m setup -a "filter=ansible_memory*"

# 禁用 facts 收集
ansible all -m ping --gather_facts=no
```

### 常用 Facts

```
ansible_hostname          # 主机名
ansible_os_family         # 操作系统家族
ansible_distribution      # 发行版
ansible_distribution_version  # 版本
ansible_kernel            # 内核版本
ansible_processor_cores   # CPU 核心数
ansible_memtotal_mb       # 总内存
ansible_default_ipv4.address  # IP 地址
```

---

## 练习题

### 基础练习

1. 安装 Ansible
2. 配置 Inventory（3 台主机）
3. 使用 ping 模块测试连接
4. 使用 command 模块执行命令
5. 使用 copy 模块复制文件

### 进阶练习

1. 批量安装 Nginx
2. 批量部署配置文件
3. 批量创建用户
4. 使用变量定制配置
5. 收集系统信息

---

## 总结

Ansible 基础要点：
- ✅ 理解 Ansible 架构
- ✅ 配置 Inventory
- ✅ 掌握 Ad-Hoc 命令
- ✅ 熟悉常用模块
- ✅ 使用变量和 Facts

---

## 下一步

完成 Ansible 基础后，继续学习：
- **02_Playbook编写.md**：编写自动化脚本
- **03_Roles角色.md**：模块化管理

Ansible 是自动化运维的核心工具，务必熟练掌握！
