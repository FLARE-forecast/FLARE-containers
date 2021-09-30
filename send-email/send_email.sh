#!/usr/bin/env bash

#Set Variables

DATE=$(date +%Y-%m-%d)
USERNAME=$(yq e '.gmail.username' config.yml)
PASSWORD=$(yq e '.gmail.password-hash' config.yml )
SENDER=$(yq e '.gmail.from' config.yml )
SUBJECT=$(yq e '.email.subject' config.yml )
CONTENT=$(yq e '.email.body' config.yml )
RECEIVER=$(yq e '.email.recepients' config.yml )

yq e '.email.attachments_github[]' config.yml > tmp.txt
while read -r line; do
  echo "$line$DATE.pdf" >> tmp_date.txt
done < tmp.txt

#Create a folder and download all files
mkdir $DATE
wget -i tmp_date.txt -P $DATE

#Copy the files from local directory
yq e 'email.attachments_local[]' config.yml > tmp.txt
while read -r line; do
  cp $line ./$DATE
done < tmp.txt

#Set the command related to attachments
ls ./$DATE > attachments_list.txt
while read line; do
  echo "-a ./$DATE/$line" >> attach_command.txt
done < attachments_list.txt

while read line; do
  ATTACHMENTS_LIST="$ATTACHMENTS_LIST $line"
done < attach_command.txt

# Send the email
echo "CONTENT" | s-nail -:/ -v -s $SUBJECT\
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
rm attachments_list.txt attach_command.txt tmp_date.txt tmp.txt
rm -r $DATE
