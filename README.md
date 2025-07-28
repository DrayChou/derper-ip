# Tailscale DERP Server - 跨平台部署方案

[![Build Status](https://github.com/your-username/derper-ip/workflows/Build%20Cross-Platform%20Binaries/badge.svg)](https://github.com/your-username/derper-ip/actions)
[![Release](https://img.shields.io/github/v/release/your-username/derper-ip)](https://github.com/your-username/derper-ip/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

本项目提供 **跨平台二进制文件** 和 **Docker 部署** 两种方案，用于部署 Tailscale DERP (Designated Encrypted Relay for Packets) 服务器。DERP 服务器帮助 Tailscale 客户端在无法直接连接时进行通信。

## ✨ 项目特色

- 🚀 **跨平台二进制文件** - Linux, Windows, macOS, FreeBSD
- 🐳 **Docker 部署选项** - 支持容器化部署
- 🔒 **IP 地址部署** - 自动生成自签名证书，无需域名
- ⚙️ **简单配置** - 环境变量或命令行参数
- 🔄 **systemd 集成** - Linux 生产环境服务管理
- 🎯 **GitHub Actions** - 自动化跨平台编译
- 📋 **部署脚本** - 开箱即用的启动和部署脚本

## 🚀 快速开始

### 方案一：二进制文件部署（推荐）

#### 1. 下载二进制文件

从 [Releases 页面](../../releases) 下载适合你系统的二进制文件：

```bash
# Linux AMD64
wget https://github.com/your-username/derper-ip/releases/latest/download/derper-linux-amd64.tar.gz
tar -xzf derper-linux-amd64.tar.gz
cd derper-linux-amd64

# Windows AMD64 (PowerShell)
Invoke-WebRequest -Uri "https://github.com/your-username/derper-ip/releases/latest/download/derper-windows-amd64.zip" -OutFile "derper-windows-amd64.zip"
Expand-Archive derper-windows-amd64.zip
cd derper-windows-amd64
```

#### 2. 快速启动

```bash
# Linux/macOS/FreeBSD
./start.sh 你的服务器IP 9003 9004

# Windows
start.bat 你的服务器IP 9003 9004

# 示例
./start.sh 88.88.88.88 9003 9004
```

#### 3. 生产环境部署（Linux）

```bash
# 使用 systemd 管理服务
sudo ./deploy.sh 88.88.88.88 9003 9004

# 查看服务状态
sudo systemctl status derper
sudo journalctl -u derper -f
```

### 方案二：Docker 部署

#### 1. 准备配置文件

```bash
git clone https://github.com/your-username/derper-ip.git
cd derper-ip
cp .env.example .env
```

#### 2. 编辑配置

```bash
# 编辑 .env 文件
DERP_HOSTNAME=88.88.88.88    # 你的服务器IP
DERP_HTTP_PORT=9003
DERP_STUN_PORT=9004
DERP_VERIFY_CLIENTS=true
```

#### 3. 启动服务

```bash
docker-compose up -d

# 查看日志
docker-compose logs -f derp
```

## 📦 支持平台

| 平台 | 架构 | 二进制文件名 |
|------|------|-------------|
| **Linux** | AMD64 | `derper-linux-amd64` |
| **Linux** | ARM64 | `derper-linux-arm64` |
| **Linux** | ARMv7 | `derper-linux-armv7` |
| **Windows** | AMD64 | `derper-windows-amd64.exe` |
| **Windows** | ARM64 | `derper-windows-arm64.exe` |
| **macOS** | Intel | `derper-darwin-amd64` |
| **macOS** | Apple Silicon | `derper-darwin-arm64` |
| **FreeBSD** | AMD64 | `derper-freebsd-amd64` |

## ⚙️ 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `DERP_HOSTNAME` | `localhost` | 服务器 IP 地址或主机名 |
| `DERP_HTTP_PORT` | `9003` | HTTP 服务端口 |
| `DERP_STUN_PORT` | `9004` | STUN 服务端口 |
| `DERP_VERIFY_CLIENTS` | `true` | 是否验证客户端证书 |

### 命令行参数

```bash
# 基本用法
./derper-linux-amd64 --hostname=YOUR_IP -certmode manual -certdir ./ -http-port -1 -a :9003 -stun-port 9004 -verify-clients

# 使用启动脚本
./start.sh [hostname] [http_port] [stun_port]
./deploy.sh [hostname] [http_port] [stun_port]
```

## 🔧 部署详解

### Linux 生产环境

```bash
# 1. 下载并解压
wget https://github.com/your-username/derper-ip/releases/latest/download/derper-linux-amd64.tar.gz
tar -xzf derper-linux-amd64.tar.gz
cd derper-linux-amd64

# 2. 部署为 systemd 服务
sudo ./deploy.sh 88.88.88.88 9003 9004

# 3. 服务管理
sudo systemctl status derper      # 查看状态
sudo systemctl restart derper     # 重启服务
sudo systemctl stop derper        # 停止服务
sudo journalctl -u derper -f      # 查看日志
```

### Windows 服务器

```cmd
REM 1. 解压文件到目录
unzip derper-windows-amd64.zip
cd derper-windows-amd64

REM 2. 前台运行测试
start.bat 88.88.88.88 9003 9004

REM 3. 使用 PM2 管理（需先安装 Node.js 和 PM2）
pm2 start "derper-windows-amd64.exe --hostname=88.88.88.88 -certmode manual -certdir ./certs -http-port -1 -a :9003 -stun-port 9004 -verify-clients" --name derper
pm2 save
pm2 startup
```

### macOS/FreeBSD

```bash
# 1. 下载并解压
curl -L -o derper-darwin-amd64.tar.gz https://github.com/your-username/derper-ip/releases/latest/download/derper-darwin-amd64.tar.gz
tar -xzf derper-darwin-amd64.tar.gz
cd derper-darwin-amd64

# 2. 快速启动
./start.sh 88.88.88.88 9003 9004

# 3. 后台运行
nohup ./start.sh 88.88.88.88 9003 9004 > derper.log 2>&1 &
```

## 🌐 网络配置

### 防火墙设置

```bash
# Linux (ufw)
sudo ufw allow 9003/tcp
sudo ufw allow 9004/udp

# Linux (iptables)
sudo iptables -A INPUT -p tcp --dport 9003 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 9004 -j ACCEPT

# Windows (PowerShell 管理员)
New-NetFirewallRule -DisplayName "DERP HTTP" -Direction Inbound -Protocol TCP -LocalPort 9003 -Action Allow
New-NetFirewallRule -DisplayName "DERP STUN" -Direction Inbound -Protocol UDP -LocalPort 9004 -Action Allow
```

### 端口说明

| 端口 | 协议 | 用途 | 必须开放 |
|------|------|------|----------|
| 9003 | TCP | DERP HTTP 服务 | ✅ 是 |
| 9004 | UDP | STUN 服务 | ✅ 是 |

## 🔒 证书管理

### 自动生成（推荐）

使用 IP 地址作为主机名时，DERP 服务器会自动生成自签名证书：

```bash
# 证书会保存在 certs/ 目录
ls certs/
# 88.88.88.88.crt
# 88.88.88.88.key
```

### 自定义证书

如需使用自定义证书，将证书文件放在 `certs` 目录：

```bash
mkdir -p certs
# 复制你的证书文件
cp your-cert.crt certs/
cp your-cert.key certs/
```

## 🔍 故障排除

### 常见问题

1. **端口占用**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep :9003
   netstat -ulnp | grep :9004
   ```

2. **权限问题**
   ```bash
   # 确保二进制文件有执行权限
   chmod +x derper-linux-amd64
   chmod +x start.sh deploy.sh
   ```

3. **防火墙阻止**
   ```bash
   # 临时关闭防火墙测试
   sudo ufw disable  # Ubuntu
   sudo systemctl stop firewalld  # CentOS
   ```

### 日志查看

```bash
# systemd 服务日志
sudo journalctl -u derper -f

# Docker 日志
docker-compose logs -f derp

# 直接运行时的日志
./start.sh 88.88.88.88 9003 9004 > derper.log 2>&1
```

## 🏗️ 构建说明

### 本地构建

```bash
# 克隆项目
git clone https://github.com/your-username/derper-ip.git
cd derper-ip

# 安装 Go 1.24+
# 直接编译当前平台
go install tailscale.com/cmd/derper@v1.82.1

# 交叉编译其他平台
GOOS=linux GOARCH=amd64 go install tailscale.com/cmd/derper@v1.82.1
GOOS=windows GOARCH=amd64 go install tailscale.com/cmd/derper@v1.82.1
```

### GitHub Actions

项目包含两个工作流：

- **构建测试** (`.github/workflows/build-binaries.yml`) - 每次推送都会测试构建
- **发布版本** (`.github/workflows/release-binaries.yml`) - 创建 tag 时自动构建并发布

创建发布版本：

```bash
# 创建并推送 tag
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions 会自动构建所有平台的二进制文件并创建 Release
```

## 🤝 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Tailscale](https://tailscale.com/) 团队提供优秀的 DERP 实现
- [Go](https://golang.org/) 团队提供强大的跨平台编译能力
- 社区贡献者们的支持和反馈

---

**⚡ 快速链接**
- [📥 下载二进制文件](../../releases)
- [🐛 报告问题](../../issues)
- [💬 讨论](../../discussions)
- [📚 Tailscale 文档](https://tailscale.com/kb/)