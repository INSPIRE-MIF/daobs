FROM snuids/cerebro:v0.7.1

MAINTAINER doublebyte <joana.simoes@geocat.net>

COPY ./config/application.conf /opt/cerebro/conf/application.conf
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
