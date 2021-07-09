#!/usr/bin/env bash

CURRENT_TIME=$(date +%s)
CONFIG_FILE=config.yml
GIT_REPOSITORY=$(yq r ${CONFIG_FILE} git.repository)
GIT_BRANCH=$(yq r ${CONFIG_FILE} git.branch)
GIT_UPDATE_PERIOD=$(yq r ${CONFIG_FILE} git.update-period)
UPDATE_GRACE_TIME=$(yq r ${CONFIG_FILE} git.update-grace-time)
HEALTHCHECKSIO_URL=$(yq r ${CONFIG_FILE} healthchecksio-url)
LAST_COMMIT=$(curl https://api.github.com/repos/${GIT_REPOSITORY}/commits/${GIT_BRANCH} 2>&1 | grep '"date"' | tail -n 1 | sed 's/.*\ //' | sed -e 's/^"//' -e 's/"$//')
LAST_COMMIT_EPOCH=$(date "+%s" -d ${LAST_COMMIT})
MINUTES_FROM_LAST_COMMIT=$(($((${CURRENT_TIME} - ${LAST_COMMIT_EPOCH})) / 60))
MAXIMUM_WINDOW=$((${GIT_UPDATE_PERIOD} + ${UPDATE_GRACE_TIME}))
[[ ${MINUTES_FROM_LAST_COMMIT} -lt ${MAXIMUM_WINDOW} ]] && curl -fsS -m 10 --retry 5 -o /dev/null ${HEALTHCHECKSIO_URL}
