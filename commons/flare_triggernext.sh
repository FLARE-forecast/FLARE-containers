CONFIG_FILE="flare-config.yml"
DIRECTORY_CONTAINER_SHARED="/root/flare/shared"
APIHOST=$1
AUTH=$2
CONTAINER_NAME=$3
LAKE=$4


NEXR_TRIGGER=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} openwhisk.next-trigger.name)
NEXR_TRIGGER_PAYLOAD=$(yq r ${DIRECTORY_CONTAINER_SHARED}/${CONTAINER_NAME}/${CONFIG_FILE} openwhisk.next-trigger.payload)

# apt-get update && apt-get install curl -y

if [ $CONTAINER_NAME == "flare-download-noaa" ]
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
            curl -u ${AUTH} https://${APIHOST}/api/v1/namespaces/_/triggers/$NEXR_TRIGGER -X POST -H "Content-Type: application/json" -d "$NEXR_TRIGGER_PAYLOAD"
        fi
    fi

else
   curl -u $AUTH https://$APIHOST/api/v1/namespaces/_/triggers/$NEXR_TRIGGER \
    -X POST -H "Content-Type: application/json" \
    -d "$NEXR_TRIGGER_PAYLOAD"
fi



