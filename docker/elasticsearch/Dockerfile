FROM docker.elastic.co/elasticsearch/elasticsearch:5.6.7

MAINTAINER doublebyte <joana.simoes@geocat.net>

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin remove x-pack

COPY /config/elasticsearch.yml /elasticsearch.yml

USER root
COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh

RUN yum install -y openssl
USER elasticsearch

ADD ./VERSION .

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["elasticsearch"]
