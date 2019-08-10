# docker-whosonfirst-data-index

WORK IN PROGRESS

## AWS

### Roles

You will need to make sure you have a role with the following (default) AWS policies:

* `AmazonECSTaskExecutionRolePolicy`

### Security groups

Create a new `whosonfirst-data-indexing` security and disallow _all_ inbound ports.