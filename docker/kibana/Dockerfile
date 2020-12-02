FROM docker.elastic.co/kibana/kibana:6.8.13

MAINTAINER doublebyte <joana.simoes@geocat.net>

copy ./docker-entry.sh /docker-entry.sh
COPY ./wait-for-it.sh /wait-for-it.sh
#COPY ./config/kibana.yml /usr/share/kibana/config/kibana.yml

COPY ./config/kibana.yml /kibana.yml

USER root

RUN chown kibana /kibana.yml
RUN chown kibana /usr/share/kibana/config/kibana.yml

USER kibana
ADD ./VERSION .

RUN /usr/share/kibana/bin/kibana-plugin remove x-pack

