#!/bin/bash

pkg="pixell"
pkgopts=$@
cleanup=""

rm -rf ${pkg}
repo=$( git clone https://github.com/simonsobs/${pkg}.git 1>&2; \
        /bin/ls ${pkg} 2>/dev/null )

if [ "x${repo}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${pkg}"

log=$(realpath "log_${pkg}")

echo "Building ${pkg}..." >&2

cd ${pkg} \
    && pip3 install pixell > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
