#!/bin/bash
# pem_check_expiration.sh
# Script to check .pem certificates in a folder for expiration

CERT_DIR="${1:-.}"   # Default to current dir if not passed
NOW=$(date +%s)

EXPIRED_24H=()
EXPIRING_3DAYS=()

for cert in "$CERT_DIR"/*.pem; do
    [ -e "$cert" ] || continue   # Skip if no .pem files

    # Extract notAfter field and convert to epoch
    enddate=$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | cut -d= -f2)
    if [ -z "$enddate" ]; then
        echo "Could not read expiration date from $cert"
        continue
    fi

    enddate_epoch=$(date -d "$enddate" +%s)

    diff=$(( enddate_epoch - NOW ))

    if [ "$diff" -lt 0 ] && [ "$diff" -gt -86400 ]; then
        # Expired in last 24h (86400s = 24h)
        EXPIRED_24H+=("$cert (expired on $enddate)")
    elif [ "$diff" -gt 0 ] && [ "$diff" -lt 259200 ]; then
        # Will expire in next 3 days (259200s = 3d)
        EXPIRING_3DAYS+=("$cert (expires on $enddate)")
    fi
done

echo "======================"
echo " Certificates expired in last 24 hours:"
if [ ${#EXPIRED_24H[@]} -eq 0 ]; then
    echo " None"
else
    printf '%s\n' "${EXPIRED_24H[@]}"
fi

echo
echo " Certificates expiring in next 3 days:"
if [ ${#EXPIRING_3DAYS[@]} -eq 0 ]; then
    echo " None"
else
    printf '%s\n' "${EXPIRING_3DAYS[@]}"
fi
echo "======================"
