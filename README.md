# cmbenv for the CoPS group at Fysikum

This repository is a fork of https://github.com/hpc4cmb/cmbenv.
It adds the following functionality:

- a configuration for the Sunrise cluster at Fysikum. In this version, `TOAST` is 
  cloned by git and some additional packages are installed: 
  `qpoint`, `pixell`, `sotodlib`, `so-pysm-models`, and `so3g`.

- Ubuntu based Docker image compatible with the Sunrise configuration

- a configuration to build the chemical package `cp2k`

Bellow are the instructions how to build the CoPS Docker image and use it, 
e.g., on a laptop.

## Building cmbenv CoPS Docker image

First, clone the repository, then generate a Dockerfile and 
build the derived Docker image (here tagged `simonsobs`:

``` bash
git clone https://github.com/fysikum/cmbenv.git
cd cmbenv

./cmbenv -c docker-cops-ubuntu -p /usr

time docker build -t simonsobs -f Dockerfile_docker-cops-ubuntu .
```

The build process takes around one hour. It will build a Ubuntu based image.
See `Dockerfile_docker-cops-ubuntu` for the commands which will be executed
during the build prcoess.

Note that the build command can be repeated, in which case it should complete
almost instantly.

At the end, the image `simonsobs` should be visible after issuing `docker image ls`:

``` bash
docker image ls

# REPOSITORY   TAG         IMAGE ID            CREATED           SIZE
# simonsobs    latest      315ee758c047        59 seconds ago    7.1GB
# ...
```

Now we can create one or more containers from the image. 
A suggestion is to create one container for each project.

## Using cmbenv CoPS Docker image

In this example we shall create a container for the 
[`cmbenv test simuation](https://gitlab.fysik.su.se/hpc-support/cmbenv-test-sim).
First, we clone the repository:

```  bash
git clone https://gitlab.fysik.su.se/hpc-support/cmbenv-test-sim.git
```

Next we create a container which will be used for running simulations.

``` bash
docker create -it \
  --name=sim-1 --hostname=sim-1 \
  --volume=$HOME/cmbenv-test-sim:/my-project \
  --shm-size=1024M \
  simonsobs
```

Here we specified the following options:

 * `-it` indicates that the container will be for interactive use
 * `--name sim-1` sets the name of the conainer (to label the project)
 * `--hostnamename sim-1` sets the hostname (which will be a part of the shell prompt inside the container)
 * `--volume=$HOME/cmbenv-test-sim:/my-project` binds a local directory to docker 
   (`~/cmbenv-test-sim` will appear as `/my-project` inside the container).
 * `--shm-size=1024M` reserves 1GB shared memory for the container (required for OpenMPI)

The container `sim-1` is now ready for use and can be started using `docker start`. The status
can be seen using `docker ps`:

``` bash
docker start sim-1
docker ps -a
```

To interactively 'login' on to the container, use `docker exec -it`:

``` bash
docker exec -it sim-1 bash
```

At this point we will get a bash shell prompt `root@sim-1:~#`, indicating that we are inside the container.
Note that the container is Ubuntu (type `cat /etc/*rele*` to confirm) to confirm.
As usual, to activate the cmbenv environment use `source`:

``` bash
source cmbenv
```

Finally, we can run our test simulation. (Recall that the `cmbenv-test-sim` repository 
resides in `/my-project` inside the container.)

``` bash
cd /my-project
bash job.sh  | tee log
```

## Some useful docker commands

* `docker image ls [-a]` lists images
* `docker ps [-a]` lists containers
* `docker container ls [-a]` lists containers
* `docker container start <name>` starts the container
* `docker container stop <name>` stops the container
* `docker container rm <name>` removes the container

## Complete command log

``` bash
# Build image
git clone https://github.com/fysikum/cmbenv.git
cd cmbenv
./cmbenv -c docker-cops-ubuntu -p /usr
time docker build -t simonsobs -f Dockerfile_docker-cops-ubuntu .
docker image ls -a

# Create container
git clone https://gitlab.fysik.su.se/hpc-support/cmbenv-test-sim.git
docker create -it \
  --name=sim-1 --hostname=sim-1 \
  --volume=$HOME/cmbenv-test-sim:/my-project \
  --shm-size=1024M \
  simonsobs
docker start sim-1
docker ps -a

# Run simulation
docker exec -it sim-1 bash
source cmbenv
cd /my-project
bash job.sh  | tee log
```

--------------------

# cmbenv

## Introduction

The CMB field uses a variety of software packages.  Many tools are Python based
and can easily be installed with conda or pip.  Others are more challenging to
install from source, which is often required for non-standard environments like
HPC systems.  The goal of this git repo is to make it "easier" to install many
of these packages while getting simpler tools from Python packages when
possible.

In particular, some systems may require building tools from scratch in order to
be compatible with a specialized compiler toolchain.  Other systems that are a
standard Linux flavor and less performance critical may get some tools from the
OS package manager, conda, pip, etc.


## Configuration

If you are installing on a Linux or OS X workstation you may be able to use one of the existing build configurations.  Here is a decision tree to help guide the selection:

    Linux:  Is your system python3 fairly recent (>= 3.6.0)?
        - YES.  Do you want to use Anaconda python for some reason?
            - YES.  Use the linux-conda config.
            - NO.  Use the linux-venv config.
        - NO.  You should use the linux-conda config.
    OS X:  Are you currently using macports or homebrew to get python3?
        - YES.  Do you want to use Fortran packages (libmadam)?
            - YES.  Install GNU compilers with macports or homebrew.
                    Use the osx-venv-gcc config.
            - NO.  Use the osx-venv-clang config.
        - NO.  Do you want to use Fortran packages (libmadam)?
            - YES.  Install GNU compilers with macports or homebrew.
                    Use the osx-conda-gcc config.
            - NO.  Use the osx-conda-clang config.

### Special Notes for OS X

Apple's operating system can be challenging to work with when building larger compiled packages that do not use X Code.  The native compilers do not support some languages and features, and installing external compilers (gcc) require care to ensure that all dependencies are also built with the same compiler.  Here are some recommendations:

  - Whenever you update your OS, also ensure that X Code and the commandline tools have been updated.

  - If using macports or homebrew, wipe and reinstall these when you upgrade your OS to a new major version.

If you have trouble with python or gcc on OS X, try testing the "osx-conda-clang" config.  This should be the most stand-alone solution since it uses only the system clang compiler.  Downsides of this are the lack of fortran support and perhaps other features like OpenMP threading.

### Custom Configurations

Create or edit a file in the "configs" subdirectory that is named whatever you
like.  This file will define compilers, flags, etc. Optionally create files
with the same name and the ".module" and ".sh" suffixes.  These optional files
should contain any modulefile and shell commands needed to set up the
environment prior to building the tools or loading them later.  See existing
files for examples.

To create a config for a docker image, the config file must be prefixed
with "docker-".  You should not have any "*.module" or "*.sh" files for
a docker config.


## Generate the Script

Use the top-level "cmbenv" script to generate an install script or docker file::

    %> ./cmbenv -c <config> -p <prefix> [-v <version] [-m <moduledir>]

For example::

    %> ./cmbenv -c linux-venv -p ${HOME}/cmbenv -v test


## Installation

For normal installs, simply run the install script.  I recommend doing this in a
"build" directory to avoid cluttering the source.  Continuing the previous
example::

    %> mkdir build; cd build
    %> ../install_linux-venv.sh | tee log

This installs the software and modulefile, as well as a module version file
named `.version_$CMBVERSION` in the module install directory.  You can manually
move this into place if and when you want to make that the default version.  It
also creates a simple shell snippet that you can source instead of using
modules.  

### Loading the Software

Continuing the example some more, load the above products into your environment
with::

    %> module use ${HOME}/cmbenv/modulefiles
    %> module load cmbenv

OR::

    %> source ${HOME}/cmbenv/cmbenv.sh


## Docker

For docker installs, run docker build from the same directory as the
generated Dockerfile, so that the path to data files can be found.  Making
docker images requires a working docker installation.  You
should familiarize yourself with the docker tool before attempting to use
it here.

It is recommended to tag the container with the hash of the cmbenv git
repository. In the following snippets, I assume that username is the same on
local machine, Github, DockerHub and NERSC. Build it with:

    %> docker build . -t $USER/cmbenv:$(git rev-parse --short HEAD)

### Push the Docker container to Docker Hub

Login to <https://hub.docker.com> with your Github credentials and create
a new repository named `cmbenv`, then push the image you just built to
DockerHub:

    %> docker login
    %> docker push $USER/cmbenv:$(git rev-parse --short HEAD)

### Use the Docker container at NERSC with shifter

See the [NERSC documentation about shifter](http://www.nersc.gov/users/software/using-shifter-and-docker/using-shifter-at-nersc/).

First login to Cori and pull the image from Docker Hub:

    %> shifterimg pull $USER/cmbenv:xxxxxx

This is going to take a few minutes. Then you can test this interactively:

    %> salloc -N 1 -C haswell -p debug \
       --image=docker:YOURUSERNAME/cmbenv:xxxxxx \
       -t 00:30:00
    %> shifter /bin/bash

To use this image in a slurm batch script, just add:

    #SBATCH --image=docker:YOURUSERNAME/cmbenv:xxxxx

In the SLURM header to set the image. Then prepend `shifter` to all running
commands (after `srun` and all its options).  For example, to run a script in the container:

    srun -n 1 -N 1 shifter myscript.py

If you are running any command in the container, make sure to prepend the shifter command.  For example:

    shifter which myscript.py
