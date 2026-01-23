#!/bin/bash

filename=''

for file in ./*; do
    filename=`echo "$file" | cut -d '.' -f2 | sed -e 's-/--'`
#    echo "+++ $filename"
    if [ -f "$filename.csv" ]; then
        echo "+++ $filename"

	cp "$filename".csv "$filename".ps1

	#replace comma with newlines
	sed -i -e 's/,/\r\n/g' "$filename".ps1

	#remove blank lines
	sed -i -e '/^\r/d' "$filename".ps1

	#create script from domains
	sed -i -e 's/^/Remove-IISSiteBinding -RemoveConfigOnly -Confirm:$false -Name "prod-pronet" -BindingInformation "*:80:/g' "$filename".ps1
	sed -i -e 's/\r/";/g' "$filename".ps1

	#add memory clear every 50 rows
	sed -i -e '0~49 s/$/\nRemove-Variable * -ErrorAction SilentlyContinue; Remove-Module *; $error.Clear();/g' "$filename".ps1

	#add memory clear as last line
	echo -e 'Remove-Variable * -ErrorAction SilentlyContinue; Remove-Module *; $error.Clear();' >> "$filename".ps1

	#add start date
#        echo 'sed -i -e "1 i Write-Output \"\"; Write-Output \"\$\(Get-Date\) \<\<\< Start "$filename".ps1 \>\>\>\"; Write-Output \"\";" "$filename".ps1'
	sed -i -e "1 i Write-Output \"\"; Write-Output \"\"; Write-Output \"\$\(Get-Date\)        \<\<\< Start $filename.ps1 \>\>\>\";" "$filename".ps1

#	echo 'sed -i -e "2 i Write-Output \"\"; Write-Output \"Removing unused bindings ...\"; Write-Output \"\";" "$filename".ps1'
	sed -i -e "2 i Write-Output \"\"; Write-Output \"Removing unused bindings ...\"; Write-Output \"\";" "$filename".ps1

        #add finish date
	echo -e "Write-Output \"\"; Write-Output \"\"; Write-Output \"\$(Get-Date)        <<< Finish "$filename".ps1 >>>\"; Write-Output \"\";" >> "$filename".ps1
    fi
done

mkdir ./scripts
mv *.ps1 ./scripts/
