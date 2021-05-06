#!/usr/bin/env bash
# This file:
#
#  - Installs FLARE dependancies on the host.
#
# Usage:
#
#  Running on the host:               ./flare-install.sh
#  Running directly from the web:     wget -O - https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/master/${CONTAINER_NAME}/flare-install.sh | /usr/bin/env bash -s ${CONTAINER_NAME}

YQ_URL=https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64
YQ=$HOME/bin/yq

CONFIG="flare-config.yml"
HOST_SCRIPT="flare-host.sh"
COMMONS_SCRIPT="commons.sh"
DIRECTORY_HOST="$HOME/flare-host"
DIRECTORY_HOST_SHARED="$HOME/flare-host/shared"

CONTAINER_NAME=${1}
CONTAINER_VERSION=${2}
CONFIG_URL=https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/${CONTAINER_VERSION}/${CONTAINER_NAME}/${CONFIG}
HOST_SCRIPT_URL=https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/${CONTAINER_VERSION}/commons/${HOST_SCRIPT}
COMMONS_SCRIPT_URL=https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/${CONTAINER_VERSION}/commons/${COMMONS_SCRIPT}

# Setup Directories on the Host
mkdir -p ${DIRECTORY_HOST}/${CONTAINER_NAME} ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}
chmod -R 777 ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}
mkdir -p $(dirname ${YQ})
[[ ":$PATH:" != *":$HOME/bin:"* ]] && echo -e "\nexport PATH='$HOME/bin:$PATH'" >> $HOME/.bashrc && source $HOME/.bashrc

# Get Required Files
wget ${YQ_URL} -O ${YQ}
wget ${CONFIG_URL} -O ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}/${CONFIG}
wget ${HOST_SCRIPT_URL} -O ${DIRECTORY_HOST}/${CONTAINER_NAME}/${HOST_SCRIPT}
wget ${COMMONS_SCRIPT_URL} -O ${DIRECTORY_HOST}/${CONTAINER_NAME}/${COMMONS_SCRIPT}
chmod +x ${YQ} ${DIRECTORY_HOST}/${CONTAINER_NAME}/${HOST_SCRIPT}

# Set Default Value for ssh-key.private /home/$USER/.ssh/id_rsa (default for non-root), /home/user/.ssh/id_rsa (default for root)
# yq w -i ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}/${CONFIG} git.remote.ssh-key-private $(([ $EUID -eq 0 ] && echo "/home/user/.ssh/id_rsa") || echo "/home/$USER/.ssh/id_rsa")

# Set Default Value for git.remote.user.name and git.remote.user.email from the Host Git Config
# yq w -i ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}/${CONFIG} git.remote.user-name "$(git config --global user.name)"
# yq w -i ${DIRECTORY_HOST_SHARED}/${CONTAINER_NAME}/${CONFIG} git.remote.user-email "$(git config --global user.email)"
