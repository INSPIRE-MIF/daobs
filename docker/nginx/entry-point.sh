#!/bin/sh
# generate self signed ssl cert only if all cert files are empty or nonexistent

set -e

RED='\033[0;31m'
NC='\033[0m' # No Color

mkdir -p /etc/nginx/private/
mkdir -p /etc/nginx/certs/


echo $GENERATESSL
if [ -z "${GENERATESSL}" ] || [ "${GENERATESSL}" != "NO" ]; then
  echo "Generating self-signed SSL certificates"

  apk update && apk add --no-cache openssl

  mkdir -p /certs

  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /certs/priv.key -out /certs/cert.crt \
  -subj  "$CERTIFICATESUBJ"

  cp /certs/priv.key /etc/nginx/private/
  cp /certs/cert.crt /etc/nginx/certs/
  rm -rf /certs

else
    echo "SSL Variables are set: Skipping SSL certificate generation"

    if [ ! -f "/tmp/priv.key" ]; then echo -e "${RED}Make sure that you are pointing to a valid private key${NC}"; fi
    if [ ! -f "/tmp/cert.crt" ]; then echo -e "${RED}Make sure that you are pointing to a valid public certificate${NC}"; fi

    cp /tmp/priv.key /etc/nginx/private/
    cp /tmp/cert.crt /etc/nginx/certs/

fi

echo "Replacing dashboard url"

cp /nginx.conf /etc/nginx/nginx.conf
sed "s#DASHBOARD_URL#$DASHBOARD_URL#g" -i /etc/nginx/nginx.conf


echo "Starting nginx"

nginx -g "daemon off;"
