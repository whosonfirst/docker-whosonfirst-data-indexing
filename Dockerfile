FROM alpine:3.7 AS geo

RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "@edge-testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN apk update && \
  apk --no-cache --update upgrade musl && \
  apk add --upgrade --force-overwrite apk-tools@edge && \
  apk add --update --force-overwrite "proj-dev@edge-testing" "geos-dev@edge-testing" "gdal-dev@edge-testing" "gdal@edge-testing" && \
  rm -rf /var/cache/apk/*

FROM geo

ARG PYMZWOF_INDEX_VERSION=0.1.4
ARG PYMZWOF_UTILS_VERSION=0.4.5
ARG PYMZWOF_SEARCH_VERSION=0.4.6
ARG MYSQL_CONFIG

RUN apk update && apk upgrade \
    && apk add git make gcc libc-dev ca-certificates py-pip \
    #
    && mkdir /build \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-github.git \
    && cd go-whosonfirst-github && make bin \
    && mv bin/wof-clone-repos /usr/local/bin/ \
    && mv bin/wof-list-repos /usr/local/bin/ \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-s3.git \
    && cd go-whosonfirst-s3 && make bin \
    && mv bin/wof-s3-sync /usr/local/bin/ \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-mysql.git \
    && cd go-whosonfirst-mysql && make bin \
    && mv bin/wof-mysql-index /usr/local/bin/ \
    #
    && cd /build \
    && wget -O index.tar.gz https://github.com/whosonfirst/py-mapzen-whosonfirst-index/archive/${PYMZWOF_INDEX_VERSION}.tar.gz && tar -xvzf index.tar.gz \
    && cd py-mapzen-whosonfirst-index-${PYMZWOF_INDEX_VERSION} \
    && pip install -r requirements.txt . \
    #
    && cd /build \
    && wget -O utils.tar.gz https://github.com/whosonfirst/py-mapzen-whosonfirst-utils/archive/${PYMZWOF_UTILS_VERSION}.tar.gz && tar -xvzf utils.tar.gz \
    && cd py-mapzen-whosonfirst-utils-${PYMZWOF_UTILS_VERSION} \
    && pip install -r requirements.txt . \
    #
    && cd /build \    
    && wget -O search.tar.gz https://github.com/whosonfirst/py-mapzen-whosonfirst-search/archive/${PYMZWOF_SEARCH_VERSION}.tar.gz && tar -xvzf search.tar.gz \
    && cd py-mapzen-whosonfirst-search-${PYMZWOF_SEARCH_VERSION} \
    && pip install -r requirements.txt . \
    #
    && cd && rm -rf /build

RUN mkdir /usr/local/data
RUN mkdir -p /usr/local/whosonfirst/lockedbox

COPY bin/wof-test-index /usr/local/bin/