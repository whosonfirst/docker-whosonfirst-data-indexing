# docker-whosonfirst-data-index

Tools for indexing `whosonfirst-data` repositories using containers.

## Docker

### Dockerfile.index

Dockerfile to build a container used to index a specific `whosonfirst-data` repository using the `index.sh` tool. This tool is configured by the use of a `index.sh.env` file. Both files are expected to be found in the `bin` folder of this repository and are copied to the final container.

* https://github.com/sfomuseum/go-whosonfirst-elasticsearch
* https://github.com/whosonfirst/go-whosonfirst-s3
* https://github.com/whosonfirst/go-whosonfirst-mysql

### Dockerfile.updates

Dockerfile to build a container used to determine all the `whosonfirst-data` repositories that have been updated since a specific time and then, for each repository, launch an ECS task to index that repository in zero or more targets using the `updated.sh` tool. This tool is configured by the use of a `update.sh.env` file. Both files are expected to be found in the `bin` folder of this repository and are copied to the final container.

* https://github.com/whosonfirst/go-whosonfirst-github
* https://github.com/aaronland/go-aws-ecs

### *.env files

Note that anything credential-related (for example a GitHub API token) in a `.env` file is defined as a `gocloud.dev/runtimevar` URI. This prevents the _need_ to include sensitive data in these configuration files or the containers that invoke them. If you need to include sensitive data inline (or just don't care) you can always use the `constant://` URI scheme. For example `GITHUB_TOKEN="constant://?val=s33kret"`.

* https://gocloud.dev/runtimevar
* https://github.com/sfomuseum/runtimevar