#!/bin/bash

# check args
if [ "$#" -lt 2 ]; then
	echo "usage: $0 <dm_install_config> <dm_bin_path> [DOCKER_BUILD_OPTIONS]"
    exit 1
fi

# dm bin file and install config
DM_INSTALL_CONFIG=$1
DM_BIN=$2

shift 2

# build Docker image
docker build -t dm8 --build-arg DM_BIN=${DM_BIN} --build-arg DM_INSTALL_CONFIG=${DM_INSTALL_CONFIG} "$@" .

