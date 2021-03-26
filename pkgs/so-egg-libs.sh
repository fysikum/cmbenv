#!/bin/bash

pkg="so-egg-libs"
pkgopts=$@
cleanup=""

log=$(realpath "log_${pkg}")

echo "Building ${pkg}..." >&2

log=$(realpath "log_${pkg}")

cd @AUX_PREFIX@/lib/python@PYVERSION@/site-packages/

for n in $(cat easy-install.pth); do 
  easy_install $n >> ${log} 2>&1
done

echo "Finished building ${pkg}..." >&2
exit 0
