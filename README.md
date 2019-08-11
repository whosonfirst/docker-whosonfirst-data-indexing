# docker-whosonfirst-data-index

WORK IN PROGRESS

## AWS

### Roles

You will need to make sure you have a role with the following (default) AWS policies:

* `AmazonECSTaskExecutionRolePolicy`

### Security groups

Create a new `whosonfirst-data-indexing` security and disallow _all_ inbound ports.

## Lambda

### webhookd-lambda-task

#### Environment variables

| Key | Value |
| --- | --- |
| WEBHOOKD_MODE | `lambda` |
| WEBHOOKD_COMMAND | `/usr/local/bin/wof-test-index %s` |
| WEBHOOKD_ECS_CLUSTER | `whosonfirst` |
| WEBHOOKD_ECS_CONTAINER | `whosonfirst-data-indexing` |
| WEBHOOKD_ECS_DSN | `credentials=iam: region={AWS_REGION}` |
| WEBHOOKD_ECS_SECURITY_GROUP | `whosonfirst-data-indexing` |
| WEBHOOKD_ECS_SUBNET | `{AWS_SUBNET1},{AWS_SUBNET2}...` |
| WEBHOOKD_ECS_TASK | `whosonfirst-data-indexing:{N}` |
