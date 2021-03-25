#!/bin/bash

echo "Started easy_install site packages" >&2

cd @AUX_PREFIX@/lib/python@PYVERSION@/site-packages/

for n in $(cat easy-install.pth); do 
  easy_install $n 1>&2
done

echo "Finished easy_install site packages" >&2
exit 0
