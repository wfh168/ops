# Git Push到GitHub失败解决方案

## 问题诊断

### 1. 检查网络连接

```bash
# 测试GitHub连通性
ping github.com

# 测试HTTPS端口
curl -v https://github.com

# 测试SSH端口
ssh -T git@github.com
```

### 2. 检查代理设置

```bash
# 查看当前Git代理配置
git config --global --get http.proxy
git config --global --get https.proxy

# 查看系统代理
env | grep -i proxy
```

---

## 解决方案

### 方案1：使用SSH协议替代HTTPS（推荐）

#### 1. 生成SSH密钥（如果还没有）

```bash
# 生成SSH密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 或使用RSA（如果系统不支持ed25519）
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 启动ssh-agent
eval "$(ssh-agent -s)"

# 添加SSH密钥
ssh-add ~/.ssh/id_ed25519
# 或
ssh-add ~/.ssh/id_rsa
```

#### 2. 添加SSH公钥到GitHub

```bash
# 复制公钥内容
cat ~/.ssh/id_ed25519.pub
# 或
cat ~/.ssh/id_rsa.pub

# 然后：
# 1. 打开 https://github.com/settings/keys
# 2. 点击 "New SSH key"
# 3. 粘贴公钥内容
# 4. 保存
```

#### 3. 修改远程仓库URL为SSH

```bash
# 查看当前远程仓库URL
git remote -v

# 将HTTPS URL改为SSH URL
git remote set-url origin git@github.com:wfh168/ops.git

# 验证修改
git remote -v

# 测试SSH连接
ssh -T git@github.com
# 应该看到: Hi wfh168! You've successfully authenticated...
```

#### 4. 推送代码

```bash
# 现在可以推送了
git push origin main
# 或
git push origin master
```

---

### 方案2：配置Git使用代理

#### 如果你有HTTP/HTTPS代理：

```bash
# 设置HTTP代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 或使用SOCKS5代理
git config --global http.proxy socks5://127.0.0.1:7890
git config --global https.proxy socks5://127.0.0.1:7890

# 只为GitHub设置代理
git config --global http.https://github.com.proxy http://127.0.0.1:7890
```

#### 取消代理设置：

```bash
# 取消全局代理
git config --global --unset http.proxy
git config --global --unset https.proxy

# 取消GitHub特定代理
git config --global --unset http.https://github.com.proxy
```

---

### 方案3：修改hosts文件（DNS问题）

```bash
# 编辑hosts文件
sudo vim /etc/hosts

# 添加GitHub IP地址（使用最新的IP）
140.82.113.4    github.com
140.82.114.9    nodeload.github.com
140.82.112.5    api.github.com
140.82.112.10   codeload.github.com
185.199.108.133 raw.githubusercontent.com
185.199.109.153 assets-cdn.github.com

# 刷新DNS缓存
sudo systemd-resolve --flush-caches
# 或
sudo resolvectl flush-caches
```

---

### 方案4：使用GitHub镜像站（国内用户）

#### Gitee镜像同步：

```bash
# 1. 在Gitee上创建仓库
# 2. 添加Gitee作为远程仓库
git remote add gitee https://gitee.com/your-username/ops.git

# 3. 推送到Gitee
git push gitee main

# 4. 在Gitee上设置GitHub同步
# Gitee仓库设置 -> 仓库镜像管理 -> 添加GitHub仓库
```

#### 使用GitHub加速服务：

```bash
# 使用ghproxy加速
git config --global url."https://ghproxy.com/https://github.com".insteadOf "https://github.com"

# 或使用fastgit
git config --global url."https://hub.fastgit.xyz".insteadOf "https://github.com"
```

---

### 方案5：增加超时时间

```bash
# 增加Git超时时间
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

# 设置连接超时
git config --global http.timeout 300
```

---

## 完整诊断和修复脚本

```bash
#!/bin/bash
# Git GitHub连接问题诊断脚本

echo "=== Git GitHub连接诊断 ==="
echo ""

# 1. 检查网络连接
echo "1. 检查GitHub连通性..."
if ping -c 2 github.com &> /dev/null; then
    echo "✓ GitHub可以ping通"
else
    echo "✗ GitHub无法ping通"
fi
echo ""

# 2. 检查HTTPS连接
echo "2. 检查HTTPS连接..."
if curl -s --connect-timeout 5 https://github.com &> /dev/null; then
    echo "✓ HTTPS连接正常"
else
    echo "✗ HTTPS连接失败"
fi
echo ""

# 3. 检查SSH连接
echo "3. 检查SSH连接..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✓ SSH连接正常"
else
    echo "✗ SSH连接失败或未配置"
fi
echo ""

# 4. 检查代理设置
echo "4. 检查代理设置..."
http_proxy=$(git config --global --get http.proxy)
https_proxy=$(git config --global --get https.proxy)

if [ -z "$http_proxy" ] && [ -z "$https_proxy" ]; then
    echo "✓ 未设置Git代理"
else
    echo "Git代理配置:"
    echo "  HTTP: $http_proxy"
    echo "  HTTPS: $https_proxy"
fi
echo ""

# 5. 检查远程仓库URL
echo "5. 检查远程仓库URL..."
git remote -v
echo ""

# 6. 建议
echo "=== 建议的解决方案 ==="
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✓ SSH已配置，建议使用SSH URL"
    echo "  运行: git remote set-url origin git@github.com:wfh168/ops.git"
else
    echo "建议配置SSH密钥："
    echo "  1. ssh-keygen -t ed25519 -C 'your_email@example.com'"
    echo "  2. cat ~/.ssh/id_ed25519.pub (复制公钥)"
    echo "  3. 添加到 https://github.com/settings/keys"
    echo "  4. git remote set-url origin git@github.com:wfh168/ops.git"
fi
```

---

## 快速修复命令（推荐）

### 最快的解决方案：

```bash
# 1. 生成SSH密钥（如果没有）
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519 -N ""

# 2. 显示公钥（复制并添加到GitHub）
cat ~/.ssh/id_ed25519.pub

# 3. 修改远程URL为SSH
git remote set-url origin git@github.com:wfh168/ops.git

# 4. 测试连接
ssh -T git@github.com

# 5. 推送代码
git push origin main
```

---

## 常见错误和解决方法

### 错误1：Connection timeout

```bash
# 解决方法：使用SSH或配置代理
git remote set-url origin git@github.com:wfh168/ops.git
```

### 错误2：SSL certificate problem

```bash
# 临时解决（不推荐）
git config --global http.sslVerify false

# 更新CA证书（推荐）
sudo apt update
sudo apt install ca-certificates
```

### 错误3：Port 443: Connection refused

```bash
# 使用SSH的443端口
vim ~/.ssh/config

# 添加：
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
```

### 错误4：Permission denied (publickey)

```bash
# 检查SSH密钥
ssh-add -l

# 如果为空，添加密钥
ssh-add ~/.ssh/id_ed25519

# 测试连接
ssh -vT git@github.com
```

---

## 验证修复

```bash
# 1. 检查远程URL
git remote -v

# 2. 测试连接
ssh -T git@github.com

# 3. 推送测试
git push origin main --dry-run

# 4. 实际推送
git push origin main
```

---

## 推荐配置

### 完整的Git配置：

```bash
# 基础配置
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"

# 使用SSH
git config --global url."git@github.com:".insteadOf "https://github.com/"

# 性能优化
git config --global http.postBuffer 524288000
git config --global core.compression 0

# 凭证缓存
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=3600'
```

---

## 总结

推荐的解决顺序：

1. **首选方案**：配置SSH密钥，使用SSH协议
2. **备选方案**：配置代理（如果有）
3. **临时方案**：使用Gitee等镜像站
4. **最后方案**：修改hosts文件

SSH方式最稳定可靠，强烈推荐使用！