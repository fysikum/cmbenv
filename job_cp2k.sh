#!/bin/bash -l

###############################################################################
# job_cp2k.sh -- installs the cp2k environment.
# If submitted as a Slurm job, it wipes out the earlier installation.
###############################################################################

#SBATCH -J build-cp2k
#SBATCH -p fermi
#SBATCH -N 1
#SBATCH -t 03:00:00

###############################################################################
# Configuration
###############################################################################

module=cp2k
version=8.1-plain
#version=8.1-avx
#version=8.1-avx2

prefix="/opt/ohpc/pub/sw/${module}/${version}"
module_dir="/opt/ohpc/pub/moduledeps/gnu8-openmpi3/${module}"

compiled_prefix="${prefix}"
python_prefix="${prefix}/python"
#module_dir="${prefix}/modulefiles/${module}"

###############################################################################

umask 0022

if [ -n "$SLURM_JOB_ID" ];  then
    script=$(scontrol show job $SLURM_JOB_ID | awk -F= '/Command=/{print $2}')
    # Handle interactive cases ( e.g. srun --pty bash)
    if [ ".${script:0:1}" != "./" ]; then 
        script=$(realpath $0)
    fi
else
    script=$(realpath $0)
fi

installer_dir=$(dirname ${script})

if [ -n "$SLURM_JOB_ID" ];  then
  build_dir="$(pwd)/build_${module}-${version}"
else
  build_dir="$(pwd)/build_${module}-${version}"
fi

###############################################################################

echo "# Destination: ${prefix}"
echo "# Build dir: ${build_dir}"
echo "# Module dir: ${module_dir}"
echo "# Installer dir: ${installer_dir}"

if [ -n "$SLURM_JOB_NAME" ]; then
  echo "# Slurm job: $SLURM_JOB_NAME"
  # cat $0
fi

###############################################################################

echo
echo "$(date +'%Y-%m-%d %H:%M:%S'): ${script} started"
echo

###############################################################################
# Clean up
###############################################################################

if false; then
if [ ".$1" == ".clean" -o -n "$SLURM_JOB_ID" ]; then
  echo "Removing ${build_dir}..."
  rm -rf ${build_dir}
  if [ -n "$SLURM_JOB_ID" ]; then
    echo "Removing ${prefix}..."
    rm -rf ${prefix}
  elif [ -d "${prefix}" ]; then
    read -p "Do you want to delete ${prefix}? (y/n)? " choice
    if [[ "${choice}" =~ ^[Yy]$ ]]
    then
      echo "Removing ${prefix}..."
      rm -rf ${prefix}
    fi
  fi
fi
fi

###############################################################################
# Create the installation scripts
###############################################################################

echo "Creating install_${module}.sh..."

rm -rf install_${module}*

COMPILED_PREFIX="${compiled_prefix}" \
PYTHON_PREFIX="${pyhon_prefix}" \
MODULE_DIR="${module_dir}" \
  ./cmbenv -c "${module}" -p "${prefix}" -v "${version}"

###############################################################################
# Build all the packages in the environment
###############################################################################

echo "Building the environment ${module}..."

mkdir -p "${build_dir}" || exit 1
cd "${build_dir}" || exit 1

if [ -n "$SLURM_JOB_ID" ]; then
    "${installer_dir}/install_${module}.sh" || exit 1
else
    "${installer_dir}/install_${module}.sh" >log 2>&1 || exit 1
fi

###############################################################################
echo
echo "$(date +'%Y-%m-%d %H:%M:%S'): ${script} completed"
echo
###############################################################################
