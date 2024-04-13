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

```
$> cd update
$> make cli
go build -mod vendor -ldflags="-s -w" -o bin/update cmd/update/main.go
```

### update

_Note: This tool has been deprecated and will be removed shortly. You should use the more generic `wof-launch-task` command in the [whosonfirst/go-whosonfirst-aws](https://github.com/whosonfirst/go-whosonfirst-aws?tab=readme-ov-file#wof-launch-task) package instead._

Fetch the list of respostories updated since (n) and launch an ECS task for each one.

```
$> ./bin/update  -h
  -aws-session-uri string
    	A valid aaronland/go-aws-session URI string.
  -dryrun
    	Go through the motions but do not launch any indexing tasks.
  -ecs-cluster string
    	The name of your ECS cluster.
  -ecs-container string
    	The name of your ECS container.
  -ecs-launch-type string
    	A valid ECS launch type. (default "FARGATE")
  -ecs-platform-version string
    	A valid ECS platform version. (default "1.4.0")
  -ecs-public-ip string
    	A valid ECS public IP string. (default "ENABLED")
  -ecs-security-group value
    	A valid AWS security group to run your task under.
  -ecs-subnet value
    	One or more subnets to run your ECS task in.
  -ecs-task string
    	The name (and version) of your ECS task.
  -ecs-task-command string
    	 (default "/usr/local/bin/index.sh -R -r {repo}")
  -github-access-token-uri string
    	A valid gocloud.dev/runtimevar URI that dereferences to a GitHub API access token.
  -github-organization string
    	The GitHub organization to poll for recently updated repositories. (default "whosonfirst-data")
  -github-prefix value
    	Zero or more prefixes to filter repositories by (must match).
  -github-updated-since string
    	A valid ISO-8601 duration string. (default "PT24H")
  -mode string
    	Valid options are: cli, lambda (default "cli")
```

For example:

```
$> ./bin/update \
	-dryrun -aws-session-uri 'aws://?region={REGION}&credentials={CREDENTIALS}' \
	-ecs-container whosonfirst-data-indexing \
	-github-prefix whosonfirst-data \
	-github-updated-since P14D
	
2023/05/27 14:10:37 [dryrun]  (whosonfirst-data-indexing) /usr/local/bin/index.sh -R -r whosonfirst-data-admin-al
2023/05/27 14:10:37 [dryrun]  (whosonfirst-data-indexing) /usr/local/bin/index.sh -R -r whosonfirst-data-admin-as
2023/05/27 14:10:37 [dryrun]  (whosonfirst-data-indexing) /usr/local/bin/index.sh -R -r whosonfirst-data-admin-at
2023/05/27 14:10:37 [dryrun]  (whosonfirst-data-indexing) /usr/local/bin/index.sh -R -r whosonfirst-data-admin-be
2023/05/27 14:10:37 [dryrun]  (whosonfirst-data-indexing) /usr/local/bin/index.sh -R -r whosonfirst-data-admin-bg
2023/05/27 14:10:37 [dryrun]  (whosonfirst-data-indexing) /usr/local/bin/index.sh -R -r whosonfirst-data-admin-ch
2023/05/27 14:10:37 [dryrun]  (whosonfirst-data-indexing) /usr/local/bin/index.sh -R -r whosonfirst-data-admin-cy
... and so on
```

For details on the syntax and format of the `-aws-session-uri` flag consult the documentation for [aaronland/go-aws-session](https://github.com/aaronland/go-aws-session#credentials).

#### Lambda

```
$> make lambda
if test -f bootstrap; then rm -f bootstrap; fi
if test -f update.zip; then rm -f update.zip; fi
GOARCH=arm64 GOOS=linux go build -mod vendor -ldflags="-s -w" -tags lambda.norpc -o bootstrap cmd/update/main.go
zip update.zip bootstrap
  adding: bootstrap (deflated 75%)
rm -f bootstrap
```

Flags to the Lambda function are defined as environment variables. The names of environment variables are derived from the command line flag equivalents. The rules for mapping flags to environment variables are:

* Flag names are upper-cased.
* "-" symbols in flag names are replaced by "_".
* Environment variables are prefixed with "WHOSONFIRST_".

For example the `-github-updated-since` flag would be the `WHOSONFIRST_GITHUB_UPDATED_SINCE` environment variable.

## See also

* https://github.com/whosonfirst/go-whosonfirst-github
* https://github.com/aaronland/go-aws-ecs
* https://gocloud.dev/runtimevar
* https://github.com/sfomuseum/runtimevar
* https://github.com/aaronland/go-aws-session
