#!/bin/sh
# -*-sh-*-

PYTHON=`which python3`

WHOAMI=`${PYTHON} -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' $0`
FNAME=`basename $WHOAMI`
ROOT=`dirname $WHOAMI`

OS=`uname -s | tr '[:upper:]' '[:lower:]'`

GIT=`which git`
BIN="/usr/bin"

# Pull in defaults from .env file
if [ -f ${ROOT}/${FNAME}.env ]
then
    source ${ROOT}/${FNAME}.env
fi

if [ "${INDEX_ALL}" = "1" ]
then
    INDEX_MYSQL=1
    INDEX_ELASTICSEARCH=1
    INDEX_S3=1    
fi

DRYRUN=""
CUSTOM_REPOS=""

LOCAL="${LOCAL:=}"
REFRESH="${REFRESH:=}"
DO_NOT_CLONE="${DO_NOT_CLONE:=}"

while getopts "r:hnLRX" opt; do
    case "$opt" in
	h )
	    USAGE=1
	    ;;	
	n )
	    DRYRUN=1
	    ;;
	r )
	    REPOS_CUSTOM=$OPTARG
	    ;;
	L )
	    LOCAL=1
	    ;;
	R )
	    REFRESH=1
	    ;;
	X )
	    DO_NOT_CLONE=1
	    ;;
	: )
	    echo "Unreconized flag"
	    ;;
    esac
done

if [ "${USAGE}" = "1" ]
then
    echo "usage: ./index.sh -options"
    echo "options:"
    echo "-n (dry-run) Go through the motions but do not indexing anything."
    echo "-r A list of one or more specific repositories to index."
    echo "-L (local) Assume local indexing (like on your own machine, from this repo)."
    echo "-R (refresh) Do a full refresh when indexing a repo rather than only the most recent commits.)"
    echo "-X (do not clone) Assume repo already exists in local workdir (defined by the WORKDIR environment variable).)"
    exit 0
fi

# NOTE: local builds of utilities don't exist yet.
															
if [ "${LOCAL}" = "1" ] 
then
    PYTHON=`which python`
    WHOAMI=`${PYTHON} -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`
    BIN=`dirname $WHOAMI`
    ROOT=`dirname ${BIN}`
    UTIL="${ROOT}/util"
    BIN="${UTIL}/${OS}"

    # TODO: Ensure BIN exists

    echo "Local indexing is specified, disabling S3 indexing"
    INDEX_S3=""
fi

if [ "${INDEX_ELASTICSEARCH}" = "1" ]
then

    if [ "${ES_INDEX}" = "" ]
    then
	echo "Missing or empty -i Elasticsearch index flag."
	exit 1
    fi

    ES_TEST=`curl -v -s ${ES_HOST}/_aliases`
    echo "ES TEST ${ES_TEST}"
fi

if [ "${INDEX_MYSQL}" = "1" ]
then
    
    MYSQL_CREDS=`${BIN}/runtimevar "${MYSQL_CREDENTIALS}"`
    MYSQL_DSN="${MYSQL_CREDS}@tcp("${MYSQL_HOST}")/${MYSQL_DATABASE}?maxAllowedPacket=0"
    
    MYSQL_USER=`echo ${MYSQL_CREDS} | awk -F ':' '{ print $1 }'`
    
    MYSQL_DSN_DEBUG="${MYSQL_USER}:...@tcp("${MYSQL_HOST}")/${MYSQL_DATABASE}?maxAllowedPacket=0"

fi

LIST_REPOS="${BIN}/wof-list-repos"
S3_SYNC="${BIN}/wof-s3-sync"


MYSQL_INDEX="${BIN}/wof-mysql-index"

# Note the "es2-" which is necessary until we migrate the Spelunker over to ES 7.x
ES_INDEX_TOOL="${BIN}/es2-whosonfirst-index"

# ensure tools exist here...

REPOS=""

if [ "${GITHUB_TOKEN}" != "" ]
then
    GITHUB_TOKEN=`${BIN}/runtimevar '${GITHUB_TOKEN}'`
fi

if [ "${REPOS_CUSTOM}" != "" ]
then   
    REPOS=${REPOS_CUSTOM}
else
    REPOS=`${LIST_REPOS} -org ${GITHUB_ORG} -prefix whosonfirst-data  -token ${GITHUB_TOKEN}`
fi

if [ "${REPOS}" = "" ]
then
    echo "Nothing to index"
    exit 1
fi

for REPO_NAME in ${REPOS}
do

    if [ "${REPO_NAME}" = "whosonfirst-data" ]
    then
	continue
    fi

    echo "INDEX ${REPO_NAME}"
    REPO_PATH="${WORKDIR}/${REPO_NAME}"

    if [ "${DO_NOT_CLONE}" = "1" ]
    then
	echo "Do not clone flag enabled. Assuming that ${REPO_PATH} already exists."
    else 
	echo "${GIT} clone https://github.com/${GITHUB_ORG}/${REPO_NAME}.git ${REPO_PATH}"

	if [ "${DRYRUN}" = "" ]
	then
	    ${GIT} clone https://github.com/${GITHUB_ORG}/${REPO_NAME}.git ${REPO_PATH}
	fi
    fi

    if [ "${DRYRUN}" = "" ]
    then
	cd ${REPO_PATH}
    fi

    MODE="filelist"
    INDEX="${REPO_PATH}/index.txt"

    # as of this writing most (all...) of the time savings doing it this way is targeted at
    # flights and because of the way we are exporting them (flights) – which involves using a
    # two-pass export, first in go and then again using the more-complete python exporter 
    # basically a pure-go port of the py-mapzen-whosonfirst-export code can't happen soon
    # enough but until then all of the effeciencies here depend on exporting flights with
    # something like this (where utils/python/export.py is bundled with the flights repo):
    #
    # git status --porcelain --untracked-files=all | egrep '.geojson' | awk '{ print $$2 }' > new.txt
    # python utils/python/export.py -r . -f new.txt
    # rm new.txt
    #
    # (20190123/thisisaaronland)
    
    if [ "${REFRESH}" = "1" ]
    then
	MODE="repo"
	INDEX="${REPO_PATH}"
    else

	echo "${GIT} log --name-only --pretty=format:'' HEAD^..HEAD > ${INDEX}"

	if [ "${DRYRUN}" = "" ]
	then
	    ${GIT} log --name-only --pretty=format:'' HEAD^..HEAD > ${INDEX}
	fi
    fi
    
    echo "index ${REPO_PATH} in '${MODE}' mode, reading from ${INDEX}"

    # S3
    
    if [ "${INDEX_S3}" = "1" ]
    then	
	
	echo ${S3_SYNC} -verbose -dsn "${S3_DSN}" -mode ${MODE} ${INDEX}
	
	if [ "${DRYRUN}" = "" ]
	then
	    ${S3_SYNC} -verbose -dsn "${S3_DSN}" -mode ${MODE} ${INDEX}
	fi
	
    fi

    # Elasticsearch
    
    if [ "${INDEX_ELASTICSEARCH}" = "1" ]
    then
	
	echo ${ES_INDEX_TOOL} -elasticsearch-endpoint ${ES_HOST} -elasticsearch-index ${ES_INDEX} -index-spelunker-v1 -iterator-uri ${MODE}:// ${INDEX}
    
	if [ "${DRYRUN}" = "" ]
	then
	    ${ES_INDEX_TOOL} -elasticsearch-endpoint ${ES_HOST} -elasticsearch-index ${ES_INDEX} -index-spelunker-v1 -iterator-uri ${MODE}:// ${INDEX}
	fi
    fi

    if [ "${DRYRUN}" = "" ]
    then
    
	if [ "${REFRESH}" != "1" ]
	then
	    rm ${INDEX}
	fi
    fi
    
    # MySQL
    
    if [ "${INDEX_MYSQL}" = "1" ]
    then
	
	echo ${MYSQL_INDEX} -dsn ${MYSQL_DSN_DEBUG} -all -mode ${MODE} ${INDEX}
	
	if [ "${DRYRUN}" = "" ]
	then	
	    ${MYSQL_INDEX} -dsn ${MYSQL_DSN} -all -mode ${MODE}:// ${INDEX}
	fi
	
    fi
    
    if [ "${DRYRUN}" = "" ]
    then

	if [ "${DO_NOT_CLONE}" = "" ]
	then
	    cd -
	    rm -rf ${REPO_PATH}
	fi

    fi

done

