# Linux 基础命令学习指南

## 学习路线

```
01_目录操作命令.md    ──▶  掌握 cd/ls/pwd/mkdir 等目录操作
        │
        ▼
02_文件操作命令.md    ──▶  掌握 cp/mv/rm/cat/less 等文件操作
        │
        ▼
03_查找与帮助命令.md  ──▶  掌握 find/locate/man 等查找帮助
        │
        ▼
04_压缩与打包命令.md  ──▶  掌握 tar/gzip/zip 等压缩打包
        │
        ▼
05_系统信息与进程.md  ──▶  掌握 ps/top/kill/systemctl 等
        │
        ▼
06_网络与下载命令.md  ──▶  掌握 ping/curl/wget/ssh/scp 等
        │
        ▼
07_管道与重定向.md    ──▶  掌握 |、>、>>、xargs 等组合技巧
```

## 文件清单

| 文件 | 内容 | 预计学习时间 |
|------|------|--------------|
| 01_目录操作命令.md | pwd/cd/ls/mkdir/rmdir/tree | 0.5 天 |
| 02_文件操作命令.md | touch/cp/mv/rm/cat/less/head/tail | 1 天 |
| 03_查找与帮助命令.md | find/locate/which/man/help/history | 1 天 |
| 04_压缩与打包命令.md | tar/gzip/bzip2/xz/zip | 0.5 天 |
| 05_系统信息与进程命令.md | uname/free/df/ps/top/kill/systemctl | 1 天 |
| 06_网络与下载命令.md | ping/curl/wget/ssh/scp/ss/ip | 1 天 |
| 07_管道与重定向.md | 重定向/管道/xargs/命令组合 | 0.5 天 |

## 学习建议

1. 边学边练：每个命令都要在终端实际操作
2. 做好笔记：记录自己踩过的坑
3. 多用 man：遇到不懂的参数查手册
4. 组合使用：命令的威力在于组合

## 必须熟练的命令

```bash
# 这些命令要做到闭着眼睛都能敲
cd / ls / pwd / mkdir -p / rm -rf
cp -a / mv / cat / less / tail -f
find / grep / ps aux / kill
tar -czvf / tar -xzvf
ssh / scp / curl / wget
```

## 下一步

完成基础命令学习后，进入「文件属性」模块，理解 Linux 文件系统的核心概念。
