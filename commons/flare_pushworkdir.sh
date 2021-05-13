#!/bin/bash
PROGNAME=$(basename $0)

error_exit()
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}

DIRECTORY_CONTAINER_SHARED="/home/user/flare/shared"

s3_endpoint=$1
s3_access_key=$2
s3_secret_key=$3
CONTAINER=$4
LAKE=$5

TIMESTAMP=$(date +"%Y%m%d")
# mkdir -p ~/.ssh/

cd /home/user
tar -czvf ${LAKE}_${TIMESTAMP}_${CONTAINER}_workingdirectory.tar.gz -C ${DIRECTORY_CONTAINER_SHARED} ${CONTAINER}
mc cp ${LAKE}_${TIMESTAMP}_${CONTAINER}_workingdirectory.tar.gz flare/${LAKE}/${CONTAINER}/ || error_exit "$LINENO: An error has occurred in push $FLARE_CONTAINER_NAME working directory."
rm ${LAKE}_${TIMESTAMP}_${CONTAINER}_workingdirectory.tar.gz
