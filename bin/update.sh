#!/bin/sh

PYTHON=`which python3`

WHOAMI=`${PYTHON} -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' $0`
FNAME=`basename $WHOAMI`
ROOT=`dirname $WHOAMI`

OS=`uname -s | tr '[:upper:]' '[:lower:]'`

BIN="/usr/bin"

# Pull in defaults from .env file
if [ -f ${ROOT}/${FNAME}.env ]
then
    source ${ROOT}/${FNAME}.env
fi

REPOS=`${BIN}/wof-list-repos -org whosonfirst-data -prefix whosonfirst-data -updated-since ${UPDATED_SINCE}`

for REPO in ${REPOS}
do

    echo "Invoke ${ECS_TASK} for ${REPO}

    ${BIN}/ecs-launch-task -dsn ${ECS_DSN} -task ${ECS_TASK} -container ${ECS_CONTAINER} -cluster ${ECS_CLUSTER} -launch-type FARGATE -public-ip ENABLED -security-group ${ECS_SECURITY_GROUP} -subnet ${ECS_SUBNET} ${ECS_COMMAND} ${REPO}
    
done


