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

### BASH3 Boilerplate (b3bp) Header
##############################################################################

read -r -d '' __usage <<-'EOF' || true
  -v               Enable verbose mode, print script as it is executed
  -d --debug       Enables debug mode
  -h --help        This page
  -n --no-color    Disable color output
  -1 --one         Do just one thing
  -i --input [arg] File to process. Can be repeated.
  -x               Specify a flag. Can be repeated.
EOF

read -r -d '' __helptext <<-'EOF' || true
 This is Bash3 Boilerplate's help text. Feel free to add any description of your
 program or elaborate more on command-line arguments. This section is not
 parsed and will be added as-is to the help.
EOF

# shellcheck source=source.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/source.sh"
type info >/dev/null 2>&1 || info() { echo "[INFO] $*"; }
type warn >/dev/null 2>&1 || warn() { echo "[WARN] $*" >&2; }
type emergency >/dev/null 2>&1 || emergency() { echo "[EMERGENCY] $*" >&2; exit 1; }

### Signal trapping and backtracing
##############################################################################

function __b3bp_cleanup_before_exit () {
  rm -rf "${DATE}" attachments_list.txt attach_command.txt
  info "Cleaning Up Completed"
}
trap __b3bp_cleanup_before_exit EXIT

__b3bp_err_report() {
    local error_code=$?
    error "Error in ${__file} in function ${1} on line ${2}"
    exit ${error_code}
}
# trap '__b3bp_err_report "${FUNCNAME:-.}" ${LINENO}' ERR

### Command-line argument switches
##############################################################################

if [[ "${arg_d:?}" = "1" ]]; then
  set -o xtrace
  PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
  LOG_LEVEL="7"
  trap '__b3bp_err_report "${FUNCNAME:-.}" ${LINENO}' ERR
fi

if [[ "${arg_v:?}" = "1" ]]; then
  set -o verbose
fi

if [[ "${arg_n:?}" = "1" ]]; then
  NO_COLOR="true"
fi

if [[ "${arg_h:?}" = "1" ]]; then
  help "Help using ${0}"
fi

### Validation
##############################################################################

[[ "${LOG_LEVEL:-}" ]] || emergency "Cannot continue without LOG_LEVEL."

### Run-time and User-defined
##############################################################################

CONFIG_FILE="email_config.yaml"
DATE=$(date +%Y-%m-%d)
USERNAME=$(yq e '.gmail.username' ${CONFIG_FILE})
PASSWORD=$(yq e '.gmail.password' ${CONFIG_FILE})
SENDER=$(yq e '.email.sender' ${CONFIG_FILE})
SUBJECT=$(yq e '.email.subject' ${CONFIG_FILE})
CONTENT=$(yq e '.email.body' ${CONFIG_FILE})
RECIPIENTS=$(yq e '.email.recipients[]' ${CONFIG_FILE})
readarray -t ATTACHMENTS_WEB < <(yq e -o=j -I=0 '.email.attachments_web[]' ${CONFIG_FILE})
readarray -t ATTACHMENTS_LOCAL < <(yq e -o=j -I=0 '.email.attachments_local[]' ${CONFIG_FILE})
EXPECTED_COUNT=$(( ${#ATTACHMENTS_WEB[@]} + ${#ATTACHMENTS_LOCAL[@]} ))

# Find if URL is accessible
function validate_url() {
  wget -S --spider --no-check-certificate "$1" 2>&1 | grep -q 'HTTP/1.1 200 OK'
}

# Retry block for downloading and verifying attachments
##############################################################################

MAX_RETRIES=3
attempt=1

while (( attempt <= MAX_RETRIES )); do
  info "========== Attempt $attempt to collect attachments =========="
  FAILED_FILES=()

  rm -rf "${DATE}"
  mkdir "${DATE}"

  # Download from web
  for attachment_web in "${ATTACHMENTS_WEB[@]}"; do
    __prefix_web=$(echo "${attachment_web}" | yq e '.prefix // ""' -)
    __infix_web=$(echo "${attachment_web}" | yq e '.infix // ""' -)
    [[ -n ${__infix_web} ]] && __infix_output_web=$(eval "${__infix_web}")
    __suffix_web=$(echo "${attachment_web}" | yq e '.suffix // ""' -)
    __url="${__prefix_web}${__infix_output_web:-}${__suffix_web}"

    if validate_url "${__url}"; then
      if wget --no-check-certificate -q "${__url}" -P "${DATE}"; then
        info "Downloaded: ${__url}"
      else
        warn "Failed to download: ${__url} – wget error"
        FAILED_FILES+=("web: ${__url} (wget failed)")
      fi
    else
      warn "Invalid URL: ${__url}"
      FAILED_FILES+=("web: ${__url} (invalid URL)")
    fi
  done

  # Copy from local
  for attachment_local in "${ATTACHMENTS_LOCAL[@]}"; do
    __prefix_local=$(echo "${attachment_local}" | yq e '.prefix // ""' -)
    __infix_local=$(echo "${attachment_local}" | yq e '.infix // ""' -)
    [[ -n ${__infix_local} ]] && __infix_output_local=$(eval "${__infix_local}")
    __suffix_local=$(echo "${attachment_local}" | yq e '.suffix // ""' -)
    __path="${__prefix_local}${__infix_output_local:-}${__suffix_local}"

    if [[ -e "${__path}" ]]; then
      cp "${__path}" "${DATE}"
      info "Copied local file: ${__path}"
    else
      warn "Missing local file: ${__path}"
      FAILED_FILES+=("local: ${__path} (not found)")
    fi
  done

  ACTUAL_COUNT=$(ls -1 "${DATE}" | wc -l)

  if [[ "${ACTUAL_COUNT}" -eq "${EXPECTED_COUNT}" ]]; then
    info "Attachment count matches expected (${ACTUAL_COUNT})"
    break
  else
    warn "Mismatch: expected ${EXPECTED_COUNT}, got ${ACTUAL_COUNT}"
    if (( ${#FAILED_FILES[@]} > 0 )); then
      warn "Files failed to be retrieved:"
      for f in "${FAILED_FILES[@]}"; do
        warn " - $f"
      done
    fi
    ((attempt++))
    sleep 2
  fi
done

if (( attempt > MAX_RETRIES )); then
  emergency "Attachment collection failed after ${MAX_RETRIES} attempts. Email not sent."
fi

# Build attachment command list
touch attach_command.txt
ls "${DATE}" > attachments_list.txt

while read -r __line; do
  echo "-a ${DATE}/${__line}" >> attach_command.txt
done < attachments_list.txt

while read -r __line; do
  ATTACHMENTS_LIST="${ATTACHMENTS_LIST:-} ${__line}"
done < attach_command.txt

# Send Email
##############################################################################

echo "${CONTENT}" | s-nail -:/ -v -s "${SUBJECT}" \
  ${ATTACHMENTS_LIST:-} \
  -S smtp-use-starttls \
  -S ssl-verify=ignore \
  -S smtp-auth=login \
  -S mta=smtp://smtp.gmail.com:587 \
  -S from="${USERNAME}(${SENDER})" \
  -S smtp-auth-user=${USERNAME} \
  -S smtp-auth-password=${PASSWORD} \
  -S ssl-verify=ignore \
  ${RECIPIENTS}

info "Email sent successfully."
