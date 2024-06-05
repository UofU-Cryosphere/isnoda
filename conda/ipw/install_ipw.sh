#!/usr/bin/env bash
# IPW
# Script to install the point-model of iSnobal

git clone --depth 1 https://github.com/USDA-ARS-NWRC/ipw.git
pushd ipw

export IPW=$(pwd)
export WORKDIR=${IPW}/tmp

./configure
make
make install

popd
