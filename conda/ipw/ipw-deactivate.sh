#!/usr/bin/env bash

for IPW_BIN_PATH in "${IPW}/sbin" "${IPW}/bin"; do
  export PATH="${PATH//\:$IPW_BIN_PATH}"
done

unset IPW
unset IPW_PATH
unset WORKDIR

unset CC
