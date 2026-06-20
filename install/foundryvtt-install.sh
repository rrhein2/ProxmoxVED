#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/ | Github: https://github.com/actualbudget/actual

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Node.js"
NODE_VERSION="22" setup_nodejs
msg_ok "Node.js installed"

# create_self_signed_cert

msg_info "Installing FoundryVTT"
base_install_dir="/opt/foundryvtt"
release_version_regex='^.*releases\/(\d+.\d+).*$'

cd /opt
# mkdir -p /opt/actualbudget-data/{server-files,upload,migrate,user-files,migrations,config}
# chown -R root:root /opt/actualbudget-data
# chmod -R 755 /opt/actualbudget-data

# cat <<EOF >/opt/actualbudget-data/config.json
# {
#   "port": 5006,
#   "hostname": "::",
#   "serverFiles": "/opt/actualbudget-data/server-files",
#   "userFiles": "/opt/actualbudget-data/user-files",
#   "trustedProxies": [
#     "10.0.0.0/8",
#     "172.16.0.0/12",
#     "192.168.0.0/16",
#     "127.0.0.0/8",
#     "::1/128",
#     "fc00::/7"
#   ],
#   "https": {
#     "key": "/etc/ssl/actualbudget/actualbudget.key",
#     "cert": "/etc/ssl/actualbudget/actualbudget.crt"
#   }
# }
# EOF
mkdir -p "/opt/foundryvtt/foundryvtt"
mkdir -p "/opt/foundryvtt/foundrydata"
cd "/opt/foundryvtt/foundryvtt"
# $STD npm install --location=global @actual-app/sync-server
wget -q "$DOWNLOAD_URL"
unzip FoundryVTT*.zip*
# [[ $DOWNLOAD_URL =~ $release_version_regex ]]
# RELEASE=${BASH_REMATCH[1]}
# echo "${RELEASE}" >~/.foundryvtt
msg_ok "Installed FoundryVTT"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/foundryvtt.service
[Unit]
Description=FoundryVTT

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/foundryvtt
ExecStart=/usr/bin/node /opt/foundryvtt/foundryvtt/main.js --dataPath=/opt/foundryvtt/foundrydata
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now foundryvtt
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc