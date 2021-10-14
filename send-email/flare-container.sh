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

# shellcheck source=main.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commons.sh"


### Signal trapping and backtracing
##############################################################################

function __b3bp_cleanup_before_exit () {
  rm -rf /home/user/.ssh
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

#Set Variables
CONTAINER_NAME=${1}
DATE=$(date +%Y-%m-%d)
USERNAME=$(yq e '.gmail.username' ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} )
PASSWORD=$(yq e '.gmail.password-hash' ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} )
SENDER=$(yq e '.gmail.from' ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} )
SUBJECT=$(yq e '.email.subject' ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} )
CONTENT=$(yq e '.email.body' ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} )
RECEIVER=$(yq e '.email.recepients' ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} )
ATTACHMENT_GITHUB=$(yq e '.email.attachments_github[]' ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} )
ATTACHMENT_LOCAL=$(yq e '.email.attachments_local[]' ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} )
ATTACHMENTS_LIST=${ATTACHMENTS_LIST:-""}

# Add the date into file path
if [ ! -z "$ATTACHMENT_GITHUB" ]; then
  for line in $ATTACHMENT_GITHUB
  do	  
    echo "$line$DATE.pdf" >> tmp_date.txt
  done
fi

#Create a folder and download all files
mkdir $DATE
wget -i tmp_date.txt -P $DATE

#Copy the files from local directory
if [ ! -z "$ATTACHMENT_LOCAL" ]; then
  for line in $ATTACHMENT_LOCAL
  do
    cp $line ./$DATE
  done
fi

#Set the command related to attachments
ls ./$DATE > attachments_list.txt
while read line; do
  echo "-a ./$DATE/$line" >> attach_command.txt
done < attachments_list.txt

while read line; do
  ATTACHMENTS_LIST="$ATTACHMENTS_LIST $line"
done < attach_command.txt

# Send the email
echo "$CONTENT" | s-nail -:/ -v -s "$SUBJECT"\
$ATTACHMENTS_LIST \
-S smtp-use-starttls \
-S ssl-verify=ignore \
-S smtp-auth=login \
-S mta=smtp://smtp.gmail.com:587 \
-S from="$USERNAME($SENDER)" \
-S smtp-auth-user=$USERNAME \
-S smtp-auth-password=$PASSWORD \
-S ssl-verify=ignore \
$RECEIVER

#Remove useless files
rm -r $DATE attach*.txt tmp*.txt