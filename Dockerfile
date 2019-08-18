# first build all the gdal/libgeos stuff

FROM alpine:3.7 AS geo

RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "@edge-testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN apk update && \
  apk --no-cache --update upgrade  && \  
  apk add --upgrade --force-overwrite apk-tools@edge && \
  apk add --update --force-overwrite "proj-dev@edge-testing" "geos-dev@edge-testing" "gdal-dev@edge-testing" "gdal@edge-testing" && \
  rm -rf /var/cache/apk/*

# next build all the Go tools

FROM golang:1.12-alpine as gotools

RUN apk update && apk upgrade \
    && apk add git make libc-dev gcc \
    #
    && mkdir /build \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-github.git \
    && cd go-whosonfirst-github && make tools \
    && mv bin/wof-clone-repos /usr/local/bin/ \
    && mv bin/wof-list-repos /usr/local/bin/ \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-s3.git \
    && cd go-whosonfirst-s3 && make tools \
    && mv bin/wof-s3-sync /usr/local/bin/ \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-mysql.git \
    && cd go-whosonfirst-mysql && make tools \
    && mv bin/wof-mysql-index /usr/local/bin/ \
    #
    && cd / && rm -rf /build

# finally build the actual Docker container with all the things...

FROM geo

ARG PYMZWOF_INDEX_VERSION=0.1.4
ARG PYMZWOF_UTILS_VERSION=0.4.5
ARG PYMZWOF_SEARCH_VERSION=0.4.9
ARG MYSQL_CONFIG

# See the way `py-mapzen-whosonfirst-index` and `py-mapzen-whosonfirst-utils` are using
# the old-skool no-v-prefix release format? Yeah, that... (20190810/straup)

RUN apk update && apk upgrade \
    && apk add git make gcc libc-dev ca-certificates py-pip curl \
    #
    && pip install awscli \
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
    && wget -O search.tar.gz https://github.com/whosonfirst/py-mapzen-whosonfirst-search/archive/v${PYMZWOF_SEARCH_VERSION}.tar.gz && tar -xvzf search.tar.gz \
    && cd py-mapzen-whosonfirst-search-${PYMZWOF_SEARCH_VERSION} \
    && pip install -r requirements.txt . \
    #
    && cd && rm -rf /build

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_data_volumes.html
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-storage.html

# So... I don't really understand why this is but:
# If we create a /usr/local/data directory here using `RUN mkdir...` or
# If we create a /usr/local/data volume here using `VOLUME ...` or
# If we create a data source and volume in the ECS task definition (see AWS docs above) then
# ... we always run out of disk space for large repos (whosonfirst-data-admin-us, etc.) when
# this is run as an (AWS) Fargate container. But:
#
# If we just assume the standard Fargate container volume (10GB) and `mkdir /usr/local/data`
# at runtime (in `bin/wof-index-data`) then... it seems to work.
# If someone can explain to me what's actually going on here I'd be grateful.
#
# There's a better than 50/50 chance we'll need to move away from Fargate containers in favour
# of EC2 containers, at least until the former support EFS volumes (disk I/O anyone...) but
# we'll see how far this set up gets us for now.
#
# Another possibility is to use S3/FUSE as a filesystem but I can't see that not being inefficient
# and slow... https://github.com/kahing/goofys
#
# (20190818/straup)

COPY --from=gotools /usr/local/bin/wof-clone-repos /usr/local/bin/wof-clone-repos
COPY --from=gotools /usr/local/bin/wof-list-repos /usr/local/bin/wof-list-repos
COPY --from=gotools /usr/local/bin/wof-s3-sync /usr/local/bin/wof-s3-sync
COPY --from=gotools /usr/local/bin/wof-mysql-index /usr/local/bin/wof-mysql-index

COPY bin/wof-index-data /usr/local/bin/
COPY bin/wof-test-permissions /usr/local/bin/