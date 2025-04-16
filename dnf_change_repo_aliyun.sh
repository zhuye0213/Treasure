#!/bin/bash
set -o errexit

# 配置
# 注意：“# baseurl” 中间有个空格（AlmaLinux 专有）
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^# baseurl=https://repo.almalinux.org|baseurl=https://mirrors.aliyun.com|g' \
    -i.bak \
    /etc/yum.repos.d/almalinux*.repo

# 恢复 (sysin)
sed -e 's|^#mirrorlist=|mirrorlist=|g' \
    -e 's|^baseurl=https://mirrors.aliyun.com|# baseurl=https://repo.almalinux.org|g' \
    -i.bak \
    /etc/yum.repos.d/almalinux*.repo