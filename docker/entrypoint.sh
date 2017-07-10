#!/usr/bin/env sh
set -e -x

DEV_UID="${DEV_UID:-''}"
DEV_GID="${DEV_GID:-''}"

DATA_DIR="${DATA_DIR:-'/conan_data'}"
DEFAULT_RUN_USER="${DEFAULT_RUN_USER:-conan}"
DEFAULT_RUN_COMMAND="${DEFAULT_RUN_COMMAND:-/usr/local/bin/conan_server}"

rewriteUID(){
  local HOST_UID="${1}"
  local HOST_GID="${2}"
  local DOCKER_RUN_USER="${DEFAULT_RUN_USER}"

# Checks if uid rewrite is required
  if [ ! "${HOST_UID}" = "" ] || [ ! "${HOST_GID}" = "" ] ; then
    return
  fi

# Loads UID/GID/HOME from /etc/passwd
  ORIGPASSWD=$(cat /etc/passwd | grep ${DOCKER_RUN_USER})
  ORIG_UID=$(echo ${ORIGPASSWD} | cut -f3 -d:)
  ORIG_GID=$(echo ${ORIGPASSWD} | cut -f4 -d:)
  ORIG_HOME=$(echo ${ORIGPASSWD} | cut -f6 -d:)

# Changes UID and GID of docker user
  sed -i -e "s/:$ORIG_UID:$ORIG_GID:/:$HOST_UID:$HOST_GID:/" /etc/passwd
  sed -i -e "s/$DOCKER_RUN_USER:x:$ORIG_GID:/$DOCKER_RUN_USER:x:$HOST_GID:/" /etc/group
  chown -R ${HOST_UID}:${HOST_GID} ${ORIG_HOME}
}

initSettings(){
  readonly CONF_FILE="$(eval echo "~${DEFAULT_RUN_USER}")/.conan_server/server.conf"
  readonly CONF_PATH=$(dirname "${CONF_FILE}")
  if [ ! -d "${CONF_PATH}" ] ; then
    mkdir -p "${CONF_PATH}"
  fi
  cat '/conan_conf/server.dist.conf' |  envsubst > "${CONF_FILE}"
  chown -R "${DEFAULT_RUN_USER}." "${CONF_PATH}"
}

if [ "$1" = "${DEFAULT_RUN_COMMAND}" -a "$(id -u)" = '0' ]; then
  initSettings
  rewriteUID "${DEV_UID}" "${DEV_GID}"
  mkdir -p "${DATA_DIR}"

  chown -R "${DEFAULT_RUN_USER}." "${DATA_DIR}"
  exec gosu "${DEFAULT_RUN_USER}" sh -c "$@"
fi

exec "$@"
