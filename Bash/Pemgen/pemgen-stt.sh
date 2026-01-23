#!/bin/bash

#!!!Requires Rename app - "sudo apt install rename"

#create Checks dir
mkdir Checks

#Domain list file should be namer domainlist.txt in main folder
cp *omain*.txt check-urls.bat
#sed -i -e 's/.com/.com"/' urlopen.bat
sed -i -e 's/^ultraplay./start "" "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe" https:\/\/ultraplay./' check-urls.bat
sed -i -e '/^\(start\|\r\)/!d' check-urls.bat
mv check-urls.bat Checks/check-urls.bat

echo ''
echo '------------------------------------------'
echo ''
echo -e "\033[33m@@@ URL-Open script created  \033[m"
echo ''
echo '------------------------------------------'
#echo ''
#sed -i -e 's/.com/.com"/' *omain*.txt
sed -i -e 's/^ultraplay./New-WebBinding -Name "prod-sportingtech" -IPAddress "*" -Port 80 -HostHeader "ultraplay./' *omain*.txt
sed -i -e '/^\(New\|\r\)/!d' *omain*.txt
#add CR at the end
echo -e "\r" >> *omain*.txt
#change only lines beginning with New
sed -i '/^New/ s/\r/\"\r/g' *omain*.txt
#echo ''
#echo '------------------------------------------'
echo ''
echo -e "\033[33m@@@ Domainlist file updated  \033[m"
echo ''
echo '------------------------------------------'
echo ''
#Checks if key and crt match each other
#Creates pem file if they match
for D in ./*; do
    if [ -d "$D" ] && [ "$D" != "./Checks" ]; then
        cd "$D"
	#Rename files to lowercase
	rename --force 'y/A-Z/a-z/' *
	echo "$D"
	#find key file
	if [ -f *key* ]; then
		key=$(openssl pkey -in *key* -pubout -outform pem | sha256sum)
		ls -A1 *key*; echo -e "\033[33m$key\033[m"
	else
		key=$(openssl pkey -in *KEY* -pubout -outform pem | sha256sum)
		ls -A1 *KEY*; echo -e "\033[33m$key\033[m"
	fi
	#find crt/cer file
	if [ -f *.cer ]; then
		cer=$(openssl x509 -in *.cer -pubkey -noout -outform pem | sha256sum)
		ls -A1 *.cer; echo -e "\033[33m$cer\033[m"
	else
		cer=$(openssl x509 -in *.crt -pubkey -noout -outform pem | sha256sum)
		ls -A1 *.crt; echo -e "\033[33m$cer\033[m"
	fi
	#key=$(openssl pkey -in *key* -pubout -outform pem | sha256sum)
	#cer=$(openssl x509 -in *.c* -pubkey -noout -outform pem | sha256sum)
	#ls -A1 *key*; echo -e "\033[33m$key\033[m"
	#ls -A1 *.c*; echo -e "\033[33m$cer\033[m"

	if [ "$key" = "$cer" ]; then
		echo -e "\033[32m----- MATCH -----\033[m"
		echo ''	
		if [ -f *key* ]; then
			if [ -f *.cer ]; then
				cat *key* *.cer > ../${PWD##*/}.pem
			else
				cat *key* *.crt > ../${PWD##*/}.pem
			fi
		else
			if [ -f *.cer ]; then
				cat *KEY* *.cer > ../${PWD##*/}.pem
			else
				cat *KEY* *.crt > ../${PWD##*/}.pem
			fi
		fi
		#cat *key* *.c* > ../${PWD##*/}.pem

		#add Enter at the end
		sed -i -e '$a\' ../${PWD##*/}.pem
		echo -e "\033[32m@@@ ${PWD##*/}.pem file created !\033[m"

		openssl x509 -in ../${PWD##*/}.pem  -noout -text > ../Checks/${PWD##*/}_pem.txt

		echo ''
		echo '----------------------'
		echo -e "\033[32m@@@ Check PEM file with >>>  openssl x509 -in ${PWD##*/}.pem  -noout -text  <<<  !\033[m"
		echo -e "\033[32m@@@ OR \033[m"
		echo -e "\033[32m@@@ Check generated file in Checks folder  >>> ${PWD##*/}_pem.txt <<<  !\033[m"
		echo '------------------------------------------'
		echo ''
	else
		echo -e "\033[31m----- NOT MATCH -----\033[m"
		echo ''
		echo '----------------------'
		echo -e "\033[31m----- MANUALLY CHECK Key and Cert files-----\033[m"
		echo '---'
		echo 'openssl pkey -in KEYFILE -pubout -outform pem | sha256sum'
		echo 'openssl x509 -in CERTFILE -pubkey -noout -outform pem | sha256sum'
		echo '------------------------------------------'
		echo ''
	fi
        cd ..
    fi
done
echo '----------------------'
dos2unix *.pem
echo 'dos2unix ready'
echo '----------------------'
echo ''
