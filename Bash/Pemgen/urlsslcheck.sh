#!/bin/bash


#number of .pem files found
pemCount=0
#number of urls with OK cert
okCount=0
#number of urls with NOT OK cert
notOkCount=0
#number of urls that cannot open
noSiteCount=0

#remove bad chars
dos2unix domain\ list.txt

echo "--------------------------------------------"

#sed '/^[[:space:]]*$/d' domain\ list.txt | while read line; do 
sed '/^[[:space:]]*$/d' domain\ list.txt > /dev/null
while read line; do
    #check if there is .pem file with same name or continue checks with last found pem file
    certfiletest=$(echo "$line" | sed 's/New-WebBinding -Name \"prod-pronet\" -IPAddress \"\*\" -Port 80 -HostHeader \"ultraplay\.//' | sed 's/\.com\"//')
    certfiletest+='.pem'
#    echo "$certfiletest"
    if [ -f $certfiletest ]; then
        echo -e "\033[93m New .pem file found! \033[m"
        certfile=$certfiletest
        pemCount=$((pemCount+1))
    fi
line=$(echo "$line" | sed 's/New-WebBinding -Name \"prod-pronet\" -IPAddress \"\*\" -Port 80 -HostHeader \"//' | sed 's/\"//')
#check ssl cers with curl
    if [ ! -z "$line" ]; then
        echo "https://$line"
        if [ "$(curl https://$line -vI --cacert $certfile 2>&1 | grep 'SSL certificate')" = "*  SSL certificate verify ok." ]; then
            echo -e "\033[32m --> Certificate is OK \033[m"
            okCount=$((okCount+1))
        elif [ "$(curl https://$line -vI --cacert $certfile 2>&1 | grep 'SSL certificate')" = "" ]; then
            echo -e "\033[93m --> Cannot open site - DNS records not configured?  \033[m"
            noSiteCount=$((noSiteCount+1))
        else
            echo -e "\033[31m --> Certificate is NOT OK or is using old .pem file \033[m"
            notOkCount=$((notOkCount+1))
        fi

        echo "--------------------------------------------"
    fi
done < domain\ list.txt

#Stats
echo ''
echo ''
echo '####################################'
echo 'Total Statistics'
echo '####################################'
echo "PEM files found               : $pemCount"
echo '------------------------------------'
echo "OK sites                      : $okCount"
echo "Not OK/using old pem sites    : $notOkCount"
echo "Can\`t open sites              : $noSiteCount"
echo '####################################'
