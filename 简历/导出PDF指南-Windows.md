# Windows系统简历导出PDF指南

## 方法一：使用浏览器直接打印（推荐）

这是最简单的方法，无需安装额外软件。

### 步骤：
1. 双击打开 `resume1.html` 文件（会在默认浏览器中打开）
2. 按 `Ctrl + P` 打开打印对话框
3. 在"目标打印机"中选择"另存为 PDF"或"Microsoft Print to PDF"
4. 点击"保存"按钮
5. 选择保存位置，输入文件名（如：吴付红-运维工程师简历.pdf）
6. 点击"保存"完成

### 浏览器推荐设置：
- **Chrome/Edge**：
  - 布局：纵向
  - 页边距：默认
  - 背景图形：勾选（保留样式）
  - 缩放：100%

## 方法二：使用wkhtmltopdf工具

### 安装步骤：
1. 下载 wkhtmltopdf for Windows：
   ```
   https://wkhtmltopdf.org/downloads.html
   ```
   选择 Windows 64-bit 版本

2. 安装到默认路径（如：`C:\Program Files\wkhtmltopdf`）

3. 添加到系统环境变量（可选）：
   - 右键"此电脑" → "属性" → "高级系统设置"
   - "环境变量" → 编辑 Path
   - 添加：`C:\Program Files\wkhtmltopdf\bin`

### 使用命令：
打开 PowerShell 或 CMD，进入简历文件夹：

```bash
cd 简历
wkhtmltopdf resume1.html 吴付红-运维工程师简历.pdf
```

### 高级参数：
```bash
wkhtmltopdf --page-size A4 --margin-top 10mm --margin-bottom 10mm --margin-left 10mm --margin-right 10mm --enable-local-file-access resume1.html 吴付红-运维工程师简历.pdf
```

## 方法三：使用在线转换工具

如果不想安装软件，可以使用在线工具：

1. **HTML to PDF Converter**：https://www.html2pdf.com/
2. **CloudConvert**：https://cloudconvert.com/html-to-pdf
3. **PDF24 Tools**：https://tools.pdf24.org/zh/html-to-pdf

### 步骤：
1. 上传 `resume1.html` 文件
2. 同时上传 `resume.css` 文件（保持样式）
3. 点击转换
4. 下载生成的 PDF 文件

## 关于gtk3-runtime的说明

gtk3-runtime 主要用于 Linux 系统，在 Windows 上不太适用。推荐使用上述三种方法。

如果您坚持使用 gtk3-runtime：
1. 需要安装 MSYS2 或 Cygwin 环境
2. 安装 GTK3 开发库
3. 使用 Python + WeasyPrint 库

但这个过程较为复杂，不推荐在 Windows 上使用。

## 推荐方案

**最佳方案**：使用 Chrome 或 Edge 浏览器的"打印为PDF"功能
- ✅ 无需安装额外软件
- ✅ 样式保留完整
- ✅ 操作简单快捷
- ✅ 生成的PDF质量高

## 验证PDF效果

导出后请检查：
- ✅ 页面布局是否完整
- ✅ 字体是否清晰
- ✅ 颜色是否正确
- ✅ 头像图片是否显示
- ✅ 技能标签样式是否保留

## 常见问题

### Q1: PDF中头像不显示？
A: 确保 `简历附件.assets/wps1.jpg` 文件存在，使用相对路径。

### Q2: 样式丢失？
A: 确保 `resume.css` 文件与 `resume1.html` 在同一目录。

### Q3: 中文显示乱码？
A: 使用浏览器打印时，确保选择了支持中文的字体。

### Q4: PDF文件过大？
A: 压缩图片大小，或使用在线PDF压缩工具。

## 文件清单

导出前确保以下文件完整：
```
简历/
├── resume1.html          # 简历HTML文件
├── resume.css            # 样式文件
└── 简历附件.assets/
    └── wps1.jpg          # 头像图片
```

---

**提示**：建议使用 Chrome 或 Edge 浏览器的"打印为PDF"功能，这是最简单且效果最好的方法！
