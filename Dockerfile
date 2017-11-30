FROM openjdk:8-jre-alpine

MAINTAINER Guillaume Simonneau <simonneaug@gmail.com>
LABEL Description="elasticsearch searchguard search-guard"

ENV ES_VERSION 5.6.0
ENV DOWNLOAD_URL "https://artifacts.elastic.co/downloads/elasticsearch"
ENV ES_TARBAL "${DOWNLOAD_URL}/elasticsearch-${ES_VERSION}.tar.gz"
ENV ES_TARBALL_ASC "${DOWNLOAD_URL}/elasticsearch-${ES_VERSION}.tar.gz.asc"
ENV GPG_KEY "46095ACC8548582C1A2699A9D27D666CD88E42B4"

# Install Elasticsearch.
RUN apk add --no-cache --update bash ca-certificates su-exec util-linux curl
RUN apk add --no-cache -t .build-deps gnupg openssl \
  && cd /tmp \
  && echo "===> Install Elasticsearch..." \
  && curl -o elasticsearch.tar.gz -Lskj "$ES_TARBAL"; \
	if [ "$ES_TARBALL_ASC" ]; then \
		curl -o elasticsearch.tar.gz.asc -Lskj "$ES_TARBALL_ASC"; \
		export GNUPGHOME="$(mktemp -d)"; \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY"; \
		gpg --batch --verify elasticsearch.tar.gz.asc elasticsearch.tar.gz; \
		rm -r "$GNUPGHOME" elasticsearch.tar.gz.asc; \
	fi; \
  tar -xf elasticsearch.tar.gz \
  && ls -lah \
  && mv elasticsearch-$ES_VERSION /elasticsearch \
  && adduser -DH -s /sbin/nologin elasticsearch \
  && echo "===> Installing search-guard..." \
  && /elasticsearch/bin/elasticsearch-plugin install -b "com.floragunn:search-guard-5:$ES_VERSION-16" \
  && echo "===> Creating Elasticsearch Paths..." \
  && for path in \
  	/elasticsearch/config \
  	/elasticsearch/config/scripts \
  	/elasticsearch/plugins \
  ; do \
  mkdir -p "$path"; \
  chown -R elasticsearch:elasticsearch "$path"; \
  done \
  && rm -rf /tmp/* \
  && apk del --purge .build-deps


RUN  mkdir -p /.backup/elasticsearch/
COPY config /.backup/elasticsearch/config

VOLUME /elasticsearch/config
VOLUME /elasticsearch/data
EXPOSE 9200 9300

# env
ENV CLUSTER_NAME="elasticsearch-default" \
    MINIMUM_MASTER_NODES=1 \
    NODE_NAME=NODE-1 \
    NODE_MASTER=true \
    NODE_DATA=true \
    NODE_INGEST=true \
    HTTP_ENABLE=true \
    HTTP_CORS_ENABLE=true \
    HTTP_CORS_ALLOW_ORIGIN=* \
    NETWORK_HOST="0.0.0.0" \
    ELASTIC_PWD="changeme" \
    KIBANA_PWD="changeme" \
    LOGSTASH_PWD="changeme" \
    BEATS_PWD="changeme" \
    HEAP_SIZE="256m" \
    CA_PWD="changeme" \
    TS_PWD="changeme" \
    KS_PWD="changeme" \
		HTTP_SSL=true \
    LOG_LEVEL=INFO \
    MEMORY_LOCK false \
    DISCOVERY_SERVICE elasticsearch-discovery

COPY ./src/ /run/
RUN chmod +x -R /run/

ENTRYPOINT ["/run/entrypoint.sh"]
CMD ["elasticsearch"]
