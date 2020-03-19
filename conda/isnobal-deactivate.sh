#!/usr/bin/env bash

for ISNOBAL_PATH in "${IPW_PATH}/sbin" "${IPW_PATH}/bin" "${MACPORTS}" ; do
  PATH="${PATH//$ISNOBAL_PATH:}"
done

unset IPW
unset IPW_PATH
unset WORKDIR

unset MACPORTS

unset CC
#unset LDFLAGS
#unset CPPFLAGS
