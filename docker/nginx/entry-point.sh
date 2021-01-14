#!/bin/sh
# generate self signed ssl cert only if all cert files are empty or nonexistent

set -e

RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Replacing allowed_domain, dashboard & es url"

cp /nginx.conf /etc/nginx/nginx.conf
#sed "s#ALLOWED_DOMAIN#$ALLOWED_DOMAIN#g" -i /etc/nginx/nginx.conf
sed "s#DASHBOARD_URL#$DASHBOARD_URL#g" -i /etc/nginx/nginx.conf
sed "s#ES_URL#$ES_URL#g" -i /etc/nginx/nginx.conf


echo "Starting nginx"

nginx -g "daemon off;"
