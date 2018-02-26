FROM docker.elastic.co/elasticsearch/elasticsearch:5.6.7

MAINTAINER doublebyte <joana.simoes@geocat.net>

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin remove x-pack

COPY  readonlyrest-1.16.16_es5.6.7.zip ./readonlyrest.zip

COPY /config/elasticsearch.yml /elasticsearch.yml
COPY /config/readonlyrest.yml /readonlyrest.yml

USER root
COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh

RUN yum install -y openssl
USER elasticsearch

ADD ./VERSION .

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["elasticsearch"]
