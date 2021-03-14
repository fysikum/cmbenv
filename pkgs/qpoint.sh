#!/bin/bash

pkg="qpoint"
pkgopts=$@
cleanup=""

rm -rf ${pkg}
repo=$( git clone https://github.com/arahlin/${pkg}.git 1>&2; \
        /bin/ls ${pkg} 2>/dev/null )

if [ "x${repo}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${pkg}"

log=$(realpath "log_${pkg}")

echo "Building ${pkg}..." >&2

cd ${pkg} \
    && python3 setup.py install > ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
