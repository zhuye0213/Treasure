#!/bin/bash
set -o errexit

cat > ~/.ssh/authorized_keys << "EOF"
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBDVHW9f6AltHAJ4d5IBB386aJAJGAhGHmhjluQlbQm
EOF
chmod 600 ~/.ssh/authorized_keys
cat > /etc/ssh/sshd_config.d/PubkeyAuthentication.conf << "EOF"
PubkeyAuthentication yes
EOF
systemctl restart sshd
