#!/usr/bin/env bash
# This file:
#
#  - Runs FLARE container from the host.
#
# Usage:
#
#  LOG_LEVEL=7 ./flare-host.sh -d
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
  'flare-host' script for '${CONTAINER_NAME}' container
EOF

# shellcheck source=commons.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons.sh"


### Signal trapping and backtracing
##############################################################################

function __b3bp_cleanup_before_exit () {
  info "Done Cleaning Up Host"
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

CONTAINER_NAME=$(basename ${__dir})
CONTAINER_VERSION=$(yq r ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} container.version)
GIT_REMOTE_SSHKEYPRIVATE=$(yq r ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} git.remote.ssh-key-private)

[[ -e ${GIT_REMOTE_SSHKEYPRIVATE} ]] && cp -u ${GIT_REMOTE_SSHKEYPRIVATE} ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}

# Run Container Script in Manual or OpenWhisk Mode
([[ "${arg_o:?}" = "1" ]] && cp -r ${DIRECTORY_HOST_SHARED} ${DIRECTORY_CONTAINER} && ${DIRECTORY_CONTAINER}/${CONTAINER_SCRIPT} -d ${CONTAINER_NAME}) \
  || docker run --rm -v ${DIRECTORY_HOST_SHARED}:${DIRECTORY_CONTAINER_SHARED} ${DOCKERHUB_ID}/${CONTAINER_NAME}:${CONTAINER_VERSION} ${DIRECTORY_CONTAINER}/${CONTAINER_SCRIPT} ${CONTAINER_NAME}
