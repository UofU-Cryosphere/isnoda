#!/usr/bin/env bash

##  !! IMPORTANT !! ##
# Set the IPW_PATH value to the directory path of the cloned IPW GitHub repository
IPW_PATH=/path/to/cloned/ipw
##

export IPW=$IPW_PATH
export WORKDIR=$HOME/snoda

export PATH=${IPW_PATH}/bin:${IPW_PATH}/sbin:$PATH
