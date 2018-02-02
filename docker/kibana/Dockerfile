FROM docker.elastic.co/kibana/kibana:5.6.6

MAINTAINER doublebyte <joana.simoes@geocat.net>

copy ./docker-entry.sh /docker-entry.sh
COPY ./wait-for-it.sh /wait-for-it.sh
COPY ./config/kibana.yml /usr/share/kibana/config/kibana.yml   
