FROM whosonfirst-data-geo:latest

ARG PYMZWOF_INDEX_VERSION=0.1.4
ARG PYMZWOF_UTILS_VERSION=0.4.5
ARG PYMZWOF_SEARCH_VERSION=0.4.6

ARG MYSQL_CONFIG

# these are built in Dockerfile.tools

COPY --from=whosonfirst-data-indexing-tools:latest /usr/local/bin/wof-list-repos /usr/bin
COPY --from=whosonfirst-data-indexing-tools:latest /usr/local/bin/wof-clone-repos /usr/bin
COPY --from=whosonfirst-data-indexing-tools:latest /usr/local/bin/wof-s3-sync /usr/bin
COPY --from=whosonfirst-data-indexing-tools:latest /usr/local/bin/wof-mysql-index /usr/bin

RUN apk update && apk upgrade \
    && apk add git git-lfs make ca-certificates py-pip \
    #
    && mkdir /build \
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

COPY bin/index-data /usr/local/bin/