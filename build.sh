#!/bin/bash

# check args
if [ "$#" -lt 2 ]; then
	echo "usage: $0 <dm_bin_path> <dm_install_config>"
    exit 1
fi

# dm bin file and install config
DM_BIN=$1
DM_INSTALL_CONFIG=$2

shift 2

# build Docker image
docker build --build-arg DM_BIN=${DM_BIN} --build-arg DM_INSTALL_CONFIG=${DM_INSTALL_CONFIG} "$@" .

