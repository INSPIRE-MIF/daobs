#!/bin/bash

set -e

cd /usr/share/kibana/

#echo $PASSWORD

cp /kibana.yml /usr/share/kibana/config/kibana.yml

sed "s#KIBANA_SRV_PASSWORD#$KIBANA_SRV_PASSWORD#g" -i /usr/share/kibana/config/kibana.yml

exec /usr/share/kibana/bin/kibana --cpu.cgroup.path.override=/ --cpuacct.cgroup.path.override=/ ${longopts} "$@"
