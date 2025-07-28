#!/bin/bash
#
# 这是一个自动化脚本，用于在 Linux (Ubuntu/CentOS) 系统上：
# 1. 自动检测服务器区域，智能选择国内/国际源
# 2. 卸载旧版本的 Go
# 3. 安装最新版本的 Go
# 4. 编译 Tailscale 的 derper 中继服务器
# 5. 使用服务器的公网 IP 启动 derper 服务
#

# --- 配置项 ---
# 您可以根据需要修改这些端口
DERP_PORT=9003
STUN_PORT=9004
CERT_DIR="./" # 证书存放目录，默认为当前目录

# --- 脚本设置 ---
# 如果任何命令执行失败，立即退出脚本
set -e
# 全局变量，用于标记服务器位置
IS_CHINA_SERVER=false

# --- 辅助函数 ---
# 打印信息
print_info() {
    echo -e "\n\033[34m[信息]\033[0m $1"
}

# 打印成功信息
print_success() {
    echo -e "\033[32m[成功]\033[0m $1"
}

# 打印错误信息并退出
print_error() {
    # 将错误信息输出到 stderr
    echo -e "\033[31m[错误]\033[0m $1" >&2
    exit 1
}

# 新增：检测服务器所在区域
check_location() {
    print_info "正在检测服务器所在区域..."
    local country_code
    # 使用 --connect-timeout 避免长时间等待
    country_code=$(curl -s --connect-timeout 5 ipinfo.io/country)
    
    if [ "$country_code" == "CN" ]; then
        print_success "检测到服务器位于中国大陆区域，将优先使用国内镜像源。"
        IS_CHINA_SERVER=true
    else
        print_success "服务器不在中国大陆区域，将优先使用全球官方源。"
    fi
}

# 更新：根据区域获取最新 Go 版本号
get_latest_go_version() {
    local version
    if [ "$IS_CHINA_SERVER" = true ]; then
        # 将提示信息输出到 stderr，避免被变量捕获
        print_info "正在从 mirrors.aliyun.com (国内源) 获取最新的 Go 版本号..." >&2
        version=$(curl -s https://mirrors.aliyun.com/golang/ | grep -oP 'go([0-9\.]+)\.linux-amd64\.tar\.gz' | sort -V | tail -n 1 | sed -e 's/go//' -e 's/\.linux-amd64\.tar\.gz//')
    else
        print_info "正在从 go.dev (主源) 获取最新的 Go 版本号..." >&2
        version=$(curl -s https://go.dev/dl/ | grep -oP 'go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 | sed -e 's/go//' -e 's/\.linux-amd64\.tar\.gz//')
        
        if [ -z "$version" ]; then
            print_info "主源获取失败，正在尝试从 mirrors.aliyun.com (备用源) 获取..." >&2
            version=$(curl -s https://mirrors.aliyun.com/golang/ | grep -oP 'go([0-9\.]+)\.linux-amd64\.tar\.gz' | sort -V | tail -n 1 | sed -e 's/go//' -e 's/\.linux-amd64\.tar\.gz//')
        fi
    fi

    if [ -z "$version" ]; then
        print_error "无法从任何源获取最新的 Go 版本号，请检查网络连接。"
    else
        # 只将最终的版本号输出到 stdout
        echo "$version"
    fi
}

# 更新：根据区域获取公网 IP
get_public_ip() {
    local ip
    # 如果是国内服务器，优先使用国内IP查询服务
    if [ "$IS_CHINA_SERVER" = true ]; then
        print_info "正在尝试从 myip.ipip.net (国内源) 获取公网 IP..." >&2
        # myip.ipip.net 返回格式: 当前 IP：1.2.3.4 来自于...
        ip=$(curl -s myip.ipip.net | awk '{print $3}')
        [ -n "$ip" ] && echo "$ip" && return
    fi

    # 全球通用源 (也作为国内服务器的备用)
    print_info "正在尝试从 ifconfig.me 获取公网 IP..." >&2
    ip=$(curl -s ifconfig.me)
    [ -n "$ip" ] && echo "$ip" && return

    print_info "ifconfig.me 失败，正在尝试从 icanhazip.com 获取..." >&2
    ip=$(curl -s icanhazip.com)
    [ -n "$ip" ] && echo "$ip" && return
    
    print_error "无法从任何源获取公网 IP 地址，请检查网络。"
}


# --- 主逻辑 ---

# 0. 检查 sudo 权限
print_info "检查超级用户权限..."
if [ "$(id -u)" -ne 0 ]; then
    print_info "此脚本需要超级用户（sudo）权限来安装软件和配置系统。"
    sudo -v # 提前请求密码
    if [ $? -ne 0 ]; then
        print_error "获取 sudo 权限失败，脚本退出。"
    fi
fi

# 1. 检测服务器位置
check_location

# 2. 卸载已有的 Go 版本
print_info "正在检查并卸载旧的 Go 版本..."
if command -v go &> /dev/null; then
    print_info "检测到已安装的 Go，将尝试卸载..."
    # 移除手动安装的 Go
    if [ -d "/usr/local/go" ]; then
        print_info "正在移除 /usr/local/go 目录..."
        sudo rm -rf /usr/local/go
    fi
    # 尝试通过包管理器卸载
    if command -v apt-get &> /dev/null; then
        sudo apt-get remove -y golang-go > /dev/null 2>&1
        sudo apt-get purge -y golang-go > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum remove -y golang > /dev/null 2>&1
    fi
    print_success "旧版本 Go 已卸载。"
else
    print_info "未检测到已安装的 Go，将直接进行安装。"
fi

# 3. 安装最新的 Go 版本
LATEST_GO_VERSION=$(get_latest_go_version)

print_info "最新的 Go 版本为: $LATEST_GO_VERSION"
GO_FILENAME="go${LATEST_GO_VERSION}.linux-amd64.tar.gz"
DOWNLOAD_URL="https://mirrors.aliyun.com/golang/${GO_FILENAME}"

print_info "正在从阿里云镜像下载 Go $LATEST_GO_VERSION..."
wget -q --show-progress "$DOWNLOAD_URL"

print_info "正在解压 Go 到 /usr/local 目录..."
sudo tar -C /usr/local -xzf "$GO_FILENAME"

print_info "清理下载的临时文件..."
rm "$GO_FILENAME"

# 4. 为当前会话配置环境变量
print_info "为当前会话配置 Go 环境变量..."
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# 验证 Go 是否安装成功
print_info "验证 Go 安装..."
if ! command -v go &> /dev/null; then
    print_error "安装后未找到 go 命令，安装过程可能出错。"
fi
go version

print_success "Go $LATEST_GO_VERSION 安装成功！"
print_info "要使环境变量永久生效，请将以下内容添加到您的 ~/.bashrc 或 ~/.zshrc 文件中:"
echo -e "\033[33m"
echo 'export PATH=$PATH:/usr/local/go/bin'
echo 'export GOPATH=$HOME/go'
echo 'export PATH=$PATH:$GOPATH/bin'
echo -e "\033[0m"
print_info "然后执行 'source ~/.bashrc' 或 'source ~/.zshrc' 使其生效。"

# 5. 编译 derper
print_info "正在安装/更新 derper..."
# 如果是国内服务器，自动设置 Go 代理
if [ "$IS_CHINA_SERVER" = true ]; then
    print_info "检测到国内服务器，为 'go install' 设置国内代理..."
    go env -w GOPROXY=https://goproxy.cn,direct
fi
go install tailscale.com/cmd/derper@latest

DERPER_PATH="$HOME/go/bin/derper"
if [ -f "$DERPER_PATH" ]; then
    print_info "正在将 derper 移动到 /usr/local/bin/ ..."
    sudo cp "$DERPER_PATH" /usr/local/bin/
    print_success "derper 已安装到 /usr/local/bin/derper"
else
    print_error "derper 编译失败，未在 $DERPER_PATH 找到二进制文件。"
fi

# 6. 获取公网 IP
PUBLIC_IP=$(get_public_ip)
print_success "检测到公网 IP: $PUBLIC_IP"

# 7. 启动 derper 服务
print_info "准备启动 derper 服务..."
echo "------------------------------------------------------------------"
print_info "主机名 (Hostname): $PUBLIC_IP"
print_info "DERP 端口 (TCP): $DERP_PORT"
print_info "STUN 端口 (UDP): $STUN_PORT"
print_info "证书目录 (Cert Dir): $CERT_DIR"
print_info "请确保您的防火墙已放行 TCP 端口 $DERP_PORT 和 UDP 端口 $STUN_PORT"
echo "------------------------------------------------------------------"
print_info "现在将启动 derper 服务，按 Ctrl+C 停止。"

# 执行启动命令
# 注意：此命令将在前台运行，关闭终端将导致服务停止。
# 如需后台运行，请考虑使用 systemd 或 nohup。
sudo /usr/local/bin/derper --hostname="$PUBLIC_IP" -certmode manual -certdir "$CERT_DIR" -http-port -1 -a ":$DERP_PORT" -stun-port "$STUN_PORT" -verify-clients
