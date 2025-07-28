# 更新日志

## [未发布]

### 新增
- 🚀 跨平台二进制文件支持（Linux, Windows, macOS, FreeBSD）
- 🎯 GitHub Actions 自动化构建和发布
- 📋 部署脚本套件（start.sh, start.bat, deploy.sh）
- 🔄 Linux systemd 服务集成
- ⚙️ 环境变量和命令行参数配置
- 📚 完整的中文文档和使用指南

### 改进
- 🔒 简化的 IP 地址部署，自动生成自签名证书
- 🐳 保留 Docker 部署作为备选方案
- 📦 优化的 GitHub Actions 工作流，无需 Docker
- 🛡️ 安全的默认配置（启用客户端验证）

### 技术细节
- 基于 Tailscale derper v1.82.1
- Go 1.24 交叉编译
- 静态链接二进制文件
- CGO_ENABLED=0 确保兼容性

## 项目初始化

### Docker 版本
- 🐳 Docker 多阶段构建
- 🔧 Docker Compose 配置
- 📊 健康检查和监控
- 🔒 Let's Encrypt 和手动证书支持

---

**格式说明**: 本变更日志遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 规范。