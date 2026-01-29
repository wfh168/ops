# Roles 角色

## 什么是 Role？

Role（角色）是 Ansible 的一种组织方式，将 Playbook 按功能模块化，便于重用和共享。

### Role 的优势

```
✅ 模块化：按功能划分
✅ 可重用：多个项目共享
✅ 易维护：结构清晰
✅ 易分享：Ansible Galaxy
✅ 标准化：统一目录结构
```

---

## Role 目录结构

### 标准结构

```
roles/
└── nginx/
    ├── tasks/          # 任务
    │   └── main.yml
    ├── handlers/       # 处理器
    │   └── main.yml
    ├── templates/      # 模板
    │   └── nginx.conf.j2
    ├── files/          # 文件
    │   └── index.html
    ├── vars/           # 变量
    │   └── main.yml
    ├── defaults/       # 默认变量
    │   └── main.yml
    ├── meta/           # 元数据
    │   └── main.yml
    └── README.md       # 说明文档
```

### 目录说明

```
tasks/      # 主要任务列表
handlers/   # 处理器
templates/  # Jinja2 模板文件
files/      # 静态文件
vars/       # 变量（优先级高）
defaults/   # 默认变量（优先级低）
meta/       # 角色依赖和元信息
library/    # 自定义模块
module_utils/  # 模块工具
lookup_plugins/  # 查找插件
```

---

## 创建 Role

### 方法1：手动创建

```bash
# 创建目录结构
mkdir -p roles/nginx/{tasks,handlers,templates,files,vars,defaults,meta}

# 创建文件
touch roles/nginx/tasks/main.yml
touch roles/nginx/handlers/main.yml
touch roles/nginx/defaults/main.yml
```

### 方法2：使用 ansible-galaxy

```bash
# 初始化 Role
ansible-galaxy init nginx

# 指定路径
ansible-galaxy init roles/nginx

# 查看生成的结构
tree roles/nginx
```

---

## Role 示例

### 示例1：Nginx Role

#### tasks/main.yml

```yaml
---
# roles/nginx/tasks/main.yml

- name: Install nginx
  yum:
    name: nginx
    state: present

- name: Create document root
  file:
    path: "{{ nginx_document_root }}"
    state: directory
    owner: nginx
    group: nginx
    mode: '0755'

- name: Deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
  notify: Restart nginx

- name: Deploy index page
  template:
    src: index.html.j2
    dest: "{{ nginx_document_root }}/index.html"
    owner: nginx
    group: nginx
    mode: '0644'

- name: Start nginx service
  service:
    name: nginx
    state: started
    enabled: yes
```

#### handlers/main.yml

```yaml
---
# roles/nginx/handlers/main.yml

- name: Restart nginx
  service:
    name: nginx
    state: restarted

- name: Reload nginx
  service:
    name: nginx
    state: reloaded
```

#### defaults/main.yml

```yaml
---
# roles/nginx/defaults/main.yml

nginx_port: 80
nginx_user: nginx
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_document_root: /data/www
nginx_server_name: localhost
```

#### templates/nginx.conf.j2

```jinja2
user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};

events {
    worker_connections {{ nginx_worker_connections }};
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    
    server {
        listen {{ nginx_port }};
        server_name {{ nginx_server_name }};
        root {{ nginx_document_root }};
        index index.html;
        
        location / {
            try_files $uri $uri/ =404;
        }
    }
}
```

#### meta/main.yml

```yaml
---
# roles/nginx/meta/main.yml

galaxy_info:
  author: Your Name
  description: Nginx web server role
  company: Your Company
  license: MIT
  min_ansible_version: 2.9
  
  platforms:
    - name: EL
      versions:
        - 7
        - 8
  
  galaxy_tags:
    - nginx
    - web
    - server

dependencies: []
```

---

## 使用 Role

### 方法1：在 Playbook 中使用

```yaml
---
# site.yml
- name: Deploy web servers
  hosts: webservers
  become: yes
  
  roles:
    - nginx
```

### 方法2：指定变量

```yaml
---
- name: Deploy web servers
  hosts: webservers
  become: yes
  
  roles:
    - role: nginx
      nginx_port: 8080
      nginx_server_name: example.com
```

### 方法3：使用 include_role

```yaml
---
- name: Deploy web servers
  hosts: webservers
  become: yes
  
  tasks:
    - name: Include nginx role
      include_role:
        name: nginx
```

### 方法4：使用 import_role

```yaml
---
- name: Deploy web servers
  hosts: webservers
  become: yes
  
  tasks:
    - name: Import nginx role
      import_role:
        name: nginx
```

---

## Role 依赖

### 定义依赖

```yaml
# roles/webapp/meta/main.yml
---
dependencies:
  - role: nginx
    nginx_port: 80
  
  - role: php
    php_version: 7.4
  
  - role: mysql
    mysql_root_password: "{{ vault_mysql_password }}"
```

### 使用有依赖的 Role

```yaml
---
- name: Deploy web application
  hosts: webservers
  become: yes
  
  roles:
    - webapp  # 会自动安装 nginx、php、mysql
```

---

## 实战案例

### 案例1：LNMP Role

#### 目录结构

```
roles/
├── nginx/
│   ├── tasks/main.yml
│   ├── handlers/main.yml
│   ├── templates/nginx.conf.j2
│   └── defaults/main.yml
├── mysql/
│   ├── tasks/main.yml
│   ├── handlers/main.yml
│   ├── templates/my.cnf.j2
│   └── defaults/main.yml
└── php/
    ├── tasks/main.yml
    ├── handlers/main.yml
    ├── templates/php.ini.j2
    └── defaults/main.yml
```

#### site.yml

```yaml
---
- name: Deploy LNMP Stack
  hosts: webservers
  become: yes
  
  roles:
    - nginx
    - mysql
    - php
```

### 案例2：用户管理 Role

#### roles/users/tasks/main.yml

```yaml
---
- name: Create groups
  group:
    name: "{{ item.group }}"
    state: present
  loop: "{{ users }}"
  when: item.group is defined

- name: Create users
  user:
    name: "{{ item.name }}"
    uid: "{{ item.uid | default(omit) }}"
    group: "{{ item.group | default(omit) }}"
    groups: "{{ item.groups | default(omit) }}"
    shell: "{{ item.shell | default('/bin/bash') }}"
    state: present
  loop: "{{ users }}"

- name: Set up SSH keys
  authorized_key:
    user: "{{ item.name }}"
    key: "{{ item.ssh_key }}"
  loop: "{{ users }}"
  when: item.ssh_key is defined
```

#### roles/users/defaults/main.yml

```yaml
---
users:
  - name: deploy
    uid: 1001
    group: deploy
    groups: wheel
    shell: /bin/bash
    ssh_key: "{{ lookup('file', '/root/.ssh/id_rsa.pub') }}"
```

#### 使用

```yaml
---
- name: Manage users
  hosts: all
  become: yes
  
  roles:
    - role: users
      users:
        - name: user1
          uid: 2001
          group: developers
        - name: user2
          uid: 2002
          group: operators
```

---

## Ansible Galaxy

### 搜索 Role

```bash
# 搜索 nginx role
ansible-galaxy search nginx

# 查看 role 信息
ansible-galaxy info geerlingguy.nginx
```

### 安装 Role

```bash
# 安装 role
ansible-galaxy install geerlingguy.nginx

# 安装到指定目录
ansible-galaxy install geerlingguy.nginx -p ./roles

# 从文件安装
ansible-galaxy install -r requirements.yml
```

### requirements.yml

```yaml
---
# requirements.yml

# 从 Galaxy 安装
- src: geerlingguy.nginx
  version: 3.1.0

- src: geerlingguy.mysql
  version: 4.0.0

# 从 Git 安装
- src: https://github.com/username/ansible-role-nginx.git
  scm: git
  version: master
  name: nginx

# 从本地路径
- src: /path/to/local/role
  name: local-role
```

### 安装依赖

```bash
# 安装 requirements.yml 中的所有 role
ansible-galaxy install -r requirements.yml

# 强制重新安装
ansible-galaxy install -r requirements.yml --force
```

---

## Role 最佳实践

### 1. 使用默认变量

```yaml
# roles/nginx/defaults/main.yml
---
nginx_port: 80
nginx_user: nginx
nginx_worker_processes: auto
```

### 2. 文档化

```markdown
# roles/nginx/README.md

# Nginx Role

## 描述
安装和配置 Nginx web 服务器

## 变量
- `nginx_port`: 监听端口（默认：80）
- `nginx_user`: 运行用户（默认：nginx）

## 示例
\`\`\`yaml
- hosts: webservers
  roles:
    - role: nginx
      nginx_port: 8080
\`\`\`
```

### 3. 使用标签

```yaml
# roles/nginx/tasks/main.yml
---
- name: Install nginx
  yum:
    name: nginx
    state: present
  tags:
    - nginx
    - install

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags:
    - nginx
    - config
```

```bash
# 只执行特定标签
ansible-playbook site.yml --tags "install"
ansible-playbook site.yml --tags "config"
ansible-playbook site.yml --skip-tags "install"
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
    enabled: yes
```

### 5. 错误处理

```yaml
- name: Check if config is valid
  command: nginx -t
  register: nginx_test
  failed_when: nginx_test.rc != 0
  changed_when: false

- name: Restart nginx if config is valid
  service:
    name: nginx
    state: restarted
  when: nginx_test.rc == 0
```

---

## 项目结构示例

### 完整项目结构

```
ansible-project/
├── ansible.cfg
├── inventory/
│   ├── production
│   └── staging
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   └── dbservers.yml
├── host_vars/
│   └── web1.yml
├── roles/
│   ├── common/
│   ├── nginx/
│   ├── mysql/
│   └── php/
├── playbooks/
│   ├── site.yml
│   ├── webservers.yml
│   └── dbservers.yml
└── requirements.yml
```

### ansible.cfg

```ini
[defaults]
inventory = inventory/production
roles_path = roles
host_key_checking = False
retry_files_enabled = False
```

### site.yml

```yaml
---
# 主 playbook
- import_playbook: webservers.yml
- import_playbook: dbservers.yml
```

---

## 练习题

### 基础练习

1. 创建一个 Nginx Role
2. 创建一个用户管理 Role
3. 使用 ansible-galaxy 初始化 Role
4. 在 Playbook 中使用 Role
5. 为 Role 添加默认变量

### 进阶练习

1. 创建 LNMP Role 集合
2. 配置 Role 依赖关系
3. 从 Ansible Galaxy 安装 Role
4. 创建 requirements.yml
5. 编写完整的项目结构

---

## 总结

Role 核心要点：
- ✅ 理解 Role 目录结构
- ✅ 掌握 Role 创建方法
- ✅ 学会使用 Role
- ✅ 配置 Role 依赖
- ✅ 使用 Ansible Galaxy
- ✅ 遵循最佳实践

Role 是 Ansible 模块化的核心，务必熟练掌握！
