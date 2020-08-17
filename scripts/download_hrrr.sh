#!/usr/bin/env bash

declare -a DATES=(
  20171031
)

HRRR_VARS='TMP:2 m|RH:2 m|DPT: 2 m|UGRD:10 m|VGRD:10 m|TCDC:|APCP:surface|DSWRF:surface|HGT:surface'

for DATE in "${DATES[@]}"; do
  printf "Processing: $DATE\n"

  FOLDER="hrrr.${DATE}"
  mkdir -p $FOLDER
  pushd $FOLDER

  for HOUR in {0..23}; do
    for FIELD in {0..1}; do
        FILE_NAME="hrrr.t$(printf "%02d" $HOUR)z.wrfsfcf0${FIELD}.grib2"

        wget -nv --no-check-certificate "https://pando-rgw01.chpc.utah.edu/hrrr/sfc/${DATE}/${FILE_NAME}" -O - | \
        wgrib2 - -v0 -ncpu 8 -small_grib -109.06:-102 36.99:41.01 - | \
        wgrib2 - -v0 -ncpu 8 -match "$HRRR_VARS" -GRIB $FILE_NAME | \
        printf "${FILE_NAME} created"
    done
  done
  popd
done
