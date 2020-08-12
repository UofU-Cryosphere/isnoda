#!/usr/bin/env bash

declare -a DATES=(
  20171031
)

HRRR_VARS='TMP:2 m|RH:2 m|DPT: 2 m|UGRD:10 m|VGRD:10 m|TCDC:|APCP:surface|DSWRF:surface|HGT:surface'

for DATE in "${DATES[@]}"; do
  FOLDER="hrrr.${DATE}"
  mkdir -p $FOLDER
  pushd $FOLDER

  for HOUR in {0..23}; do
    for FIELD in {0..1}; do
        FILE_NAME="hrrr.t$(printf "%02d" $HOUR)z.wrfsfcf0${FIELD}.grib2"

        grib_download="${FILE_NAME}_download"
        wget --no-check-certificate "https://pando-rgw01.chpc.utah.edu/hrrr/sfc/${DATE}/${FILE_NAME}" -O $grib_download

        wgrib_file="${FILE_NAME}_tmp"
        mkfifo $wgrib_file

        wgrib2 -ncpu 8 $grib_download -small_grib -109.06:-102 36.99:41.01 $wgrib_file &
        wgrib2 $wgrib_file -ncpu 8 -match "$HRRR_VARS" -GRIB $FILE_NAME

        rm $wgrib_file
        rm $grib_download

    done
  done
  popd
done
