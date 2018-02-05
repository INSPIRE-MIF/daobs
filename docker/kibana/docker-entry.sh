#!/bin/bash

set -e

cd /usr/share/kibana/

#echo $PASSWORD

cp /kibana.yml /usr/share/kibana/config/kibana.yml

sed "s#PASSWORD#$PASSWORD#g" -i /usr/share/kibana/config/kibana.yml

/usr/share/kibana/bin/kibana-plugin remove x-pack

exec /usr/share/kibana/bin/kibana --cpu.cgroup.path.override=/ --cpuacct.cgroup.path.override=/ ${longopts} "$@"
