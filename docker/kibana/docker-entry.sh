#!/bin/bash

cd /usr/share/kibana/

/usr/share/kibana/bin/kibana-plugin remove x-pack

echo $SERVER_BASEPATH
echo $REGIONMAP_LAYERS_URL
echo $ELASTICSEARCH_USERNAME
echo $ELASTICSEARCH_PASSWORD

sed "s#SERVER_BASEPATH#$SERVER_BASEPATH#g" -i /usr/share/kibana/config/kibana.yml
sed "s#REGIONMAP_LAYERS_URL#$REGIONMAP_LAYERS_URL#g" -i /usr/share/kibana/config/kibana.yml
sed "s#ELASTICSEARCH_USERNAME#$ELASTICSEARCH_USERNAME#g" -i /usr/share/kibana/config/kibana.yml
sed "s#ELASTICSEARCH_PASSWORD#$ELASTICSEARCH_PASSWORD#g" -i /usr/share/kibana/config/kibana.yml

/usr/share/kibana/bin/kibana
