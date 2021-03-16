#!/bin/bash

pkg="spglib"
pkgopts=$@
cleanup=""

version=1.16.1
pfile=spglib-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/spglib/spglib/archive/v${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log=$(realpath "log_${pkg}")

echo "Building ${pkg}..." >&2

# Make options to consider:
# AVX=2

rm -rf spglib-${version}
tar xzf ${src} \
    && cd spglib-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && mkdir -p build \
    && cd build \
    && cmake \
    -DCMAKE_C_COMPILER="@CC@" \
    -DCMAKE_CXX_COMPILER="@CXX@" \
    -DCMAKE_C_FLAGS="@CFLAGS@" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@" \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_INSTALL_PREFIX="@AUX_PREFIX@" \
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
