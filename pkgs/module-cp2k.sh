#!/bin/bash

pkg=module-cp2k

log=$(realpath "log_${pkg}") 

echo "Building ${pkg}..." >&2
echo "Creating @MODULE_DIR@/@VERSION@..." >&2

mkdir -p "@MODULE_DIR@" || exit 1

cat > "@MODULE_DIR@/@VERSION@" <<'EOF'
#%Module###<-magic cookie ####################################################

set version @VERSION@

proc ModulesHelp { } {
    puts stderr " "
    puts stderr "This module loads CP2K which is a quantum chemistry and "
    puts stderr "solid state physics software package."
    puts stderr "\nVersion @VERSION@\n"
}

module-whatis "Name: cp2k"
module-whatis "Version: @VERSION@"
module-whatis "Description: quantum chemistry and solid state physics software"

if [ module-info mode load ] {
  module load gsl/2.6
  module load openblas/0.3.12
  module load fftw/3.3.8
  module load boost/1.71.0
  module load scalapack/2.0.2
}
prepend-path    PATH             @AUX_PREFIX@/bin
prepend-path    LD_LIBRARY_PATH  @AUX_PREFIX@/lib64
prepend-path    INCLUDE          @AUX_PREFIX@/include
prepend-path    MANPATH          @AUX_PREFIX@/share/man

setenv          CP2K_DIR        @AUX_PREFIX@
setenv          CP2K_BIN        @AUX_PREFIX@/bin
setenv          CP2K_INC        @AUX_PREFIX@/include
setenv          CP2K_LIB        @AUX_PREFIX@/lib64
setenv          CP2K_DATA_DIR   @AUX_PREFIX@/data
EOF

if [ $? -ne 0 ]; then
    echo "Failed to build ${pkg}" >&2
    exit 1
fi

echo "Finished building ${pkg}" >&2
echo "${cleanup}"
exit 0
