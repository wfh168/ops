# SSH连接时Vim粘贴格式错误解决方案

## 问题描述
在SSH连接服务器时，使用vim编辑文件，右键粘贴或Ctrl+Shift+V粘贴时出现格式错误，通常表现为：
- 粘贴内容前后出现奇怪字符
- 缩进格式混乱
- 出现 `0~` 或 `1~` 等字符

## 原因分析
这是由于终端的"括号粘贴模式"(Bracketed Paste Mode)导致的，vim会在粘贴内容前后添加特殊字符来标识粘贴操作。

## 解决方案

### 方案1：在vim中使用粘贴模式（推荐）

#### 临时解决
```bash
# 在vim中进入插入模式前，先设置粘贴模式
:set paste
# 然后进入插入模式粘贴
i
# 粘贴完成后退出插入模式，关闭粘贴模式
:set nopaste
```

#### 永久配置vim
```bash
# 编辑vim配置文件
vim ~/.vimrc

# 添加以下配置
set pastetoggle=<F2>
set clipboard=unnamedplus
```

使用方法：
- 按F2开启粘贴模式
- 进入插入模式粘贴内容
- 按F2关闭粘贴模式

### 方案2：优化Alacritty配置

在你的 `alacritty.toml` 中添加以下配置：

```toml
# 在 [terminal] 部分添加
[terminal]
osc52 = "CopyPaste"

# 或者禁用括号粘贴模式
[terminal]
bracketed_paste = false
```

### 方案3：使用vim的内置粘贴功能

#### 使用系统剪贴板
```bash
# 在vim中直接粘贴系统剪贴板内容
"+p    # 在光标后粘贴
"+P    # 在光标前粘贴

# 或者在插入模式下
<Ctrl+r>+  # 然后按回车
```

#### 配置vim支持系统剪贴板
```bash
# 检查vim是否支持剪贴板
vim --version | grep clipboard

# 如果显示 -clipboard，需要安装vim-gtk3
sudo apt install vim-gtk3

# 或者安装neovim（推荐）
sudo apt install neovim
```

### 方案4：使用更好的vim配置

创建一个优化的vim配置：

```bash
# 创建或编辑 ~/.vimrc
cat > ~/.vimrc << 'EOF'
" 基础设置
set number
set relativenumber
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set incsearch
set ignorecase
set smartcase

" 粘贴相关设置
set paste
set pastetoggle=<F2>
set clipboard=unnamedplus

" 鼠标支持
set mouse=a

" 语法高亮
syntax on

" 颜色主题
colorscheme default

" 状态栏
set laststatus=2
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]\ %{strftime(\"%d/%m/%y\ -\ %H:%M\")}

" 文件编码
set encoding=utf-8
set fileencodings=utf-8,gbk,gb2312,big5

" 快捷键映射
" F2 切换粘贴模式
" F3 显示/隐藏行号
nnoremap <F3> :set nu! rnu!<CR>

" 更好的粘贴体验
if has('unnamedplus')
    set clipboard=unnamedplus
else
    set clipboard=unnamed
endif
EOF
```

### 方案5：使用tmux（推荐用于长期SSH会话）

```bash
# 安装tmux
sudo apt install tmux

# 创建tmux配置
cat > ~/.tmux.conf << 'EOF'
# 启用鼠标支持
set -g mouse on

# 设置剪贴板
set -g set-clipboard on

# 更好的粘贴体验
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
bind-key -T copy-mode-vi r send-keys -X rectangle-toggle

# 重新加载配置
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
EOF

# 启动tmux会话
tmux new-session -d -s main
tmux attach-session -t main
```

## 快速解决步骤

### 立即解决（临时）
```bash
# 在vim中执行
:set paste
# 然后粘贴内容
# 粘贴完成后执行
:set nopaste
```

### 永久解决（推荐）
```bash
# 1. 更新vim配置
echo 'set pastetoggle=<F2>' >> ~/.vimrc
echo 'set clipboard=unnamedplus' >> ~/.vimrc

# 2. 安装支持剪贴板的vim
sudo apt update
sudo apt install vim-gtk3 -y

# 3. 重新加载vim配置
source ~/.vimrc
```

## 验证解决方案

1. **测试粘贴模式**：
   ```bash
   vim test.txt
   # 按F2开启粘贴模式
   # 进入插入模式，粘贴内容
   # 按F2关闭粘贴模式
   ```

2. **测试系统剪贴板**：
   ```bash
   vim test.txt
   # 在正常模式下按 "+p 粘贴
   ```

3. **测试配置是否生效**：
   ```bash
   vim --version | grep clipboard
   # 应该显示 +clipboard
   ```

## 额外建议

### 使用更现代的编辑器
```bash
# 安装neovim（更现代的vim）
sudo apt install neovim

# 创建neovim配置
mkdir -p ~/.config/nvim
echo 'set clipboard=unnamedplus' > ~/.config/nvim/init.vim
echo 'set mouse=a' >> ~/.config/nvim/init.vim

# 使用nvim替代vim
alias vim=nvim
```

### SSH配置优化
```bash
# 在本地 ~/.ssh/config 中添加
Host your-server
    HostName 10.0.0.91
    User wfh
    ForwardX11 yes
    ForwardX11Trusted yes
```

这样配置后，SSH连接时的vim粘贴体验会大大改善！