FROM docker.elastic.co/elasticsearch/elasticsearch:6.8.13

MAINTAINER doublebyte <joana.simoes@geocat.net>

COPY /config/elasticsearch.yml /elasticsearch.yml

USER root
COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh

RUN yum install -y openssl
USER elasticsearch

ADD ./VERSION .

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["elasticsearch"]
