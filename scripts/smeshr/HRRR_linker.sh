#!/usr/bin/env bash
# Script to link net_solar.nc and cloud for iSnobal run
#
# NOTE: ISNOBAL path needs to be in quotes to prevent bash variable expansion
#
# Usage: 
#  HRRR_linker.sh <ISNOBAL_OUT_FOLDERS> <HRRR_FORCING_PREFIX> <FILE_TO_LINK>
#
# Example: 
#  HRRR_linker.s "/path/to/isnobal/run*" "/path/to/HRRR/forcing/net_dswrf" "net_solar.nc"

for DAY in $1; do
  pushd $DAY || exit 1
  DAY=$(echo $DAY | cut -d '/' -f11,12 | sed 's/\//./g' | sed 's/run//g' );
  ln -fs $2.$DAY.nc $3
  popd
done
