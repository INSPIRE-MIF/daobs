#/bin/bash

echo -e "\e[91mLoad ES indexes\e[96m"
curl -X PUT http://elasticsearch:9200/records -d @/usr/local/tomcat/daobs/es/config/records.json;
curl -X PUT http://elasticsearch:9200/indicators -d @/usr/local/tomcat/daobs/es/config/indicators.json;

curl 'elasticsearch:9200/_cat/indices?v'

cd /usr/local/tomcat/daobs/dashboards/data/;
rm index-dashboards-mapping.json && rm index-dashboards.json;

elasticdump \
  --input=http://elasticsearch:9200/.dashboards \
  --output=index-dashboards-mapping.json \
  --type=mapping

elasticdump \
  --input=http://elasticsearch:9200/.dashboards \
  --output=index-dashboards.json

echo -e "\e[96mStart tomcat\e[0m"

cd $CATALINA_HOME
catalina.sh run
