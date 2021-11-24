#!/bin/sh

PYTHON=`which python`

WHOAMI=`${PYTHON} -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`
FNAME=`basename $WHOAMI`
BIN=`dirname $WHOAMI`
ROOT=`dirname $BIN`
UTIL="${ROOT}/util"

OS=`uname -s | tr '[:upper:]' '[:lower:]'`

# Pull in defaults from .env file
if [ -f ${BIN}/${FNAME}.env ]
then
    source ${BIN}/${FNAME}.env
fi

# TO DO: check for export LOCAL, REFRESH and DO_NOT_CLONE flags

while getopts "r:hnN" opt; do
    case "$opt" in
        h) 
	    USAGE=1
	    ;;
	n)
	    DRYRUN=1
	    ;;
	N)
	    DRYRUN=""
	    DRYRUN_NEXT=1
	    ;;
	r)
	    REPO=$OPTARG
	    ;;
	:   )
	    echo "Unrecognized flags"
	    ;;
    esac
done

if [ "${USAGE}" = "1" ]
then
    echo "usage: index-repo.sh"
    echo "options:"
    echo "-n (dryrun) Go through the motions but don't index anything."
    echo "-N (dryrun-many) Invoke the 'index.sh' tool but do so in -dryrun mode so nothing will actually be indexed."
    echo "-r (repo) A valid GitHub repository name."
    exit 0
fi

if [ "${REPO}" = "" ]
then
    echo "Missing or empty -r (repo) flag"
    exit 1
fi

# See this...
COMMAND="/usr/local/bin/index.sh -r ${REPO}"

if [ "${DRYRUN_NEXT}" = "1" ]
then
    COMMAND="${COMMAND} -n"
fi

# Hello, ECS

if [ "${DRYRUN}" = "1" ]
then

	echo ${UTIL}/${OS}/ecs-launch-task -container ${ECS_CONTAINER} -cluster ${ECS_CLUSTER} -task ${ECS_TASK}:${TASK_VERSION} -launch-type FARGATE -public-ip ENABLED ${ECS_SUBNETS} -security-group ${ECS_SECURITY_GROUP} -dsn '${ECS_DSN}' ${COMMAND}
	exit 0
fi   

${UTIL}/${OS}/ecs-launch-task -container ${ECS_CONTAINER} -cluster ${ECS_CLUSTER} -task ${ECS_TASK}:${TASK_VERSION} -launch-type FARGATE -public-ip ENABLED ${ECS_SUBNETS} -security-group ${ECS_SECURITY_GROUP} -dsn '${ECS_DSN}' ${COMMAND}
	
