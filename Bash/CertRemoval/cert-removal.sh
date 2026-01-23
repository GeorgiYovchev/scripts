#!/bin/bash

echo ''
echo '#####################################################################'
echo '# >>> Script for expired .pem files - check/praparation/removal <<< #'
echo '#####################################################################'
echo '#                                                                   #'
echo '#  Select operation:                                                #'
echo '#    1) List all .pem files with their expiration date              #'
echo "#    2) Create expired_"$currentdate".txt file with all expired .pem files        #"
echo "#    3) List contents of expired_"$currentdate".txt                               #"
echo "#    4) Remove all .pem files from expired_"$currentdate".txt                     #"
echo '#    5) Exit                                                        #'
echo '#                                                                   #'
echo '#####################################################################'


currentdate=$(date -d "$date - 7 days" --iso-8601)

echo ''
read -p ">>> Enter number (1-5): " n
echo ''

case $n in
   1) echo 'List all .pem files with their expiration date';
        for pem in ./certs/*.pem; do
                printf '%s: %s\n' \
                "$(date --date="$(openssl x509 -enddate -noout -in "$pem"|cut -d= -f 2)" --iso-8601)" \
                "$pem";
        done | sort;;
##############################################
   2) echo "Create expired_"$currentdate".txt file with all expired .pem files"
        : > expired_"$currentdate".txt;
	for pem in ./certs/*.pem; do
		certdate=$(date --date="$(openssl x509 -enddate -noout -in "$pem"|cut -d= -f 2)" --iso-8601)
		if [ $(date -d $currentdate +"%Y%m%d") -ge $(date -d $certdate +"%Y%m%d") ]; then
	
			echo "$certdate $pem" >> expired_"$currentdate".txt
		fi
	done;
        sort -k 1 -o expired_"$currentdate".txt expired_"$currentdate".txt;;
##############################################
   3) echo "List contents of expired_"$currentdate".txt";
        cat expired_"$currentdate".txt;;
##############################################
   4) echo "Remove all .pem files listed in expired_"$currentdate".txt";
        awk '{print $2}' expired_"$currentdate".txt | xargs rm;;
##############################################
   5) echo 'Exit';
        break;;
##############################################
esac



