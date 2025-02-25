#!/bin/bash

# This is (for example) install.in, Dockerfile.in, etc
template=$1

# The config file definitions and package list
config=$2
conffile=$3
pkgfile=$4
confmodinit=$5
confshinit=$6

# The output root of the install script
outroot=$7

# Runtime options
prefix=$8
version=$9
moddir=${10}

# Is this template a dockerfile?  If this is "yes", then when calling
# package scripts we will insert the "RUN " prefix and also capture the
# downloaded files so that we can clean them up on the same line without
# polluting the image.
docker=${11}

# Top level cmbenv git checkout
pushd $(dirname $0) > /dev/null
topdir=$(dirname $(pwd))
popd > /dev/null

# The outputs
if [ "x${docker}" = "xyes" ]; then
    outfile="${outroot}"
else
    outfile="${outroot}.sh"
fi
outmod="${outfile}.mod"
outmodver="${outfile}.modver"
outinit="${outfile}.init"
outpkg="${outroot}_pkgs"
rm -f "${outfile}"
rm -f "${outmod}"
rm -f "${outmodver}"
rm -rf "${outpkg}"

mkdir -p "${outpkg}"


# Create list of variable substitutions from the input config file

pyversion=""

confsub="-e 's#@CONFFILE@#${conffile}#g'"
confsub="${confsub} -e 's#@CONFIG@#${config}#g'"

while IFS='' read -r line || [[ -n "${line}" ]]; do
    # is this line commented?
    comment=$(echo "${line}" | cut -c 1)
    if [ "${comment}" != "#" ]; then

        check=$(echo "${line}" | sed -e "s#.*=.*#=#")

        if [ "x${check}" = "x=" ]; then
            # get the variable and its value
            var=$(echo ${line} | sed -e "s#\([^=]*\)=.*#\1#" | awk '{print $1}')
            val=$(echo ${line} | sed -e "s#[^=]*= *\(.*\)#\1#")
            if [ "${var}" = "PYVERSION" ]; then
                if [ "x${val}" = "xauto" ]; then
                    val=$(python3 --version 2>&1 | awk '{print $2}' | sed -e "s#\(.*\)\.\(.*\)\..*#\1.\2#")
                fi
                pyversion="${val}"
            fi

            # add to list of substitutions
            confsub="${confsub} -e 's#@${var}@#${val}#g'"
        fi
    fi
done < "${conffile}"

# We add these predefined matches at the end- so that the config
# file can actually use these as well.

compiled_prefix=${COMPILED_PREFIX:-"${prefix}/cmbenv_aux"}
python_prefix=${PYTHON_PREFIX:-"${prefix}/cmbenv_python"}
module_dir=${MODULE_DIR:-"${moddir}/cmbenv"}

if [ "x${docker}" = "xyes" ]; then
    if [ "x${prefix}" = "x" ]; then
        compiled_prefix="/usr"
        python_prefix="/usr"
    else
        compiled_prefix="${prefix}"
        python_prefix="${prefix}"
    fi
fi

confsub="${confsub} -e 's#@SRCDIR@#${topdir}#g'"
confsub="${confsub} -e 's#@PREFIX@#${prefix}#g'"
confsub="${confsub} -e 's#@AUX_PREFIX@#${compiled_prefix}#g'"
confsub="${confsub} -e 's#@PYTHON_PREFIX@#${python_prefix}#g'"
confsub="${confsub} -e 's#@VERSION@#${version}#g'"
confsub="${confsub} -e 's#@MODULE_DIR@#${module_dir}#g'"

# If we are using docker, then the package scripts need to be able to find
# the tools that we have copied into the container.
if [ "x${docker}" = "xyes" ]; then
    confsub="${confsub} -e 's#@TOP_DIR@#/home/cmbenv#g'"
else
    confsub="${confsub} -e 's#@TOP_DIR@#${topdir}#g'"
fi

# Process each selected package for this config.  Copy each package file into
# the output location while substituting config variables.  Also build up the
# text that will be inserted into the template.

pkgcom=""

while IFS='' read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^#.* ]]; then
        # This is a comment line
        echo "" >/dev/null
    else
        # This is a package line
        pkgname=""
        pkgopts=""
        if [[ "${line}" =~ ":" ]]; then
            # We have a package and options
            pkgname=$(echo "${line}" | sed -e 's/\(.*\):.*/\1/')
            pkgopts=$(echo "${line}" | sed -e 's/.*:\(.*\)/\1/')
        else
            # We have just a package
            pkgname=$(echo "${line}" | awk '{print $1}')
        fi

        # Copy the package file into place while applying the config.
        while IFS='' read -r pkgline || [[ -n "${pkgline}" ]]; do
            echo "${pkgline}" | eval sed ${confsub} >> "${topdir}/${outpkg}/${pkgname}.sh"
        done < "${topdir}/pkgs/${pkgname}.sh"
        chmod +x "${topdir}/${outpkg}/${pkgname}.sh"

        # Copy any patch file
        if [ -e "${topdir}/pkgs/patch_${pkgname}" ]; then
            cp -a "${topdir}/pkgs/patch_${pkgname}" "${topdir}/${outpkg}/"
        fi

        if [ "x${docker}" = "xyes" ]; then
            pcom="RUN cln=\$(./${outpkg}/${pkgname}.sh ${pkgopts}) && if [ \"x\${cln}\" != \"x\" ]; then for cl in \${cln}; do if [ -e \"\${cl}\" ]; then rm -rf \"\${cl}\"; fi; done; fi"
            pkgcom+="${pcom}"$'\n'$'\n'
        else
            # pcom="cln=\$(${topdir}/${outpkg}/${pkgname}.sh ${pkgopts}); if [ \$? -ne 0 ]; then echo \"FAILED\"; exit 1; fi"
            pcom="call_installer ${topdir}/${outpkg} ${pkgname} ${pkgopts}"
            pkgcom+="${pcom}"$'\n'$'\n'
        fi
    fi
done < "${pkgfile}"


# Now process the input template, substituting the list of package install
# commands that we just built.

while IFS='' read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ @PACKAGES@ ]]; then
        echo "${pkgcom}" >> "${outfile}"
    else
        echo "${line}" | eval sed ${confsub} >> "${outfile}"
    fi
done < "${topdir}/templates/${template}"
chmod +x "${outfile}"


# Finally, create the module file and module version file for this config.
# Also create a shell snippet that can be sourced.

if [ "x${docker}" != "xyes" ]; then
    while IFS='' read -r line || [[ -n "${line}" ]]; do
        if [[ "${line}" =~ @modload@ ]]; then
            if [ -e "${confmodinit}" ]; then
                cat "${confmodinit}" >> "${outmod}"
            fi
        else
            echo "${line}" | eval sed ${confsub} >> "${outmod}"
        fi
    done < "${topdir}/templates/modulefile.in"

    while IFS='' read -r line || [[ -n "${line}" ]]; do
        echo "${line}" | eval sed ${confsub} >> "${outmodver}"
    done < "${topdir}/templates/version.in"

    echo "# Source this file from a Bourne-compatible shell to load" > "${outinit}"
    echo "# this cmbenv installation into your environment:" >> "${outinit}"
    echo "#" >> "${outinit}"
    echo "#   %>  . path/to/cmbenv_init.sh" >> "${outinit}"
    echo "#" >> "${outinit}"
    echo "# Then do \"source cmbenv\" as usual." >> "${outinit}"
    echo "#" >> "${outinit}"
    if [ -e "${confshinit}" ]; then
        cat "${confshinit}" | sed 's#@VERSION@#${version}#g' >> "${outinit}"
    fi
    echo "unset PYTHONSTARTUP" >> "${outinit}"
    echo "export PYTHONUSERBASE=\$HOME/.local/cmbenv-${version}" >> "${outinit}"
    echo "export PATH=\"${python_prefix}/bin\":\${PATH}" >> "${outinit}"

fi
