# Tailscale DERP Server - 一键安装脚本

本项目提供一个**一键安装脚本**，用于在 Linux 服务器上快速部署 Tailscale DERP 中继服务器。

## 特色功能

- 🌍 **智能区域检测** - 自动识别国内/海外服务器，选择最佳下载源
- 🚀 **一键部署** - 自动安装 Go 环境、编译并启动 DERP 服务
- 🔒 **IP 地址部署** - 自动获取公网 IP，生成自签名证书

## 快速开始

### 系统要求
- Ubuntu 18.04+ 或 CentOS 7+
- sudo 权限
- 能够访问互联网

### 一键安装

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/DrayChou/derper-ip/master/install_derper.sh | bash
```

或者分步执行：

```bash
# 下载脚本
wget https://raw.githubusercontent.com/DrayChou/derper-ip/master/install_derper.sh

# 运行安装
chmod +x install_derper.sh
./install_derper.sh
```

## 配置选项

修改脚本开头的配置项：

```bash
DERP_PORT=9003      # DERP 服务端口
STUN_PORT=9004      # STUN 服务端口
CERT_DIR="./"       # 证书存放目录
```

## 防火墙配置

安装完成后，确保开放对应端口：

```bash
# Ubuntu/Debian
sudo ufw allow 9003/tcp
sudo ufw allow 9004/udp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=9003/tcp
sudo firewall-cmd --permanent --add-port=9004/udp
sudo firewall-cmd --reload
```

**云服务器用户**：还需要在云控制台的安全组中开放这些端口。

## 后台运行

脚本默认前台运行，如需后台运行：

```bash
# 使用 nohup
nohup ./install_derper.sh > derper.log 2>&1 &

# 或创建 systemd 服务
sudo tee /etc/systemd/system/derper.service << EOF
[Unit]
Description=Tailscale DERP Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/derper --hostname=YOUR_SERVER_IP -certmode manual -certdir /opt/derper/certs -http-port -1 -a :9003 -stun-port 9004 -verify-clients
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable derper
sudo systemctl start derper
```

## 常见问题

**安装失败？**
- 检查网络连接：`curl -I https://mirrors.aliyun.com/golang/`
- 检查sudo权限：`sudo -v`

**端口被占用？**
- 检查端口：`lsof -i :9003`
- 修改脚本中的端口配置

**测试服务是否正常？**
```bash
# 检查进程
ps aux | grep derper

# 测试连接
curl -k https://YOUR_SERVER_IP:9003/derp/probe
```

## 脚本功能

1. **智能下载源**：国内服务器自动使用阿里云镜像
2. **Go环境管理**：自动安装最新版Go并配置环境
3. **DERP编译**：编译最新版Tailscale DERP服务
4. **自动配置**：获取公网IP并启动服务

---

**问题反馈**：[GitHub Issues](https://github.com/DrayChou/derper-ip/issues)