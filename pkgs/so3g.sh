#!/bin/bash

pkg="so3g"
pkgopts=$@
cleanup=""

rm -rf ${pkg}
repo=$( git clone https://github.com/simonsobs/${pkg}.git 1>&2; \
        /bin/ls ${pkg} 2>/dev/null )

if [ "x${repo}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${repo}"

echo "Building ${pkg}..." >&2

log=$(realpath "log_${pkg}")

cd ${pkg} \
    && mkdir -p build \
    && cd build \
    && cmake \
    -DCMAKE_C_COMPILER="@CC@" \
    -DCMAKE_CXX_COMPILER="@CXX@" \
    -DCMAKE_C_FLAGS="@CFLAGS@" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@" \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DPython_USE_STATIC_LIBS=FALSE \
    -DPython_EXECUTABLE:FILEPATH=$(which python3) \
    -DCMAKE_INSTALL_PREFIX="@AUX_PREFIX@" \
    -DCMAKE_PREFIX_PATH="@AUX_PREFIX@/spt3g/build" \
    .. >> ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
