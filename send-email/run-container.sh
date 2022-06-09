#!/usr/bin/env bash
# This file:
#
#  - Demos BASH3 Boilerplate (change this for your script)
#
# Usage:
#
#  LOG_LEVEL=7 ./example.sh -f /tmp/x -d (change this for your script)
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
  -1 --one         Do just one thing
  -i --input [arg] File to process. Can be repeated.
  -x               Specify a flag. Can be repeated.
EOF

# shellcheck disable=SC2034
read -r -d '' __helptext <<-'EOF' || true # exits non-zero when EOF encountered
 This is Bash3 Boilerplate's help text. Feel free to add any description of your
 program or elaborate more on command-line arguments. This section is not
 parsed and will be added as-is to the help.
EOF

# shellcheck source=source.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/source.sh"


### Signal trapping and backtracing
##############################################################################

function __b3bp_cleanup_before_exit () {
  rm -rf ${DATE} date_temp.txt attachments_list.txt attach_command.txt
  info "Cleaning up. Done"
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


### Validation. Error out if the things required for your script are not present
##############################################################################

[[ "${LOG_LEVEL:-}" ]] || emergency "Cannot continue without LOG_LEVEL. "


### Run-time and User-defined
##############################################################################

# Set Variables
DATE=$(date +%Y-%m-%d)
USERNAME=$(yq e '.gmail.username' ${CONFIG_FILE})
PASSWORD=$(yq e '.gmail.password-hash' ${CONFIG_FILE})
SENDER=$(yq e '.gmail.from' ${CONFIG_FILE})
SUBJECT=$(yq e '.email.subject' ${CONFIG_FILE})
CONTENT=$(yq e '.email.body' ${CONFIG_FILE})
RECIPIENTS=$(yq e '.email.recipients' ${CONFIG_FILE})
ATTACHMENTS_GRAPH=$(yq e '.email.attachments_graph' ${CONFIG_FILE})
ATTACHMENTS_GRAPH_PREFIX=$(yq e '.email.attachments_graph.prefix' ${CONFIG_FILE})
ATTACHMENTS_GRAPH_POSTFIX=$(yq e '.email.attachments_graph.postfix' ${CONFIG_FILE})
ATTACHMENTS_GITHUB=$(yq e '.email.attachments_github[]' ${CONFIG_FILE})
ATTACHMENTS_LOCAL=$(yq e '.email.attachments_local[]' ${CONFIG_FILE})
ATTACHMENTS_LIST=${ATTACHMENTS_LIST:-""}

__past=1
__graph_url="${ATTACHMENTS_GRAPH_PREFIX}"$(date -d $__past" day ago" '+%Y-%m-%d')"${ATTACHMENTS_GRAPH_POSTFIX}"

# Find if URL is accessible
function validate_url() {
  if [[ `wget -S --spider ${1} 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
    echo "Valid URL"
  else
    echo "Invalid URL"
  fi
  return
}

# Add Attachments
mkdir ${DATE}

if [ ! -z "${ATTACHMENTS_GRAPH}" ]; then
  if [[ $(validate_url ${__graph_url}) = "Valid URL" ]]; then
    wget --no-check-certificate ${__graph_url} -P ${DATE}
  fi
fi

if [ ! -z "${ATTACHMENTS_GITHUB}" ]; then
  for __line in ${ATTACHMENTS_GITHUB}; do
    if [[ $(validate_url "${__line}${DATE}.pdf") = "Valid URL" ]]; then
      echo "${__line}${DATE}.pdf" >> date_temp.txt
    fi
  done
  wget --no-check-certificate -i date_temp.txt -P ${DATE}
fi

if [ ! -z "${ATTACHMENTS_LOCAL}" ]; then
  for __line in ${ATTACHMENTS_LOCAL}; do
    cp ${__line} ./${DATE}
  done
fi

touch attach_command.txt
ls ./${DATE} > attachments_list.txt

while read __line; do
  echo "-a ./${DATE}/${__line}" >> attach_command.txt
done < attachments_list.txt

while read __line; do
  ATTACHMENTS_LIST="${ATTACHMENTS_LIST} ${__line}"
done < attach_command.txt

# Send Email
echo "${CONTENT}" | s-nail -:/ -v -s "${SUBJECT}" \
${ATTACHMENTS_LIST} \
-S smtp-use-starttls \
-S ssl-verify=ignore \
-S smtp-auth=login \
-S mta=smtp://smtp.gmail.com:587 \
-S from="${USERNAME}(${SENDER})" \
-S smtp-auth-user=${USERNAME} \
-S smtp-auth-password=${PASSWORD} \
-S ssl-verify=ignore \
${RECIPIENTS}
