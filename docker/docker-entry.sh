#/bin/bash

cd /daobs-data-dir/datadir/;
elasticdump \
  --input=index-dashboards-mapping.json \
  --output=http://kibana_server:password@elasticsearch:9200/.dashboards \
  --type=mapping \
  --headers='{"Content-Type": "application/json"}'

elasticdump \
  --input=index-dashboards.json \
  --output=http://kibana_server:password@elasticsearch:9200/.dashboards \
  --type=data \
  --headers='{"Content-Type": "application/json"}'

echo -e "\e[96mStart tomcat\e[0m"

cd $CATALINA_HOME
catalina.sh run

