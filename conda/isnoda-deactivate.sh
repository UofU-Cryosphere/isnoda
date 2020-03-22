#!/usr/bin/env bash

for ISNODA_PATH in "${IPW_PATH}/sbin" "${IPW_PATH}/bin"; do
  PATH="${PATH//$ISNODA_PATH:}"
done

unset IPW
unset IPW_PATH
unset WORKDIR

unset CC
#unset LDFLAGS
#unset CPPFLAGS
