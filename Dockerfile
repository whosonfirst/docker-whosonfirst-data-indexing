# https://github.com/whosonfirst/go-whosonfirst-github
# https://github.com/whosonfirst/go-whosonfirst-s3
# https://github.com/whosonfirst/go-whosonfirst-mysql
# https://github.com/sfomuseum/go-whosonfirst-elasticsearch
# https://github.com/sfomuseum/runtimevar

# first build Go tools

FROM golang:1.17-alpine as gotools

RUN mkdir /build

RUN apk update && apk upgrade \
    && apk add git make gcc libc-dev \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-github.git \
    && cd go-whosonfirst-github \
    && go build -mod vendor -o /usr/local/bin/wof-clone-repos cmd/wof-clone-repos/main.go \
    && go build -mod vendor -o /usr/local/bin/wof-list-repos cmd/wof-list-repos/main.go \           
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-s3.git \
    && cd go-whosonfirst-s3 \       	
    && go build -mod vendor -o /usr/local/bin/wof-s3-sync cmd/wof-s3-sync/main.go \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-mysql.git \
    && cd go-whosonfirst-mysql \
    && go build -mod vendor -o /usr/local/bin/wof-mysql-index cmd/wof-mysql-index/main.go \
    #
    && cd /build \
    && git clone https://github.com/sfomuseum/go-whosonfirst-elasticsearch.git \
    && cd go-whosonfirst-elasticsearch \
    && go build -mod vendor -o /usr/local/bin/es-whosonfirst-index cmd/es-whosonfirst-index/main.go \
    && go build -mod vendor -o /usr/local/bin/es2-whosonfirst-index cmd/es2-whosonfirst-index/main.go \        
    #
    && cd /build \
    && git clone https://github.com/sfomuseum/runtimevar.git \    
    && cd runtimevar \
    && go build -mod vendor -o /usr/local/bin/runtimevar cmd/runtimevar/main.go \
    #
    && cd && rm -rf /build 
    
FROM alpine

RUN mkdir /usr/local/data

RUN apk update && apk upgrade \
    && apk add git python3 py-pip ca-certificates jq \
    #
    && pip install awscli

COPY --from=gotools /usr/local/bin/wof-list-repos /usr/bin
COPY --from=gotools /usr/local/bin/wof-clone-repos /usr/bin
COPY --from=gotools /usr/local/bin/wof-s3-sync /usr/bin
COPY --from=gotools /usr/local/bin/wof-mysql-index /usr/bin
COPY --from=gotools /usr/local/bin/es-whosonfirst-index /usr/bin
COPY --from=gotools /usr/local/bin/es2-whosonfirst-index /usr/bin
COPY --from=gotools /usr/local/bin/runtimevar /usr/bin

COPY bin/index.sh /usr/local/bin/
COPY bin/index.sh.env /usr/local/bin/