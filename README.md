# docker-whosonfirst-data-index

Tools for indexing `whosonfirst-data` repositories using containers.

## Docker

### Dockerfile.updates

Dockerfile to build a container used to determine all the `whosonfirst-data` repositories that have been updated since a specific time and then, for each repository, launch an ECS task to index that repository in zero or more targets using the `updated.sh` tool. This tool is configured by the use of a `update.sh.env` file. Both files are expected to be found in the `bin` folder of this repository and are copied to the final container.

#### update.sh.env

_TBW. For now consult [bin/update.sh.env.example](bin/update.sh.env.example)_

#### See also

* https://github.com/whosonfirst/go-whosonfirst-github
* https://github.com/aaronland/go-aws-ecs

### Dockerfile.index

Dockerfile to build a container used to index a specific `whosonfirst-data` repository using the `index.sh` tool. This tool is configured by the use of a `index.sh.env` file. Both files are expected to be found in the `bin` folder of this repository and are copied to the final container.

#### index.sh.env

_TBW. For now consult [bin/update.sh.env.example](bin/index.sh.env.example)_

#### See also

* https://github.com/sfomuseum/go-whosonfirst-elasticsearch
* https://github.com/whosonfirst/go-whosonfirst-s3
* https://github.com/whosonfirst/go-whosonfirst-mysql

### *.env files

These tools were originally written to expect CLI options. Most of these flags have been removed.

Basically, there are enough different flags and enough details that shouldn't be kept in source control that the CLI flag approach has become a burden. For example all the details used to invoke an ECS task (container name, cluster name, security group, subnet(s), etc.)

Instead, we are using an alternative approach to pull in `.env` files with defaults at runtime. These files are explicitly excluded from source control. For example:

```
PYTHON=`which python`

WHOAMI=`${PYTHON} -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`
FNAME=`basename $WHOAMI`

# Pull in defaults from .env file
if [ -f ${BIN}/${FNAME}.env ]
then
    source ${BIN}/${FNAME}.env
fi
```

Because these tools are cascading (as in one invokes another) the convention is to use the `VARIABLE="${VARIABLE:=default_value}"` syntax. For example:

```
ECS_CONTAINER="${ECS_CONTAINER:=whosonfirst-data-indexing}"
```

This _should_ help to make the individual tools easier to maintain since it removes the need for a lot of boilerplate code to assign CLI variables to the next process in the chain. That's the thinking anyway. In practice things might still change.

Note that anything credential-related (for example a GitHub API token) in a `.env` file is defined as a `gocloud.dev/runtimevar` URI. This prevents the _need_ to include sensitive data in these configuration files or the containers that invoke them. If you need to include sensitive data inline (or just don't care) you can always use the `constant://` URI scheme. For example `GITHUB_TOKEN="constant://?val=s33kret"`.

* https://gocloud.dev/runtimevar
* https://github.com/sfomuseum/runtimevar