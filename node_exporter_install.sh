#!/bin/bash
set -euo pipefail

# 1. 安装依赖（优先使用 dnf，兼容 yum）
if command -v dnf &>/dev/null; then
    dnf install -y wget tar curl jq
else
    yum install -y wget tar curl
fi

# 2. 获取最新版本号（若 GitHub API 受限，可手动指定 VERSION="1.x.x"）
LATEST_TAG=$(curl -fsSL https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep -oE '"tag_name": "v[^"]+"' | cut -d'"' -f4)
VERSION="${LATEST_TAG#v}"
if [[ -z "$VERSION" ]]; then
    echo "无法自动获取最新版本号，请检查网络或手动指定 VERSION" >&2
    exit 1
fi

# 3. 检测架构并下载解压
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  GOARCH="amd64" ;;
    aarch64) GOARCH="arm64" ;;
    *)       echo "不支持的架构: $ARCH" >&2; exit 1 ;;
esac

PKG="node_exporter-${VERSION}.linux-${GOARCH}"
TARBALL="${PKG}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${TARBALL}"

cd /opt
wget -q --show-progress "$URL"
tar -xzf "$TARBALL"
ln -sfn "/opt/${PKG}/node_exporter" /usr/local/bin/node_exporter
rm -f "$TARBALL"

# 4. 创建专用低权限用户运行服务
if ! id -u node_exporter &>/dev/null; then
    useradd --no-create-home --shell /sbin/nologin node_exporter
fi
chown -R node_exporter:node_exporter "/opt/${PKG}"

# 5. 配置 systemd 服务
cat > /etc/systemd/system/node_exporter.service << "EOF"
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target
Wants=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node_exporter

# 6. 放行 9100 端口（仅在 firewalld 运行时生效）
if systemctl is-active --quiet firewalld; then
    firewall-cmd --zone=public --add-port=9100/tcp --permanent
    firewall-cmd --reload
fi

echo "node_exporter v${VERSION} 已启动并设置开机自启。"
