umask 0022

# Unload conflicting modules: 
module -q unload $(module -t list | awk -F/ '$1 ~ "^openmpi*|^gnu*|^nix*" {print $1}' )

# Usefull packages:
module -q load prun 
module -q load autotools
module -q load cmake

# Required packages (some of them pinned):
module -q load git
module -q load gmp eigen
module -q load gnu8/8.3.0
module -q load gsl/2.6
module -q load openblas/0.3.12
module -q load openmpi3/3.1.4
module -q load fftw/3.3.8
module -q load boost/1.71.0
module -q load scalapack/2.0.2

module list
