#!/bin/bash

pkg="libxsmm"
pkgopts=$@
cleanup=""

version=1.16.1
pfile=libxsmm-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/hfp/libxsmm/archive/${version}.tar.gz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log=$(realpath "log_${pkg}")

echo "Building ${pkg}..." >&2

# Make options to consider:
# AVX=2

rm -rf libxsmm-${version}
tar xzf ${src} \
    && cd libxsmm-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && make \
          CC="@CC@" \
          CXX="@CXX@" \
          FC="@FC@" \
          STATIC=0 \
          OMP=1 \
          -j @MAKEJ@ \
       >> ${log} 2>&1 \
    && make PREFIX="@AUX_PREFIX@" install >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
