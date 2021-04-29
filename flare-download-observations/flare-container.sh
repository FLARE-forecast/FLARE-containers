#!/usr/bin/env bash
# This file:
#
#  - Runs the service inside FLARE container.
#
# Usage:
#
#  LOG_LEVEL=7 ./flare-container.sh -d
#
# Based on a template by BASH3 Boilerplate v2.3.0
# http://bash3boilerplate.sh/#authors
#
# The MIT License (MIT)
# Copyright (c) 2013 Kevin van Zonneveld and contributors
# You are not obligated to bundle the LICENSE file with your b3bp projects as long
# as you leave these references intact in the header comments of your source files.


### BASH3 Boilerplate (b3bp) Header
##############################################################################

# Commandline options. This defines the usage page, and is used to parse cli
# opts & defaults from. The parsing is unforgiving so be precise in your syntax
# - A short option must be preset for every long option; but every short option
#   need not have a long option
# - `--` is respected as the separator between options and arguments
# - We do not bash-expand defaults, so setting '~/app' as a default will not resolve to ${HOME}.
#   you can use bash variables to work around this (so use ${HOME} instead)

# shellcheck disable=SC2034
read -r -d '' __usage <<-'EOF' || true # exits non-zero when EOF encountered
  -v               Enable verbose mode, print script as it is executed
  -d --debug       Enables debug mode
  -h --help        This page
  -n --no-color    Disable color output
  -o --openwhisk   Enables OpenWhisk mode
EOF

# shellcheck disable=SC2034
read -r -d '' __helptext <<-'EOF' || true # exits non-zero when EOF encountered
  'flare-container' script for '${CONTAINER_NAME}' container
EOF

# shellcheck source=commons.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons.sh"


### Signal trapping and backtracing
##############################################################################

function __b3bp_cleanup_before_exit () {
  rm -rf /root/.ssh
  info "Done Cleaning Up Container"
}
trap __b3bp_cleanup_before_exit EXIT

# requires `set -o errtrace`
__b3bp_err_report() {
  local error_code=${?}
  # shellcheck disable=SC2154
  error "Error in ${__file} in function ${1} on line ${2}"
  exit ${error_code}
}
# Uncomment the following line for always providing an error backtrace
# trap '__b3bp_err_report "${FUNCNAME:-.}" ${LINENO}' ERR


### Command-line argument switches (like -d for debugmode, -h for showing helppage)
##############################################################################

# debug mode
if [[ "${arg_d:?}" = "1" ]]; then
  set -o xtrace
  PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
  LOG_LEVEL="7"
  # Enable error backtracing
  trap '__b3bp_err_report "${FUNCNAME:-.}" ${LINENO}' ERR
fi

# verbose mode
if [[ "${arg_v:?}" = "1" ]]; then
  set -o verbose
fi

# no color mode
if [[ "${arg_n:?}" = "1" ]]; then
  NO_COLOR="true"
fi

# help mode
if [[ "${arg_h:?}" = "1" ]]; then
  # Help exists with code 1
  help "Help using ${0}"
fi

# OpenWhisk mode
if [[ "${arg_o:?}" = "1" ]]; then
  echo "Running in OpenWhisk Mode..."
fi


### User-defined and Runtime
##############################################################################

# Pulls from Git Repo
# TODO: Make it more readable.
# TODO: Cover corner cases such as wrong directory with the same name already exists.
# Usage: git_pull location config_file
function git_pull() {
  ([ -d $(yq r ${2} ${1}.git.remote.branch) ] && cd $(yq r ${2} ${1}.git.remote.branch) && git pull && cd ..) || git clone --branch $(yq r ${2} ${1}.git.remote.branch) --depth 1 https://$(yq r ${2} ${1}.git.remote.server)/$(yq r ${2} ${1}.git.remote.repository) $(yq r ${2} ${1}.git.remote.branch)
}

function pull_workdir() {
  REMOTE_SERVER=$1
  REMOTE_PORT=$2
  LAKE=$3
  CONTAINER=$4
  USERNAME=$5

  ssh-keyscan -p ${REMOTE_PORT} -t rsa ${REMOTE_SERVER} >> ~/.ssh/known_hosts
  cd ${DIRECTORY_HOST}

  if [[ ! -e "${DIRECTORY_HOST}/${LAKE}" ]]; then
      git clone ssh://git@${REMOTE_SERVER}:${REMOTE_PORT}/${USERNAME}/${LAKE}.git
  fi
  cd ${LAKE}/
  git checkout ${CONTAINER}
  git pull

  if [ -f "config.tar.gz" ]; then
      tar -xzvf config.tar.gz
      # echo "{\"hello\":$(<flare-config.yml)}"
      if [ -f "flare-config.yml" ]; then
          cp flare-config.yml ${DIRECTORY_HOST_SHARED}/${CONTAINER}/flare-config.yml
      fi
  fi
}

function push_workdir() {
  REMOTE_SERVER=$1
  REMOTE_PORT=$2
  LAKE=$3
  CONTAINER=$4
  USERNAME=$5

  TIMESTAMP=$(date +"%d_%m_%y")
  ssh-keyscan -p ${REMOTE_PORT} -t rsa ${REMOTE_SERVER} >> ~/.ssh/known_hosts

  if [[ ! -e "${DIRECTORY_HOST}/${LAKE}" ]]; then
      error_exit "$LINENO: No ${LAKE} gitlab directory."
  fi
  cd ${DIRECTORY_HOST}/${LAKE}/
  git remote add gitlab ssh://git@${REMOTE_SERVER}:${REMOTE_PORT}/${USERNAME}/${LAKE}.git
  git fetch gitlab ${CONTAINER}
  git checkout ${CONTAINER}

  if [[ ! -e "${DIRECTORY_CONTAINER_SHARED}/test-data/${LAKE}" ]]; then
      error_exit "$LINENO: No test-data directory."
  fi
  tar -czvf workdir_${TIMESTAMP}.tar.gz ${DIRECTORY_CONTAINER_SHARED}/test-data/${LAKE}
  git add workdir_${TIMESTAMP}.tar.gz
  git clean -f
  git commit -m "$(date +"%D %T") - Add NOAA Forecast"
  git push gitlab ${CONTAINER}
}

CONTAINER_NAME=${1}
CONTAINER_VERSION=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.version)
echo "Welcome to ${CONTAINER_NAME} version ${CONTAINER_VERSION}!"

PRE_RUN_PULL_WORKDIR=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.working-directory.pre-run-pull)
POST_RUN_PUSH_WORKDIR=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.working-directory.post-run-push)

REMOTE_SERVER=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.working-directory.git.remote.server)
REMOTE_PORT=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.working-directory.git.remote.port)
LAKE=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.working-directory.git.remote.directory)
CONTAINER=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.working-directory.git.remote.repository)
USERNAME=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.working-directory.git.remote.user-name)

# pre pull work dir
if [[ "${arg_o:?}" = "1" ]] && [[ "${PRE_RUN_PULL_WORKDIR:?}" = "True" ]]; then
  pull_workdir ${REMOTE_SERVER} ${REMOTE_PORT} ${LAKE} ${CONTAINER} ${USERNAME}
fi


# Start flare-container work

cd ${DIRECTORY_CONTAINER}

CONTAINER_NAME=${1}
GIT_REMOTE_SERVER=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} git.remote.server)
GIT_REMOTE_USERNAME=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} git.remote.user-name)
GIT_REMOTE_USEREMAIL=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} git.remote.user-email)
GIT_REMOTE_SSHKEYPRIVATE=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} git.remote.ssh-key-private)

# Support Compatibility with Old Names
# TODO: Use New Names in the Scripts
ln -nsf ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/fcre-metstation-data ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/carina-data
ln -nsf ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/fcre-catwalk-data ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/mia-data
ln -nsf ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/fcre-weir-data ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/diana-data
ln -nsf ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/fcre-manual-data ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/manual-data

# Extract Private SSH Key File Name from Full Path
GIT_REMOTE_SSHKEYPRIVATE_FILE=$(awk -F/ '{print $NF}' <<< ${GIT_REMOTE_SSHKEYPRIVATE})

# Setup SSH
mkdir -p /root/.ssh
cp -u ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${GIT_REMOTE_SSHKEYPRIVATE_FILE} /root/.ssh/id_rsa
# TODO: Add All Remote Servers to known_hosts
ssh-keyscan ${GIT_REMOTE_SERVER} > /root/.ssh/known_hosts

# Setup Git
git config --global user.name ${GIT_REMOTE_USERNAME}
git config --global user.email ${GIT_REMOTE_USEREMAIL}

cd ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}
# Check If the Directory Is There and Is the Right Git Directory and Clone the Git Repository If Doesn't Exist
git_pull realtime_insitu_location ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE}
git_pull realtime_met_station_location ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE}
git_pull manual_data_location ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE}
git_pull realtime_inflow_data_location ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE}

MANUAL_DOWNLOAD_LOCATION=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} manual_data_location.git.remote.branch)/$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} manual_data_location.git.remote.directory)
cd ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${MANUAL_DOWNLOAD_LOCATION}
wget --no-verbose --show-progress --progress=bar:force:noscroll --no-clobber $(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} manual_data_location.manual-downloads[0].url) \
  --header='Connection: keep-alive' \
  --header='Cache-Control: max-age=0' \
  --header='Upgrade-Insecure-Requests: 1' \
  --header='User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36' \
  --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  --header='Sec-Fetch-Site: cross-site' \
  --header='Sec-Fetch-Mode: navigate' \
  --header='Sec-Fetch-Dest: document' \
  --header='Accept-Language: en-US,en;q=0.9,fa;q=0.8' \
  --output-document $(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} manual_data_location.manual-downloads[0].file-name) || true

NOAA_LOCATION=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} noaa_location)
# No Need to Pull NOAA Data If flare-download-noaa Container Has Already Been Run Successfully
#cd ${DIRECTORY_CONTAINER_SHARED}/${NOAA_LOCATION} && git pull && cd ..

# post push work dir
if [[ "${arg_o:?}" = "1" ]] && [[ "${POST_RUN_PUSH_WORKDIR:?}" = "True" ]]; then
  push_workdir ${REMOTE_SERVER} ${REMOTE_PORT} ${LAKE} ${CONTAINER} ${USERNAME}
fi
