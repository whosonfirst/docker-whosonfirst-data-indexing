FROM alpine:latest

# https://proj4.org/download.html

ARG LIBGEOS_VERSION=3.7.1
ARG LIBGDAL_VERSION=2.4.0
ARG LIBPROJ_VERSION=5.2.0

RUN apk update && apk upgrade \
    && apk add coreutils git make ca-certificates py-pip libc-dev gcc g++ python-dev \
    #
    # https://github.com/appropriate/docker-postgis/blob/master/Dockerfile.alpine.template
    #
    && apk add --no-cache --virtual .build-deps-edge \
       --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
       --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
       gdal-dev geos-dev proj4-dev \
    #
    # or the hard way which takes _forever_ to build and doesn't always work...
    #
    # && apik add libc-dev gcc g++ linux-headers python-dev \       
    # && mkdir /build \
    #
    # && cd /build \
    # && wget https://download.osgeo.org/geos/geos-${LIBGEOS_VERSION}.tar.bz2 && tar -xvjf geos-${LIBGEOS_VERSION}.tar.bz2 \
    # && cd geos-${LIBGEOS_VERSION} && ./configure && make && make install \
    #
    # && cd /build \
    # && wget https://download.osgeo.org/gdal/${LIBGDAL_VERSION}/gdal-${LIBGDAL_VERSION}.tar.gz && tar -xvzf gdal-${LIBGDAL_VERSION}.tar.gz \
    # && cd gdal-${LIBGDAL_VERSION} && ./configure && make && make install \
    #
    # && cd /build \
    # && wget https://download.osgeo.org/proj/proj-{LIBPROJ_VERSION}.tar.gz && tar -xvzf proj-{LIBPROJ_VERSION}.tar.gz \
    # && cd proj-{LIBPROJ_VERSION} && ./configure && make && make install \
    # && cd / && rm -rf /build    
    #       
    && pip install gdal