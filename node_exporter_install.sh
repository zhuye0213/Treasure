#!/bin/bash
set -o errexit
yum install -y wget
yum install -y tar
cd /opt
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.8.1.linux-amd64.tar.gz
cat > /etc/systemd/system/node_exporter.service << "EOF"
[Unit]
Description=node_export
Documentation=https://github.com/prometheus/node_exporter
 
[Service]
ExecStart=/opt/node_exporter-1.8.1.linux-amd64/node_exporter
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
firewall-cmd --zone=public --add-port=9100/tcp --permanent
firewall-cmd --reload
