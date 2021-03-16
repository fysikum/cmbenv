#!/bin/bash

pkg="libint"
pkgopts=$@
cleanup=""

# Note: we use libint's cp2k release

LMAX=5
version=v2.7.0-beta.5
release=cp2k-lmax-${LMAX}
pfile=libint-${version}-${release}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/cp2k/libint-cp2k/releases/download/${version}/libint-${version}-${release}.tgz ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="${src}"

log=$(realpath "log_${pkg}")

echo "Building ${pkg}..." >&2

###############################################################################

rm -rf libint-${version}-${release}
tar xzf ${src} \
    && cd libint-${version}-${release} \
    && cleanup="${cleanup} $(pwd)" \
    && mkdir -p build \
    && cd build \
    && cmake \
    -DCMAKE_C_COMPILER="@CC@" \
    -DCMAKE_CXX_COMPILER="@CXX@" \
    -DCMAKE_Fortran_COMPILER="@FC@" \
    -DCMAKE_C_FLAGS="@CFLAGS@" \
    -DCMAKE_CXX_FLAGS="@CXXFLAGS@" \
    -DCMAKE_Fortran_FLAGS="@FCFLAGS@" \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_INSTALL_PREFIX="@AUX_PREFIX@" \
    -DENABLE_FORTRAN=ON \
    -DCMAKE_MODULE_PATH=${EIGEN_DIR}/share/cmake/Modules \
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

###############################################################################
# Build options to consider:
#  --enable-fma
#    CFLAGS = "-O3 -mavx2 -mavx -msse2";
#    FFLAGS = "-O3 -mavx2 -mavx -msse2";

rm -rf libint-${version}
tar xzf ${src} \
    && cd libint-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && ./autogen.sh > ${log} 2>&1 \
    && CC="@CC@" CXX="@CXX@" FC="@FC@" \
    CFLAGS="@CFLAGS@" CXXFLAGS="@CXXFLAGS@" FCFLAGS="@FCFLAGS@" \
    LDFLAGS="@LDFLAGS@" \
    ./configure \
    --enable-eri=1 --enable-eri2=1 --enable-eri3=1 \
    --with-max-am=${LMAX} \
    --with-eri-max-am=${LMAX},$((LMAX-1)) \
    --with-eri2-max-am=$((LMAX+2)),$((LMAX+1)) \
    --with-eri3-max-am=$((LMAX+2)),$((LMAX+1)) \
    --with-opt-am=3 \
    --enable-generic-code --disable-unrolling \
    --with-libint-exportdir=libint-${version}-${release}
    --with-incdirs="-I${GMP_INC} -I${EIGEN_INC}" \
    --with-libdirs="-L${GMP_LIB}" \
    --with-boost="${BOOST_DIR}" \
    --prefix="@AUX_PREFIX@" >> ${log} 2>&1 \
    && make export >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
