# Tailscale DERP Server Docker Deployment

这个项目提供了一个完整的 Tailscale DERP 服务器 Docker 部署方案，支持使用 IP 地址和自签名证书进行部署，无需域名和 SSL 证书。

## 灵感来源

本项目的实现基于以下文章的指导：
- [Tailscale官方支持纯IP部署DERP中继服务器](https://fuguebit.com/2025/05/tailscale%E5%AE%98%E6%96%B9%E6%94%AF%E6%8C%81%E7%BA%AFip%E9%83%A8%E7%BD%B2derp%E4%B8%AD%E7%BB%A7%E6%9C%8D%E5%8A%A1%E5%99%A8/)

## 功能特性

- 🚀 基于官方 Tailscale DERP 服务器
- 🔒 支持 IP 地址部署，无需域名
- 📝 自动生成自签名证书
- ⚙️ 完全可配置的参数
- 🐳 Docker 容器化部署
- 📊 健康检查和日志记录
- 🔄 自动重启机制

## 快速开始

### 1. 克隆或创建项目

确保你的目录结构如下：
```
derp/
├── Dockerfile
├── docker-compose.yml
├── start.sh
├── .env.example
└── README.md
```

### 2. 配置环境变量

复制示例配置文件：
```bash
cp .env.example .env
```

编辑 `.env` 文件，修改为你的服务器 IP：
```bash
# 替换为你的服务器公网 IP
DERP_HOSTNAME=88.88.88.88
DERP_HTTP_PORT=9003
DERP_STUN_PORT=9004
```

### 3. 部署服务

```bash
# 构建并启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f derper

# 查看服务状态
docker-compose ps
```

### 4. 防火墙配置

确保服务器防火墙开放端口：
- TCP 9003 (HTTP)
- UDP 9004 (STUN)

## 配置参数

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `DERP_HOSTNAME` | localhost | DERP 服务器主机名或 IP 地址 |
| `DERP_HTTP_PORT` | 9003 | HTTP 服务端口 |
| `DERP_STUN_PORT` | 9004 | STUN 服务端口 |
| `DERP_VERIFY_CLIENTS` | false | 是否验证客户端 |
| `DERP_CERT_MODE` | manual | 证书模式 (manual/letsencrypt) |
| `DERP_CERT_DIR` | /var/lib/derper | 证书存储目录 |
| `DERP_LOG_LEVEL` | info | 日志级别 (info/debug) |

## 获取 DERP 服务器信息

启动服务后，查看日志获取服务器信息：

```bash
docker-compose logs derper
```

在日志中找到类似以下的信息：
```
DERP server: region 999 is http://88.88.88.88:9003/derp with key [base64-encoded-key]
```

这些信息需要添加到 Tailscale 的 Access Controls 中。

## Tailscale 客户端配置

### 1. 获取服务器密钥

从日志中复制 base64 编码的密钥。

### 2. 配置 Access Controls

在 Tailscale 控制台的 Access Controls 中添加：

```json
{
  "derpMap": {
    "regions": {
      "999": {
        "regionId": 999,
        "regionCode": "custom",
        "regionName": "Custom DERP",
        "nodes": [
          {
            "name": "custom-derp",
            "regionId": 999,
            "hostname": "88.88.88.88",
            "ipv4": "88.88.88.88",
            "derpport": 9003,
            "stunport": 9004,
            "stunonly": false,
            "derpTestPort": 0,
            "key": "your-base64-encoded-key-here"
          }
        ]
      }
    }
  }
}
```

## 维护命令

```bash
# 查看容器状态
docker-compose ps

# 查看实时日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 完全清理（包括数据卷）
docker-compose down -v

# 重新构建镜像
docker-compose build --no-cache
```

## 故障排除

### 1. 端口被占用

检查端口是否已被使用：
```bash
netstat -tulpn | grep :9003
netstat -tulpn | grep :9004
```

### 2. 证书问题

清理证书重新生成：
```bash
docker-compose down
docker volume rm derp_derper_data
docker-compose up -d
```

### 3. 防火墙问题

确保防火墙规则正确：
```bash
# Ubuntu/Debian
sudo ufw allow 9003/tcp
sudo ufw allow 9004/udp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=9003/tcp
sudo firewall-cmd --permanent --add-port=9004/udp
sudo firewall-cmd --reload
```

## 性能优化

### 1. 资源限制

在 `docker-compose.yml` 中添加资源限制：
```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 512M
    reservations:
      cpus: '0.1'
      memory: 128M
```

### 2. 日志轮转

配置日志轮转防止日志文件过大：
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 安全建议

1. 定期更新镜像：`docker-compose pull && docker-compose up -d`
2. 使用非 root 用户运行（已在 Dockerfile 中配置）
3. 限制网络访问（仅开放必要端口）
4. 启用防火墙和入侵检测
5. 定期备份配置和证书

## 许可证

本项目基于 MIT 许可证开源。Tailscale DERP 服务器遵循其自身的许可证条款。