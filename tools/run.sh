#!/bin/bash

set -eo pipefail

usage() {
    echo -en "\nUsage: ${0} [ --build ]\n"
    echo -en "Options: \n"
    echo -en "  --help      What you see here\n"
    echo -en "  --debug     Bash set -x\n"
    echo -en "  --setup     Sets up .env file, you may need to edit it\n"
    echo -en "  --clean     Cleans up .env file and containers and volumes\n"
    echo -en "  --build     Optional argument, runs docker-compose up --build --detach\n"
    exit 0
}

while test $# -gt 0
do
  case "$1" in
    --debug)
        set -x
    ;;
    --help)
        usage
    ;;
    --setup)
        SETUP_ARG=1
	;;
    --clean)
        CLEAN_ARG=1
	;;
    --build)
    	BUILD_ARG=1
    ;;
  esac
  shift
done


# Remove env file to get a clean env
if [ -n "${CLEAN_ARG}" ] && [ -f .env ]; then
    echo "Removing old .env file"
    rm -f .env
fi

if [ -n "${CLEAN_ARG}" ]; then
    echo "Cleaning environment"
    docker-compose down --remove-orphans --volumes --rmi local
fi

if [ -n "${SETUP_ARG}" ]; then
    echo "Setting up environment"
    echo "Generating .env file"
    cat << EOF > .env
ENVIRONMENT=local
MYSQL_HOST=db
MYSQL_USER=admin
MYSQL_PASSWORD=$(openssl rand -base64 64 | tr -d '+/\n=')
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 64 | tr -d '+/\n=')
MYSQL_DATABASE=wiki
EOF
fi

if [ -n "${BUILD_ARG}" ]; then
    echo "Running build"
    docker-compose up --build --detach
fi
