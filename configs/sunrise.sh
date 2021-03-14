# Unload conflicting modules: 
module -q unload $(module -t list | awk -F/ '$1 ~ "^openmpi*|^gnu*|^nix*" {print $1}' )

# Usefull packages:
module -q load prun 
module -q load autotools
module -q load cmake

# Required packages (some of them pinned):
module -q load git               # to clone repositories on the compute nodes
module -q load gnu8/8.3.0        # our mpich is compiled using this
module -q load mpich/3.4.1       # note: the conda mpich is 3.4.1 

# Export some required libraries
export LZMA_LIBRARY_PATH=/cfs/home/cmbenv/@VERSION@/cmbenv_python/lib
export LZMA_INCLUDE=/cfs/home/cmbenv/@VERSION@/cmbenv_python/include

module list
