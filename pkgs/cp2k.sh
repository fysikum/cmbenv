#!/bin/bash

pkg="cp2k"
pkgopts=$@
cleanup=""

# Note: Use a bz2 variant which has 'git clone --recursive'
# with all git submodules included (do not use a tar.gz source code archive!)

version=8.1
pfile=cp2k-${version}.tar.gz
src=$(eval "@TOP_DIR@/tools/fetch_check.sh" https://github.com/cp2k/cp2k/releases/download/v8.1.0/cp2k-${version}.tar.bz2  ${pfile})

if [ "x${src}" = "x" ]; then
    echo "Failed to fetch ${pkg}" >&2
    exit 1
fi
cleanup="$src}"

log=$(realpath "log_${pkg}") 

echo "Building ${pkg}..." >&2

arch="Linux-x86-64-gfortran"
flavor="psmp"

# For the build options see
# https://github.com/cp2k/cp2k/blob/master/INSTALL.md

cat > cp2k_${arch}.${flavor} <<EOF
CC          = mpicc
FC          = mpif90
LD          = mpif90
AR          = ar -r

CFLAGS      = -O2 -fopenmp -g -mtune=native

DFLAGS      = -D__FFTW3
DFLAGS     += -D__LIBINT
DFLAGS     += -D__LIBXC
DFLAGS     += -D__LIBXSMM
DFLAGS     += -D__MPI_VERSION=3
DFLAGS     += -D__SPGLIB
DFLAGS     += -D__parallel
DFLAGS     += -D__SCALAPACK
DFLAGS     += -D__F2008
DFLAGS     += -D__MAX_CONTR=4

FCFLAGS     = \$(CFLAGS) \$(DFLAGS)
FCFLAGS    += -O2 -fopenmp
FCFLAGS    += -ffree-form
FCFLAGS    += -ffree-line-length-none
FCFLAGS    += -ftree-vectorize
FCFLAGS    += -funroll-loops
FCFLAGS    += -std=f2008
FCFLAGS    += -I@AUX_PREFIX@/include
FCFLAGS    += -I${FFTW_INC}
FCFLAGS    += -I${OPENBLAS_INC}

LIBS        = -lfftw3 -lfftw3_threads -lscalapack -lopenblas
LIBS       += -lxcf03 -lxc 
LIBS       += -lxsmmf -lxsmm -ldl 
LIBS       += -lsymspg
LIBS       += -lint2 
LIBS       += -lstdc++ -fopenmp

LDFLAGS     = \$(FCFLAGS) \$(LIBS)
LDFLAGS    += -L@AUX_PREFIX@/lib
LDFLAGS    += -L${FFTW_LIB}
LDFLAGS    += -L${OPENBLAS_LIB}
LDFLAGS    += -L${SCALAPACK_LIB}
EOF

rm -rf cp2k-${version}
tar xjf ${src} \
    && cd cp2k-${version} \
    && cleanup="${cleanup} $(pwd)" \
    && mv -f ../cp2k_${arch}.${flavor} arch/${arch}.${flavor} \
    && make -j @MAKEJ@ ARCH=${arch} VERSION=${flavor} >> ${log} 2>&1 \
    && rsync -av "exe/${arch}/" "@AUX_PREFIX@/bin/" >> ${log} 2>&1

#   && make -j @MAKEJ@ ARCH=${arch} VERSION=${flavor} test >> ${log} 2>&1

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
