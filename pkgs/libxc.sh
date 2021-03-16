#!/bin/bash

pkg="libxc"
pkgopts=$@
cleanup=""

version=4.3.4
pfile=libxc-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://gitlab.com/libxc/libxc/-/archive/${version}/libxc-${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log=$(realpath "log_${pkg}")

echo "Building ${pkg}..." >&2

rm -rf libxc-${version}
tar xzf ${src} \
    && cd libxc-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && patch -p1 < "@TOP_DIR@/pkgs/patch_libxc" > ${log} 2>&1 \
    && autoreconf -i >> ${log} 2>&1 \
    && CC="@CC@" CXX="@CXX@" FC="@FC@" \
    CFLAGS="@CFLAGS@" CXXFLAGS="@CXXFLAGS@" FCFLAGS="@FCFLAGS@" \
    LDFLAGS="@LDFLAGS@" \
    ./configure \
    --enable-shared \
    --prefix="@AUX_PREFIX@" >> ${log} 2>&1 \
    && make -j @MAKEJ@ >> ${log} 2>&1 \
    && make install >> ${log} 2>&1

#   && make check >> ${log} 2>&1 \

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
