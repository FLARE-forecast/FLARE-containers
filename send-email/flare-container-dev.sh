#!/usr/bin/env bash

### User-defined and Runtime
##############################################################################

#Set Variables
CONTAINER_NAME=${1}
if [ $# -eq 2 ]; then
  CONFIG_FILE="${2}.yml"
fi
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
rm -r $DATE *.txt
