#!/usr/bin/env bash
# source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVED/feature/foundryvtt/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://foundryvtt.com/article/installation/

APP="FoundryVTT"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-32}" # 32 selected as assets for maps can build up quickly
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

custom_app_settings() {
    export DOWNLOAD_URL=$(whiptail --title "Timed URL" \
    --inputbox "Timed URL from your profile's 'Purchased Licenses' page" 8 60 3>&1 1>&2 2>&3)
}
custom_app_settings

function update_script() {
#   header_info
#   check_container_storage
#   check_container_resources

#   if [[ ! -f /opt/foundryvtt ]]; then
#     msg_error "No ${APP} Installation Found!"
#     exit
#   fi

#   NODE_VERSION="22" setup_nodejs
#   [[ $DOWNLOAD_URL =~ release_version_regex ]]
#   RELEASE=${BASH_REMATCH[1]}
#   if [[ -f /opt/actualbudget-data/config.json ]]; then
#     if check_for_gh_release "actualbudget" "actualbudget/actual"; then
#       msg_info "Stopping Service"
#       systemctl stop actualbudget
#       msg_ok "Stopped Service"

#       msg_info "Updating Actual Budget to ${RELEASE}"
#       $STD npm update -g @actual-app/sync-server
#       echo "${RELEASE}" >~/.actualbudget
#       msg_ok "Updated Actual Budget to ${RELEASE}"

#       msg_info "Starting Service"
#       systemctl start actualbudget
#       msg_ok "Started Service"
#       msg_ok "Updated successfully!"
#     fi
#   else
#     msg_warn "Old Installation Found, you need to migrate your data and recreate to a new container"
#     msg_warn "Please follow the instructions on the Actual Budget website to migrate your data"
#     msg_warn "https://actualbudget.org/docs/backup-restore/backup"
#     exit
#   fi
#   exit
  msg_warn "FoundryVTT should be updated from the server's Web UI and not from the container script."
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}https://${IP}:5006${CL}"