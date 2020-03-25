#!/usr/bin/env bash

declare -a DATES=(
  20170930
  20171001
  20171002
  20171003
)

for DATE in "${DATES[@]}"; do
  mkdir -p "hrrr.${DATE}"
  pushd "hrrr.${DATE}"
  for HOUR in {0..23}; do
    for FIELD in {0..2}; do
      wget "https://pando-rgw01.chpc.utah.edu/hrrr/sfc/${DATE}/hrrr.t$(printf "%02d" $HOUR)z.wrfsfcf0${FIELD}.grib2"
    done
  done
  popd
done

