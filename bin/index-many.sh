#!/bin/sh

PYTHON=`which python`

WHOAMI=`${PYTHON} -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`
BIN=`dirname $WHOAMI`
FNAME=`basename $WHOAMI`
ROOT=`dirname $BIN`
UTIL="${ROOT}/util"

OS=`uname -s | tr '[:upper:]' '[:lower:]'`

# Pull in defaults from .env file
if [ -f ${BIN}/${FNAME}.env ]
then
    source ${BIN}/${FNAME}.env
fi

# TO DO: check for export LOCAL, REFRESH and DO_NOT_CLONE flags

while getopts "R:hnN" opt; do
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
	R)
	    REPOS=$OPTARG
	    ;;
	:   )
	    echo "Unrecognized flag"
	    ;;
    esac
done

if [ "${USAGE}" = "1" ]
then
    echo "usage: index-many.sh"
    echo "options:"
    echo "-h (help) Print this message."
    echo "-n (dryrun) Go through the motions but don't index anything."
    echo "-N (dryrun-many) Invoke the 'index-repo.sh' script for each all repos but do so in -dryrun mode so nothing will actually be indexed."
    echo "-R (repo(s) One or more specific repository names to index."
    exit 0
fi

if [ "${ALL}" = "1" ]
then

    echo ${UTIL}/${OS}/wof-list-repos -org whosonfirst-data -prefix whosonfirst-data -token ${TOKEN}
    REPOS=`${UTIL}/${OS}/wof-list-repos -org whosonfirst-data -prefix whosonfirst-data -token ${TOKEN}`
fi

for REPO in $REPOS
do

    COMMAND="${BIN}/index-repo.sh -r ${REPO}"

    if [ "${DRYRUN_NEXT}" = "1" ]
    then
	COMMAND="${COMMAND} -N"
    fi

    if [ "${DRYRUN}" = "1" ]
    then
       echo ${COMMAND}
       continue
    fi
    
    ${COMMAND}
done
