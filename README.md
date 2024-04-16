# whosonfirst-data-indexing

Tools for indexing `whosonfirst-data` repositories using containers.

## Docker

Dockerfile to build a container used to index a specific `whosonfirst-data` repository using the `index.sh` tool. This tool is configured by the use of a `index.sh.env` file. Both files are expected to be found in the `bin` folder of this repository and are copied to the final container.

### index.sh

Index one or more Who's On First repositories in to one or more target environments (databases).

#### index.sh.env

_TBW. For now consult [bin/update.sh.env.example](bin/index.sh.env.example)_

### update.sh

Determine all the `whosonfirst-data` repositories that have been updated since a specific time and then, for each repository, launch an ECS task to index that repository in zero or more targets using the `updated.sh` tool. This tool is configured by the use of a `update.sh.env` file. Both files are expected to be found in the `bin` folder of this repository and are copied to the final container.

_Note that equivalent functionality is provided by the [update/cmd/update](update/cmd/update) tool described below which can either be run from the command line or as a Lambda function. This is assumed to be easier and/or cheaper than spinning up entire ECS instances to check for changes and invoking subsequent ECS tasks._

#### update.sh.env

_TBW. For now consult [bin/update.sh.env.example](bin/update.sh.env.example)_

### *.env files

These tools were originally written to expect CLI options. Most of these flags have been removed.

Basically, there are enough different flags and enough details that shouldn't be kept in source control that the CLI flag approach has become a burden. For example all the details used to invoke an ECS task (container name, cluster name, security group, subnet(s), etc.)

Instead, we are using an alternative approach to pull in `.env` files with defaults at runtime. These files are explicitly excluded from source control. For example:

```
WHOAMI=`realpath $0`
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

## Command line (and Lambda) tools

### update

_Note: This tool has been deprecated and has been removed. You should use the more generic `wof-launch-task` command in the [whosonfirst/go-whosonfirst-aws](https://github.com/whosonfirst/go-whosonfirst-aws?tab=readme-ov-file#wof-launch-task) package instead._

## See also

* https://github.com/whosonfirst/go-whosonfirst-github
* https://github.com/whosonfirst/go-whosonfirst-aws
* https://gocloud.dev/runtimevar
* https://github.com/sfomuseum/runtimevar
* https://github.com/aaronland/go-aws-session
