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
CONFIG_FILE="flare-config.yml"
DIRECTORY_CONTAINER_SHARED="/home/user/flare/shared"
APIHOST=$1
AUTH=$2
CONTAINER_NAME=$3
LAKE=$4
NEXR_TRIGGER_INIT=$5

# Generate next trigger payload based on given payload
echo $NEXR_TRIGGER_INIT > /home/user/next_payload.json
NEXR_TRIGGER=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} openwhisk.next-trigger.name)
NEXR_TRIGGER_CONTAINER=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} openwhisk.next-trigger.container_name)
if [[ -n "$NEXR_TRIGGER_CONTAINER" ]];
then
    payload="$(jq --arg key container_name --arg pass "$NEXR_TRIGGER_CONTAINER" '.[$key] = $pass' /home/user/next_payload.json )" && echo "${payload}" > /home/user/next_payload.json
    if [[ "$NEXR_TRIGGER_CONTAINER" == "compound-trigger" ]];
    then
        NEXR_TRIGGER_TYPE=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} openwhisk.next-trigger.type)
        payload="$(jq --arg key type --arg pass "$NEXR_TRIGGER_TYPE" '.[$key] = $pass' /home/user/next_payload.json )" && echo "${payload}" > /home/user/next_payload.json
    fi
fi

# Remove type field in the next trigger if the current one the compound-trigger
if [[ "$CONTAINER_NAME" == "compound-trigger" ]];
then
    payload="$(jq 'del(.type)' /home/user/next_payload.json)" && echo "${payload}" > /home/user/next_payload.json
fi

# Start next trigger
echo "$payload"
if [[ "$CONTAINER_NAME" == "flare-download-noaa" ]];
then
    NUMBER_OF_DAYS=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} number-of-days)
    NOAA_MODEL=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} noaa_model)
    LAKE_NAME_CODE=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} lake_name_code)

    # Check data has been download sucessfully and trigger flare-process-noaa
    ## To do: check if it needs to run pyscipts again
    TODAY_DATE=$(date +%Y%m%d)
    NOT_DELETE_DATE3=$(date --date="-3 day" +%Y%m%d)
    NOT_DELETE_DATE2=$(date --date="-2 day" +%Y%m%d)
    NOT_DELETE_DATE1=$(date --date="-1 day" +%Y%m%d)

    TRIGGER=true
    FOLDER=${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${NOAA_MODEL}/${LAKE_NAME_CODE}/${TODAY_DATE}
    YESTERDAY_FOLDER=${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${NOAA_MODEL}/${LAKE_NAME_CODE}/${NOT_DELETE_DATE1}
    for time in 00 06 12 18
    do
        if [[ $time = "18" ]];then
            CHECK_FOLDER=${YESTERDAY_FOLDER}
            echo "Start to check time:${time} files in ${NOT_DELETE_DATE1} folder"
        else
            CHECK_FOLDER=${FOLDER}
            echo "Start to check time:${time} files in ${TODAY_DATE} folder"
        fi

        for name in tmp2m pressfc rh2m dlwrfsfc dswrfsfc apcpsfc ugrd10m vgrd10m
        do
            COMPLETED_CHECK=false
            FILE=${CHECK_FOLDER}/gefs_pgrb2ap5_all_${time}z.ascii?${name}[0:30][0:64][255][160]
            # Check if file is exist.
            if [[ ! -f "${FILE}" ]];
            then
                echo "$FILE does not exist."
                TRIGGER=false
                break
            fi
            # Check if file is completed.
            while IFS= read -r line
            do
                if [[ $line = "lon, [1]" ]];then
                    COMPLETED_CHECK=true
                fi
            done < "$FILE"
            if [[ "${COMPLETED_CHECK}" = false ]];
            then
                echo "${FILE} is not completed."
                break
            fi
        done
    done

    # Check if it has triggered, if not trigger flare-process-noaa
    TRIGGER_FILE=${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${NOAA_MODEL}/${LAKE_NAME_CODE}/${TODAY_DATE}.trg
    if [[ ${TRIGGER} = true ]];
    then
        if [[ ! -f "$TRIGGER_FILE" ]];
        then
            echo "Trigger flare-process-noaa"
            #Trigger flare-process-noaa
            echo "Triggered" 2>&1 | tee -a ${FOLDER}/${TODAY_DATE}.trg
            curl -u ${AUTH} https://${APIHOST}/api/v1/namespaces/_/triggers/$NEXR_TRIGGER -X POST -H "Content-Type: application/json" -d "$payload"
        fi
    fi

else
   curl -u $AUTH https://$APIHOST/api/v1/namespaces/_/triggers/$NEXR_TRIGGER \
    -X POST -H "Content-Type: application/json" \
    -d "$payload"
fi
