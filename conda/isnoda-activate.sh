#!/usr/bin/env bash

IPW_PATH=$HOME/snoda/ipw
export IPW=$IPW_PATH
export WORKDIR=$HOME/snoda

export PATH=${IPW_PATH}/bin:${IPW_PATH}/sbin:$PATH

# Used in SMRF test assertions
export NOT_ON_GOLD_HOST=1

#export CC="gcc-7"
#export LDFLAGS="-L${CONDA_PREFIX}/include -Wl,-rpath,${CONDA_PREFIX}/include"
#export CPPFLAGS="-I${CONDA_PREFIX}/include"

