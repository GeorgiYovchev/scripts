for cert in /etc/haproxy/certs/*; do
  echo ">>> File: $cert"
  # Extract Common Name (CN)
  CN=$(openssl x509 -noout -subject -in "$cert" | sed -n 's/.*CN=\([^/]*\).*/\1/p')
  # Extract SANs
  SAN=$(openssl x509 -noout -text -in "$cert" | grep -A1 "Subject Alternative Name" | tail -n1 | sed 's/.*://')
  # Expiration date
  EXP=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
  # Days left
  DAYS=$(echo $(( ( $(date -d "$EXP" +%s) - $(date +%s) ) / 86400 )))

  echo "    CN     : $CN"
  echo "    SAN    : $SAN"
  echo "    Expiry : $EXP"
  echo "    Days   : $DAYS days left"
  echo
done
