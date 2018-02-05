#!/bin/bash

set -e

cd /usr/share/kibana/

echo $SERVER_BASEPATH
echo $REGIONMAP_LAYERS_URL
#echo $USERNAME
echo $PASSWORD

cp /kibana.yml /usr/share/kibana/config/kibana.yml

sed "s#SERVER_BASEPATH#$SERVER_BASEPATH#g" -i /usr/share/kibana/config/kibana.yml
sed "s#REGIONMAP_LAYERS_URL#$REGIONMAP_LAYERS_URL#g" -i /usr/share/kibana/config/kibana.yml
sed "s#PASSWORD#$PASSWORD#g" -i /usr/share/kibana/config/kibana.yml

/usr/share/kibana/bin/kibana-plugin remove x-pack

exec /usr/share/kibana/bin/kibana --cpu.cgroup.path.override=/ --cpuacct.cgroup.path.override=/ ${longopts} "$@"
