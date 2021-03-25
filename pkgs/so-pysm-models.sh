#!/bin/bash

pkg="so-pysm-models"
pkgopts=$@
cleanup=""

log=$(realpath "log_${pkg}")

echo "Building ${pkg}..." >&2

pip3 install https://github.com/simonsobs/so_pysm_models/archive/master.zip > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
