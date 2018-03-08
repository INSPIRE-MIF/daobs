#!/bin/bash

set -e

# Add elasticsearch as command if needed
if [ "${1:0:1}" = '-' ]; then
  set -- elasticsearch "$@"
fi

cp /elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml
cp /readonlyrest.yml /usr/share/elasticsearch/config/readonlyrest.yml

# Replace node name and discovery hosts
sed "s#NODE_NAME#$NODE_NAME#g" -i /usr/share/elasticsearch/config/elasticsearch.yml
sed "s#NODE_MASTER#$NODE_MASTER#g" -i /usr/share/elasticsearch/config/elasticsearch.yml
sed "s#MINIMUM_MASTER_NODE#$MINIMUM_MASTER_NODE#g" -i /usr/share/elasticsearch/config/elasticsearch.yml
sed "s#NODE_DATA#$NODE_DATA#g" -i /usr/share/elasticsearch/config/elasticsearch.yml
#sed "s#debug#info#g" -i /usr/share/elasticsearch/config/log4j2.properties

#sed "s#KIBANA_RW_USER#$KIBANA_RW_USER#g" -i /usr/share/elasticsearch/config/readonlyrest.yml
#sed "s#KIBANA_RW_PASSWORD#$KIBANA_RW_PASSWORD#g" -i /usr/share/elasticsearch/config/readonlyrest.yml
#sed "s#KIBANA_SRV_PASSWORD#$KIBANA_SRV_PASSWORD#g" -i /usr/share/elasticsearch/config/readonlyrest.yml

sed "s#KIBANA_SRV_PASSWORD#$ADMINPASSWORD#g" -i /usr/share/elasticsearch/config/readonlyrest.yml

if [ -z "$DISCOVERY_ZEN" ]
then
   echo "DISCOVERY_ZEN is unset. This is master node."
else
    sed "s%#discovery.zen.ping.unicast.hosts: DISCOVERY_ZEN%discovery.zen.ping.unicast.hosts: $DISCOVERY_ZEN%g" -i /usr/share/elasticsearch/config/elasticsearch.yml
fi

if [ $ELASTICSEARCH_MASTER = "YES" ]
then

  # The virtual file /proc/self/cgroup should list the current cgroup
  # membership. For each hierarchy, you can follow the cgroup path from
  # this file to the cgroup filesystem (usually /sys/fs/cgroup/) and
  # introspect the statistics for the cgroup for the given
  # hierarchy. Alas, Docker breaks this by mounting the container
  # statistics at the root while leaving the cgroup paths as the actual
  # paths. Therefore, Elasticsearch provides a mechanism to override
  # reading the cgroup path from /proc/self/cgroup and instead uses the
  # cgroup path defined the JVM system property
  # es.cgroups.hierarchy.override. Therefore, we set this value here so
  # that cgroup statistics are available for the container this process
  # will run in.
  export ES_JAVA_OPTS="-Des.cgroups.hierarchy.override=/ $ES_JAVA_OPTS"

  cat /readonlyrest.yml >> /usr/share/elasticsearch/config/elasticsearch.yml

  export TESTREADONLYREST=$(/usr/share/elasticsearch/bin/elasticsearch-plugin list | grep readonlyrest)
  if [ -z "$TESTREADONLYREST" ]
  then
    bin/elasticsearch-plugin install file:/usr/share/elasticsearch/readonlyrest.zip
  fi
  export TESTREADONLYREST=''

  export SERVERNAME=localhost

  rm -rf /tmp/ssl
  mkdir -p /tmp/ssl
  keytool -genkey -keyalg RSA -noprompt -alias $SERVERNAME -dname "CN=$SERVERNAME,OU=IDM,O=EEA,L=IDM1,C=DK" -keystore /tmp/ssl/self.jks -storepass $KIBANA_SRV_PASSWORD -keypass $KIBANA_SRV_PASSWORD
  keytool -keystore  /tmp/ssl/self.jks -alias $SERVERNAME -export -file  /tmp/ssl/self.cert

  chmod 400 /tmp/ssl/*

fi

# Drop root privileges if we are running elasticsearch
# allow the container to be started with `--user`
if [ "$1" = 'elasticsearch' -a "$(id -u)" = '0' ]; then
  # Change the ownership of user-mutable directories to elasticsearch
  for path in \
    /usr/share/elasticsearch/data \
    /usr/share/elasticsearch/logs \
  ; do
    chown -R elasticsearch:elasticsearch "$path"
  done

  set -- gosu elasticsearch "$@"
  #exec gosu elasticsearch "$BASH_SOURCE" "$@"
fi


# As argument is not related to elasticsearch,
# then assume that user wants to run his own process,
# for example a `bash` shell to explore this image
exec "$@"
