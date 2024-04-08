# Dockerfile to build a container used to index a specific `whosonfirst-data` repository
# using the `index.sh` tool. This tool is configured by the use of a `index.sh.env` file.
# Both files are expected to be found in the `bin` folder of this repository and are copied
# to the final container.

# First build Go tools

FROM golang:1.22-alpine as gotools

RUN mkdir /build

RUN apk update && apk upgrade \
    && apk add git make gcc libc-dev \
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-github.git \
    && cd go-whosonfirst-github \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-clone-repos cmd/wof-clone-repos/main.go \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-list-repos cmd/wof-list-repos/main.go \           
    #
    # Not actually used... but maybe some day?
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-mysql.git \
    && cd go-whosonfirst-mysql \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-mysql-index cmd/wof-mysql-index/main.go \
    #
    # Deprecated - Spelunker v1
    #
    && cd /build \
    && git clone https://github.com/sfomuseum/go-whosonfirst-elasticsearch.git \
    && cd go-whosonfirst-elasticsearch \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/es2-whosonfirst-index cmd/es2-whosonfirst-index/main.go \
    #
    # The new new (WIP) – Spelunker v2
    #
    && cd /build \
    && git clone https://github.com/whosonfirst/go-whosonfirst-opensearch.git \
    && cd go-whosonfirst-opensearch \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/wof-opensearch-index cmd/wof-opensearch-index/main.go \
    #
    && cd /build \
    && git clone https://github.com/sfomuseum/runtimevar.git \    
    && cd runtimevar \
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/runtimevar cmd/runtimevar/main.go \
    #
    && cd /build \
    && git clone https://github.com/aaronland/go-aws-ecs.git \
    && cd go-aws-ecs \       	
    && go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/ecs-launch-task cmd/ecs-launch-task/main.go \
    #    
    && cd && rm -rf /build 
    
FROM alpine

RUN mkdir /usr/local/data

RUN apk update && apk upgrade \
    && apk add git ca-certificates jq curl

COPY --from=gotools /usr/local/bin/wof-list-repos /usr/bin
COPY --from=gotools /usr/local/bin/wof-clone-repos /usr/bin
COPY --from=gotools /usr/local/bin/wof-mysql-index /usr/bin
COPY --from=gotools /usr/local/bin/es2-whosonfirst-index /usr/bin
COPY --from=gotools /usr/local/bin/wof-opensearch-index /usr/bin
COPY --from=gotools /usr/local/bin/runtimevar /usr/bin
COPY --from=gotools /usr/local/bin/ecs-launch-task /usr/bin

COPY bin/index.sh /usr/local/bin/
COPY bin/index.sh.env /usr/local/bin/

COPY bin/update.sh /usr/local/bin/
COPY bin/update.sh.env /usr/local/bin/
