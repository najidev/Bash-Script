#!/bin/bash
# set alert level 90% is default
ALERT=90
# Exclude list of unwanted monitoring, if several partions then use "|" to separate the partitions.
EXCLUDE_LIST="/auto/ripper|loop"
LIST=( "example1@gmail.com" "example1@gmail.com" "example1@gmail.com" )
sender="example1@gmail.com"
gmpwd="smtp password goes here"
sub="Virtual Machine ran out of space"
#
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#

main_prog() {
while read -r output;
do
  #Get public ip of ur VM
  publicip=`dig TXT +short o-o.myaddr.l.google.com @ns1.google.com`
  usep=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1)
  partition=$(echo "$output" | awk '{print $2}')
  if [ $usep -ge $ALERT ] ; then
		echo "Running out of space \"$partition ($usep%)\" on server $(hostname), $(date)\nPublic IP: $publicip" > "alert.txt"
		body="Running out of space \"$partition ($usep%)\" on server $(hostname), $(date)\nPublic IP: $publicip"
		for i in "${LIST[@]}"
    do
  		receiver=$i
  		file=alert.txt
      MIMEType=`file --mime-type "$file" | sed 's/.*: //'`
 			curl -s --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
 			--mail-from $sender \
 			--mail-rcpt $receiver\
 			--user $sender:$gmpwd \
 			-F '=(;type=multipart/mixed' -F "=$body;type=text/plain" -F "file=@$file;type=$MIMEType;encoder=base64" -F '=)' \
      -H "Subject: $sub" -H "From: Alerts <$sender>" -H "To: $i"
    done
  fi
done
}

if [ "$EXCLUDE_LIST" != "" ] ; then
  df -H | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}' | main_prog
else
  df -H | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}' | main_prog
fi
