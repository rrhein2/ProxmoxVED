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

# msg_info "Installing Node.js"
# NODE_VERSION="24" setup_nodejs
# msg_ok "Node.js installed"

# create_self_signed_cert

msg_info "Installing FoundryVTT"
base_install_dir="/opt/foundryvtt"
release_version_regex="^.*releases\/([0-9]+)\.([0-9]+).*$"

cd /opt

mkdir -p "/opt/foundryvtt/foundryvtt"
mkdir -p "/opt/foundryvtt/foundrydata"
cd "/opt/foundryvtt/foundryvtt"
$STD wget -q --output-document=foundryvtt.zip "$DOWNLOAD_URL"
if [ ! -f foundryvtt.zip ]
then
  msg_error "FoundryVTT could not be downloaded - aborting"
  exit
fi
$STD unzip foundryvtt.zip
$STD rm foundryvtt.zip
if [[ $DOWNLOAD_URL =~ $release_version_regex ]]
then
    major_version="${BASH_REMATCH[1]}"
    minor_version="${BASH_REMATCH[2]}"
    if [ "$major_version" -ge 14 ]
    then
        msg_info "Installing Node.js"
        NODE_VERSION="24" setup_nodejs
        msg_ok "Node.js installed"
    else
        msg_info "Installing Node.js"
        NODE_VERSION="22" setup_nodejs
        msg_ok "Node.js installed"
    fi
    RELEASE="${major_version}.${minor_version}"
    echo "${RELEASE}" > /opt/foundryvtt/.release
fi
msg_ok "Installed FoundryVTT version ${RELEASE}"

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