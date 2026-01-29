# Ansible 自动化运维学习指南

## 学习路线

```
01_Ansible基础入门.md  ──▶  掌握 Ansible 基础
        │
        ▼
02_Playbook编写.md     ──▶  编写自动化脚本
        │
        ▼
03_Roles角色.md        ──▶  模块化管理
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_Ansible基础入门.md | 安装、Inventory、Ad-Hoc、模块 | 1.5 天 |
| 02_Playbook编写.md | Playbook、变量、条件、循环 | 2 天 |
| 03_Roles角色.md | Role 结构、创建、使用、Galaxy | 1.5 天 |

## 核心知识点

### Ansible 基础
- Ansible 架构和特点
- Inventory 主机清单
- Ad-Hoc 命令
- 常用模块（command、shell、copy、yum、service等）
- 配置文件
- Facts 系统信息

### Playbook 编写
- YAML 语法
- Play 和 Task
- 变量定义和使用
- 条件判断（when）
- 循环（loop）
- Handlers 处理器
- Templates 模板
- 实战案例

### Roles 角色
- Role 目录结构
- 创建和使用 Role
- Role 依赖
- Ansible Galaxy
- 项目组织结构
- 最佳实践

## 常用命令速查

### Ad-Hoc 命令

```bash
# Ping 测试
ansible all -m ping

# 执行命令
ansible all -m command -a "uptime"
ansible all -a "uptime"

# 使用 shell
ansible all -m shell -a "ps aux | grep nginx"

# 复制文件
ansible all -m copy -a "src=/tmp/file dest=/tmp/file"

# 安装软件
ansible all -m yum -a "name=nginx state=present"

# 启动服务
ansible all -m service -a "name=nginx state=started enabled=yes"

# 创建用户
ansible all -m user -a "name=deploy state=present"
```

### Playbook 命令

```bash
# 执行 playbook
ansible-playbook site.yml

# 检查语法
ansible-playbook site.yml --syntax-check

# 模拟执行
ansible-playbook site.yml --check

# 查看主机
ansible-playbook site.yml --list-hosts

# 查看任务
ansible-playbook site.yml --list-tasks

# 限制主机
ansible-playbook site.yml --limit webservers

# 使用标签
ansible-playbook site.yml --tags "install"
ansible-playbook site.yml --skip-tags "config"

# 详细输出
ansible-playbook site.yml -v
ansible-playbook site.yml -vvv
```

### Role 命令

```bash
# 初始化 role
ansible-galaxy init nginx

# 搜索 role
ansible-galaxy search nginx

# 安装 role
ansible-galaxy install geerlingguy.nginx

# 安装依赖
ansible-galaxy install -r requirements.yml

# 列出已安装的 role
ansible-galaxy list
```

## Inventory 配置模板

### INI 格式

```ini
# /etc/ansible/hosts

[webservers]
web1 ansible_host=192.168.1.101
web2 ansible_host=192.168.1.102
web3 ansible_host=192.168.1.103

[dbservers]
db1 ansible_host=192.168.1.201
db2 ansible_host=192.168.1.202

[webservers:vars]
ansible_user=root
ansible_port=22
ansible_ssh_private_key_file=/root/.ssh/id_rsa

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

## Playbook 模板

### 基本 Playbook

```yaml
---
- name: Deploy web servers
  hosts: webservers
  become: yes
  vars:
    http_port: 80
  
  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present
    
    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
```

### 使用 Role

```yaml
---
- name: Deploy web servers
  hosts: webservers
  become: yes
  
  roles:
    - nginx
    - php
    - mysql
```

### 完整示例

```yaml
---
- name: Deploy LNMP Stack
  hosts: webservers
  become: yes
  vars:
    nginx_port: 80
    mysql_root_password: "{{ vault_mysql_password }}"
  
  pre_tasks:
    - name: Update yum cache
      yum:
        update_cache: yes
  
  roles:
    - common
    - nginx
    - mysql
    - php
  
  post_tasks:
    - name: Verify services
      service:
        name: "{{ item }}"
        state: started
      loop:
        - nginx
        - mysql
        - php-fpm
  
  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

## 实战场景

### 场景1：批量部署 Nginx

```bash
# 1. 准备 inventory
cat > inventory.ini << EOF
[webservers]
web[1:3] ansible_host=192.168.1.10[1:3]

[webservers:vars]
ansible_user=root
EOF

# 2. 编写 playbook
cat > deploy_nginx.yml << 'EOF'
---
- name: Deploy Nginx
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present
    
    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
EOF

# 3. 执行
ansible-playbook -i inventory.ini deploy_nginx.yml
```

### 场景2：使用 Role 部署

```bash
# 1. 创建 role
ansible-galaxy init roles/nginx

# 2. 编辑 role
# roles/nginx/tasks/main.yml
# roles/nginx/templates/nginx.conf.j2
# roles/nginx/defaults/main.yml

# 3. 使用 role
cat > site.yml << 'EOF'
---
- name: Deploy web servers
  hosts: webservers
  become: yes
  roles:
    - nginx
EOF

# 4. 执行
ansible-playbook site.yml
```

### 场景3：配置管理

```bash
# 1. 准备配置模板
# templates/nginx.conf.j2

# 2. 编写 playbook
cat > config.yml << 'EOF'
---
- name: Update nginx config
  hosts: webservers
  become: yes
  
  tasks:
    - name: Deploy config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Reload nginx
  
  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
EOF

# 3. 执行
ansible-playbook config.yml
```

## 常用模块速查

| 模块 | 用途 | 示例 |
|------|------|------|
| ping | 测试连接 | `ansible all -m ping` |
| command | 执行命令 | `ansible all -m command -a "uptime"` |
| shell | 执行 shell | `ansible all -m shell -a "ps aux \| grep nginx"` |
| copy | 复制文件 | `ansible all -m copy -a "src=/tmp/file dest=/tmp/"` |
| file | 文件操作 | `ansible all -m file -a "path=/tmp/test state=touch"` |
| yum | 包管理 | `ansible all -m yum -a "name=nginx state=present"` |
| service | 服务管理 | `ansible all -m service -a "name=nginx state=started"` |
| user | 用户管理 | `ansible all -m user -a "name=deploy state=present"` |
| group | 组管理 | `ansible all -m group -a "name=deploy state=present"` |
| template | 模板 | `ansible all -m template -a "src=file.j2 dest=/tmp/file"` |

## 变量优先级

```
从低到高：
1. role defaults
2. inventory file or script group vars
3. inventory group_vars/all
4. playbook group_vars/all
5. inventory group_vars/*
6. playbook group_vars/*
7. inventory file or script host vars
8. inventory host_vars/*
9. playbook host_vars/*
10. host facts
11. play vars
12. play vars_prompt
13. play vars_files
14. role vars
15. block vars
16. task vars
17. include_vars
18. set_facts
19. role params
20. include params
21. extra vars (-e)
```

## 最佳实践

### 1. 项目结构

```
ansible-project/
├── ansible.cfg
├── inventory/
│   ├── production
│   └── staging
├── group_vars/
│   ├── all.yml
│   └── webservers.yml
├── host_vars/
│   └── web1.yml
├── roles/
│   ├── common/
│   ├── nginx/
│   └── mysql/
├── playbooks/
│   ├── site.yml
│   └── webservers.yml
└── requirements.yml
```

### 2. 使用变量

```yaml
# 不好
- name: Install nginx
  yum:
    name: nginx

# 好
- name: Install web server
  yum:
    name: "{{ web_server_package }}"
```

### 3. 使用 Handlers

```yaml
# 配置变更时自动重启
- name: Deploy config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Restart nginx

handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted
```

### 4. 幂等性

```yaml
# 确保多次执行结果一致
- name: Ensure nginx is installed
  yum:
    name: nginx
    state: present

- name: Ensure nginx is running
  service:
    name: nginx
    state: started
```

### 5. 使用标签

```yaml
- name: Install nginx
  yum:
    name: nginx
  tags:
    - install
    - nginx

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags:
    - config
    - nginx
```

## 故障排查

### 常见问题

```bash
# 1. SSH 连接失败
# 检查 SSH 连接
ansible all -m ping -vvv

# 2. 权限不足
# 使用 sudo
ansible all -m command -a "whoami" -b

# 3. 模块未找到
# 检查模块名称
ansible-doc -l | grep module_name

# 4. 语法错误
# 检查语法
ansible-playbook playbook.yml --syntax-check

# 5. 查看详细输出
ansible-playbook playbook.yml -vvv
```

## 练习题

### 基础练习

1. 安装 Ansible 并配置 Inventory
2. 使用 Ad-Hoc 命令管理服务器
3. 编写简单的 Playbook
4. 使用变量和模板
5. 使用条件和循环

### 进阶练习

1. 创建 Nginx Role
2. 编写 LNMP 部署 Playbook
3. 使用 Ansible Galaxy
4. 配置 Role 依赖
5. 编写完整的项目结构

## 面试常考

1. Ansible 的工作原理？
2. Ansible 和其他工具的区别？
3. Inventory 有哪些格式？
4. Playbook 的基本结构？
5. 如何使用变量？
6. 什么是 Handlers？
7. Role 的目录结构？
8. 如何保证幂等性？
9. 变量优先级顺序？
10. 如何调试 Ansible？

## 学习建议

### 1. 循序渐进

- 先学习 Ad-Hoc 命令
- 再学习 Playbook
- 最后学习 Role

### 2. 实践为主

- 搭建测试环境
- 编写实际的 Playbook
- 部署真实项目

### 3. 模块化思维

- 使用 Role 组织代码
- 遵循最佳实践
- 编写可重用的代码

### 4. 版本控制

- 使用 Git 管理代码
- 编写文档
- 团队协作

## 推荐资源

### 官方文档

- [Ansible 官方文档](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible 模块索引](https://docs.ansible.com/ansible/latest/modules/modules_by_category.html)

### 推荐书籍

- 《Ansible 自动化运维实战》
- 《Ansible Up and Running》
- 《Ansible for DevOps》

### 在线资源

- Ansible 中文社区
- GitHub Ansible 项目
- Ansible 视频教程

## 下一步

完成 Ansible 学习后，继续学习：
- **Zabbix**：监控告警系统
- **Docker**：容器化技术
- **Kubernetes**：容器编排

Ansible 是自动化运维的核心工具，掌握它能大大提高工作效率！

加油！💪
