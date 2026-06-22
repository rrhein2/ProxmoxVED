#!/usr/bin/env bash
# source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
source <(curl -fsSL https://raw.githubusercontent.com/rrhein2/ProxmoxVED/refs/heads/feature/foundryvtt/misc/build.func)
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
  if [[ -z "${DOWNLOAD_URL:-}" ]]
  then
    export DOWNLOAD_URL=$(whiptail --title "FoundryVTT" \
    --inputbox "Timed URL from your profile's 'Purchased Licenses' page" 8 60 3>&1 1>&2 2>&3)
  fi
}

update_get_current_versions() {
  if [ -f ".release" ]
  then
    installed_major=$(cat .release | awk -F '.' '{print $1}')
    installed_minor=$(cat .release | awk -F '.' '{print $2}')
  else
    installed_major=0
    installed_minor=0
  fi
}

update_get_latest_release_versions() {
  $STD wget -q --output-document=foundry_versions.js https://foundryvtt.com/releases/
  published_majors=$(awk -v pattern='<h2 class="border">Version [0-9]+<\/h2>' '$0~pattern {print $3}' foundry_versions.js | sed 's/<\/h2>//g')
  published_minors=$(awk -v pattern="Release ${installed_major}.[0-9]{1,3}" '$0~pattern {print $NF}' foundry_versions.js | sed 's/<\/a>//g' | awk -F '.' '{print $2}')
  # Convert from text output to a list
  SAVE_IFS=$IFS
  IFS=$'\n'
  published_majors=($published_majors)
  published_minors=($published_minors)
  IFS=$SAVE_IFS
  $STD rm foundry_versions.js
}

update_offer_minor_update() {
  if [ "${PHS_SILENT:-0}" -eq 1 ]
  then
    perform_minor_update=0
  else
    whiptail --title "FoundryVTT" \
    --yesno "Minor version upgrades can be handled from the web UI automatically. Would you like to proceed here?" 8 60 3>&1 1>&2 2>&3
    perform_minor_update=$?
  fi
}

update_download_new_release() {
  custom_app_settings
  if wget -q --output-document=foundryvtt.zip "$DOWNLOAD_URL"
  then
    return 0
  else
    msg_error "${APP} download for update failed - aborting"
    if [ -f foundryvtt.zip ] ; then rm foundryvtt.zip; fi
    return 1
  fi
}

update_perform_backup() {
  $STD mv foundryvtt foundryvtt.bak
  $STD mkdir foundryvtt
  $STD mv foundryvtt.zip foundryvtt
}

update_install_new_release() {
  cd foundryvtt

  # Stop service or abort
  systemctl stop foundryvtt
  if systemctl is-active --quiet foundryvtt
  then
    msg_error "Failed to stop ${APP} - aborting update"
    return 1
  fi

  # Unpack download
  $STD unzip foundryvtt.zip
  $STD rm foundryvtt.zip

  # Modify NODE.js version if necessary
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

    # Update Release file
    RELEASE="$major_version.$minor_version"
    echo "${RELEASE}" >/opt/foundryvtt/.release
  fi

  # Test new install
  systemctl start foundryvtt
  if systemctl is-active --quiet foundryvtt
  then
    msg_info "Successfully updated ${APP}"
    # remove backup after successful install
    rm -rf /opt/foundryvtt/foundryvtt.bak
  else
    msg_error "Failed to restart ${APP} with new version - reverting"
    $STD cd /opt/foundryvtt
    $STD rm -rf foundryvtt
    $STD mv foundryvtt.bak foundryvtt
    systemctl start foundryvtt
    return 1
  fi
}

update_cleanup() {
  cd /opt/foundryvtt
  if [ -f foundryvtt/foundryvtt.zip ]; then rm foundryvtt/foundryvtt.zip; fi
  if [ -f foundry_versions.js ]; then rm foundry_versions.js; fi
  if [ -d foundryvtt.bak ]; then rm -rf foundryvtt.bak; fi
  
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  SAVE_PWD=$(pwd)
  cd /opt/foundryvtt

  # Update-specific variables
  installed_major=""
  installed_minor=""
  published_majors=""
  published_minors=""
  release_version_regex="^.*releases\/([0-9]+)\.([0-9]+).*$"

  if ! update_get_current_versions; then exit 1; fi
  if ! update_get_latest_release_versions; then exit; fi

  if [ "$installed_major" -lt "${published_majors[0]}" ]
  then
    # Update major version
    if ! update_download_new_release; then exit; fi
    if ! update_perform_backup; then exit; fi
    if ! update_install_new_release; then exit; fi
    if ! update_cleanup; then exit; fi
  elif [ "$installed_major" -eq "${published_majors[0]}" ]
  then
    if [ "$installed_minor" -eq "${published_minors[0]}" ]
    then
      msg_info "${APP} is up-to-date. Nothing to do."
    elif [ "$installed_minor" -lt "${published_minors[0]}" ]
    then
      # Update Minor Version
      update_offer_minor_update
      if [ "$perform_minor_update" -eq 0 ]
      then
        if ! update_download_new_release; then exit; fi
        if ! update_perform_backup; then exit; fi
        if ! update_install_new_release; then exit; fi
        if ! update_cleanup; then exit; fi
      fi
    else
      msg_error "Installed minor version of ${APP} is greater than any published version"
      $STD rm foundry_versions.js
      exit
    fi
  else
    msg_error "Installed major version of ${APP} greater than any published version"
    $STD rm foundry_versions.js
    exit
  fi
  update_cleanup
  cd "$SAVE_PWD"
}

start
if command -v pveversion >/dev/null 2>&1
then
  custom_app_settings
fi
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:30000${CL}"