# Playbook 编写

## 什么是 Playbook？

Playbook 是 Ansible 的配置、部署和编排语言，使用 YAML 格式编写，用于定义自动化任务。

### Playbook vs Ad-Hoc

```
Ad-Hoc 命令：
- 适合临时任务
- 命令行执行
- 不可重用

Playbook：
- 适合复杂任务
- 文件形式
- 可重用、可版本控制
- 支持条件、循环、变量
```

---

## Playbook 基本结构

### 最简单的 Playbook

```yaml
# hello.yml
---
- name: Hello World Playbook
  hosts: all
  tasks:
    - name: Print hello message
      debug:
        msg: "Hello, Ansible!"
```

### 执行 Playbook

```bash
# 基本执行
ansible-playbook hello.yml

# 检查语法
ansible-playbook hello.yml --syntax-check

# 模拟执行（不实际执行）
ansible-playbook hello.yml --check

# 查看执行的主机
ansible-playbook hello.yml --list-hosts

# 查看任务列表
ansible-playbook hello.yml --list-tasks

# 指定 inventory
ansible-playbook -i inventory.ini hello.yml

# 限制主机
ansible-playbook hello.yml --limit webservers

# 详细输出
ansible-playbook hello.yml -v
ansible-playbook hello.yml -vvv
```

---

## Playbook 组成部分

### 完整示例

```yaml
---
# Play 1
- name: Configure web servers
  hosts: webservers
  become: yes
  vars:
    http_port: 80
    max_clients: 200
  
  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present
    
    - name: Start nginx service
      service:
        name: nginx
        state: started
        enabled: yes

# Play 2
- name: Configure database servers
  hosts: dbservers
  become: yes
  
  tasks:
    - name: Install MySQL
      yum:
        name: mysql-server
        state: present
```

### 关键字说明

```yaml
---                    # YAML 文件开始标记
- name:               # Play 或 Task 的名称
  hosts:              # 目标主机或主机组
  become: yes         # 使用 sudo
  become_user: root   # sudo 到指定用户
  vars:               # 变量定义
  tasks:              # 任务列表
  handlers:           # 处理器
  roles:              # 角色
  gather_facts: yes   # 收集系统信息
```

---

## 任务（Tasks）

### 基本任务

```yaml
---
- name: Basic tasks example
  hosts: all
  tasks:
    # 安装软件
    - name: Install nginx
      yum:
        name: nginx
        state: present
    
    # 复制文件
    - name: Copy nginx config
      copy:
        src: /tmp/nginx.conf
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
    
    # 启动服务
    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
    
    # 执行命令
    - name: Check nginx status
      command: systemctl status nginx
      register: nginx_status
    
    # 显示结果
    - name: Show nginx status
      debug:
        var: nginx_status.stdout_lines
```

### 任务控制

```yaml
---
- name: Task control example
  hosts: all
  tasks:
    # 忽略错误
    - name: This might fail
      command: /bin/false
      ignore_errors: yes
    
    # 改变状态
    - name: Always changed
      command: echo "changed"
      changed_when: true
    
    # 不改变状态
    - name: Never changed
      command: echo "ok"
      changed_when: false
    
    # 条件判断失败
    - name: Check file exists
      stat:
        path: /tmp/test.txt
      register: file_stat
      failed_when: not file_stat.stat.exists
```

---

## 变量（Variables）

### 定义变量

```yaml
---
- name: Variables example
  hosts: all
  vars:
    # 简单变量
    http_port: 80
    server_name: example.com
    
    # 列表
    packages:
      - nginx
      - mysql
      - php
    
    # 字典
    user_info:
      name: deploy
      uid: 1001
      shell: /bin/bash
  
  tasks:
    - name: Use simple variable
      debug:
        msg: "Port is {{ http_port }}"
    
    - name: Use list
      yum:
        name: "{{ packages }}"
        state: present
    
    - name: Use dictionary
      user:
        name: "{{ user_info.name }}"
        uid: "{{ user_info.uid }}"
        shell: "{{ user_info.shell }}"
```

### 变量文件

```yaml
# vars.yml
http_port: 80
max_clients: 200
packages:
  - nginx
  - mysql
```

```yaml
# playbook.yml
---
- name: Use variable file
  hosts: all
  vars_files:
    - vars.yml
  
  tasks:
    - name: Show port
      debug:
        msg: "Port is {{ http_port }}"
```

### 命令行变量

```bash
# 使用 -e 传递变量
ansible-playbook playbook.yml -e "http_port=8080"
ansible-playbook playbook.yml -e "{'http_port':8080,'max_clients':300}"
ansible-playbook playbook.yml -e @vars.json
```

### 注册变量

```yaml
---
- name: Register variable example
  hosts: all
  tasks:
    - name: Get disk usage
      shell: df -h
      register: disk_usage
    
    - name: Show disk usage
      debug:
        var: disk_usage.stdout_lines
    
    - name: Check if nginx is installed
      command: which nginx
      register: nginx_path
      ignore_errors: yes
    
    - name: Install nginx if not exists
      yum:
        name: nginx
        state: present
      when: nginx_path.rc != 0
```

---

## 条件判断（When）

### 基本条件

```yaml
---
- name: Conditional example
  hosts: all
  tasks:
    # 简单条件
    - name: Install nginx on CentOS
      yum:
        name: nginx
        state: present
      when: ansible_os_family == "RedHat"
    
    - name: Install nginx on Ubuntu
      apt:
        name: nginx
        state: present
      when: ansible_os_family == "Debian"
    
    # 多条件（and）
    - name: Install on CentOS 7
      yum:
        name: nginx
        state: present
      when:
        - ansible_os_family == "RedHat"
        - ansible_distribution_major_version == "7"
    
    # 多条件（or）
    - name: Install on CentOS or Ubuntu
      package:
        name: nginx
        state: present
      when: ansible_os_family == "RedHat" or ansible_os_family == "Debian"
```

### 复杂条件

```yaml
---
- name: Complex conditional
  hosts: all
  tasks:
    - name: Check file exists
      stat:
        path: /etc/nginx/nginx.conf
      register: nginx_conf
    
    - name: Backup config if exists
      copy:
        src: /etc/nginx/nginx.conf
        dest: /etc/nginx/nginx.conf.bak
        remote_src: yes
      when: nginx_conf.stat.exists
    
    - name: Check variable is defined
      debug:
        msg: "Variable is defined"
      when: my_var is defined
    
    - name: Check variable is not empty
      debug:
        msg: "Variable is not empty"
      when: my_var | length > 0
```

---

## 循环（Loop）

### 简单循环

```yaml
---
- name: Loop example
  hosts: all
  tasks:
    # 循环列表
    - name: Install packages
      yum:
        name: "{{ item }}"
        state: present
      loop:
        - nginx
        - mysql
        - php
    
    # 循环字典
    - name: Create users
      user:
        name: "{{ item.name }}"
        uid: "{{ item.uid }}"
        state: present
      loop:
        - { name: 'user1', uid: 1001 }
        - { name: 'user2', uid: 1002 }
        - { name: 'user3', uid: 1003 }
```

### 复杂循环

```yaml
---
- name: Complex loop
  hosts: all
  tasks:
    # 循环字典列表
    - name: Create users with details
      user:
        name: "{{ item.name }}"
        uid: "{{ item.uid }}"
        shell: "{{ item.shell }}"
        groups: "{{ item.groups }}"
      loop:
        - name: deploy
          uid: 1001
          shell: /bin/bash
          groups: wheel
        - name: www
          uid: 1002
          shell: /sbin/nologin
          groups: nginx
    
    # 循环范围
    - name: Create files
      file:
        path: "/tmp/file{{ item }}.txt"
        state: touch
      loop: "{{ range(1, 6) | list }}"
    
    # 循环变量
    - name: Show loop info
      debug:
        msg: "Item {{ item }} ({{ loop_index }}/{{ loop_length }})"
      loop:
        - one
        - two
        - three
      loop_control:
        index_var: loop_index
        length_var: loop_length
```

---

## 处理器（Handlers）

### 基本用法

```yaml
---
- name: Handlers example
  hosts: all
  tasks:
    - name: Copy nginx config
      copy:
        src: /tmp/nginx.conf
        dest: /etc/nginx/nginx.conf
      notify: Restart nginx
    
    - name: Copy php config
      copy:
        src: /tmp/php.ini
        dest: /etc/php.ini
      notify:
        - Restart php-fpm
        - Restart nginx
  
  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
    
    - name: Restart php-fpm
      service:
        name: php-fpm
        state: restarted
```

### Handlers 特点

```
1. 只在任务状态为 changed 时触发
2. 在所有任务执行完后才执行
3. 多次 notify 只执行一次
4. 按定义顺序执行
```

---

## 模板（Templates）

### Jinja2 模板

```jinja2
{# nginx.conf.j2 #}
user {{ nginx_user }};
worker_processes {{ ansible_processor_cores }};

events {
    worker_connections {{ worker_connections }};
}

http {
    server {
        listen {{ http_port }};
        server_name {{ server_name }};
        
        {% for location in locations %}
        location {{ location.path }} {
            root {{ location.root }};
        }
        {% endfor %}
    }
}
```

### 使用模板

```yaml
---
- name: Template example
  hosts: all
  vars:
    nginx_user: nginx
    worker_connections: 1024
    http_port: 80
    server_name: example.com
    locations:
      - { path: '/', root: '/data/www' }
      - { path: '/static', root: '/data/static' }
  
  tasks:
    - name: Deploy nginx config from template
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
      notify: Restart nginx
  
  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

---

## 实战案例

### 案例1：部署 Nginx

```yaml
---
- name: Deploy Nginx
  hosts: webservers
  become: yes
  vars:
    nginx_port: 80
    server_name: example.com
    document_root: /data/www
  
  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present
    
    - name: Create document root
      file:
        path: "{{ document_root }}"
        state: directory
        owner: nginx
        group: nginx
        mode: '0755'
    
    - name: Deploy index page
      copy:
        content: |
          <html>
          <head><title>Welcome</title></head>
          <body><h1>Welcome to {{ server_name }}</h1></body>
          </html>
        dest: "{{ document_root }}/index.html"
        owner: nginx
        group: nginx
        mode: '0644'
    
    - name: Deploy nginx config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/conf.d/{{ server_name }}.conf
      notify: Restart nginx
    
    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
  
  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

### 案例2：批量创建用户

```yaml
---
- name: Create multiple users
  hosts: all
  become: yes
  vars:
    users:
      - name: deploy
        uid: 1001
        groups: wheel
        shell: /bin/bash
      - name: www
        uid: 1002
        groups: nginx
        shell: /sbin/nologin
      - name: app
        uid: 1003
        groups: docker
        shell: /bin/bash
  
  tasks:
    - name: Create groups
      group:
        name: "{{ item.groups }}"
        state: present
      loop: "{{ users }}"
    
    - name: Create users
      user:
        name: "{{ item.name }}"
        uid: "{{ item.uid }}"
        groups: "{{ item.groups }}"
        shell: "{{ item.shell }}"
        state: present
      loop: "{{ users }}"
    
    - name: Set up SSH keys
      authorized_key:
        user: "{{ item.name }}"
        key: "{{ lookup('file', '/root/.ssh/id_rsa.pub') }}"
      loop: "{{ users }}"
      when: item.shell == "/bin/bash"
```

### 案例3：LNMP 环境部署

```yaml
---
- name: Deploy LNMP Stack
  hosts: webservers
  become: yes
  
  tasks:
    # 安装软件
    - name: Install LNMP packages
      yum:
        name:
          - nginx
          - mysql-server
          - php
          - php-fpm
          - php-mysql
        state: present
    
    # 配置 Nginx
    - name: Configure nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Restart nginx
    
    # 配置 PHP-FPM
    - name: Configure php-fpm
      template:
        src: php-fpm.conf.j2
        dest: /etc/php-fpm.d/www.conf
      notify: Restart php-fpm
    
    # 启动服务
    - name: Start services
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - nginx
        - mysql
        - php-fpm
    
    # 配置 MySQL
    - name: Set MySQL root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        host: localhost
        state: present
  
  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
    
    - name: Restart php-fpm
      service:
        name: php-fpm
        state: restarted
```

---

## 最佳实践

### 1. 使用有意义的名称

```yaml
# 不好
- name: task1
  yum:
    name: nginx

# 好
- name: Install nginx web server
  yum:
    name: nginx
    state: present
```

### 2. 使用变量

```yaml
# 不好
- name: Install nginx
  yum:
    name: nginx
    state: present

# 好
- name: Install web server
  yum:
    name: "{{ web_server_package }}"
    state: present
```

### 3. 使用模板

```yaml
# 不好
- name: Create config
  copy:
    content: "port=80"
    dest: /etc/config

# 好
- name: Deploy config from template
  template:
    src: config.j2
    dest: /etc/config
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

---

## 练习题

### 基础练习

1. 编写 Playbook 安装 Nginx
2. 使用变量定制配置
3. 使用循环创建多个用户
4. 使用条件判断不同系统
5. 使用 Handlers 重启服务

### 进阶练习

1. 编写 LNMP 部署 Playbook
2. 使用模板生成配置文件
3. 编写多 Play 的 Playbook
4. 实现配置文件备份
5. 编写完整的应用部署流程

---

## 总结

Playbook 编写要点：
- ✅ 掌握 YAML 语法
- ✅ 理解 Play 和 Task
- ✅ 使用变量和模板
- ✅ 掌握条件和循环
- ✅ 使用 Handlers
- ✅ 遵循最佳实践

Playbook 是 Ansible 的核心，务必熟练掌握！
