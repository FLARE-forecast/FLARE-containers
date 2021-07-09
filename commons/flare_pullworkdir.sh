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
PROGNAME=$(basename $0)

error_exit()
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}

DIRECTORY_HOST="$HOME/flare-host"
DIRECTORY_HOST_SHARED="$HOME/flare-host/shared"
DIRECTORY_CONTAINER_SHARED="/home/user/flare/shared"
CONFIG_FILE="flare-config.yml"

s3_endpoint=$1
s3_access_key=$2
s3_secret_key=$3
CONTAINER=$4
LAKE=$5

# mkdir -p ~/.ssh/
# cp /home/user/id_rsa ~/.ssh/id_rsa
# chmod 400 ~/.ssh/id_rsa

mc alias set flare $s3_endpoint $s3_access_key $s3_secret_key

# copy config file
cp /home/user/openwhisk/${CONFIG_FILE} ${DIRECTORY_HOST_SHARED}/${CONTAINER}/

Ndays_steps=$(yq r ${DIRECTORY_HOST_SHARED}/${CONTAINER}/${CONFIG_FILE} openwhisk.days-look-back)
set_of_dependencies=$(yq r ${DIRECTORY_HOST_SHARED}/${CONTAINER}/${CONFIG_FILE} openwhisk.container-dependencies)
current_date=$(date +%Y%m%d)

# copy state.json for compound trigger
if [[ "$CONTAINER" == "compound-trigger" ]];
then
	mc cp flare/${LAKE}/${CONTAINER}/state.json ${DIRECTORY_HOST_SHARED}/${CONTAINER}/
	mc cp flare/${LAKE}/${CONTAINER}/${CONFIG_FILE} ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER}/
fi

# copy work dir
for FLARE_CONTAINER_NAME in ${set_of_dependencies};
do
	downloaded=false
	for daysback in `seq 0 $Ndays_steps`
	do
    	scandate=$(date -d "$current_date - $daysback days" +%Y%m%d)
		if (downloaded==false)
		then
			mc cp flare/${LAKE}/$FLARE_CONTAINER_NAME/${LAKE}_${scandate}_${FLARE_CONTAINER_NAME}_workingdirectory.tar.gz ${DIRECTORY_HOST_SHARED}/
			if [ "$?" -eq "0" ]; # copy work dir success
			then
				echo "OK"
				downloaded=true
				cd ${DIRECTORY_HOST_SHARED}/
				tar -xzf ${LAKE}_${scandate}_${FLARE_CONTAINER_NAME}_workingdirectory.tar.gz
				break
			else
				echo "NotOK"
			fi
		fi
    done
	downloaded==true || error_exit "$LINENO: An error has occurred in copy $FLARE_CONTAINER_NAME working directory."
done
# in case that the old config file rewrites the new one
cp /home/user/openwhisk/${CONFIG_FILE} ${DIRECTORY_HOST_SHARED}/${CONTAINER}/
