#!/usr/bin/env bash

# Script to extract albedo values for ERW model domain from MODIS.
# This prepares a NetCDF file with per grid cell albedo values for every
# hour of one day. It can be directly used to calculate net solar 
# with incoming shortwave radiation.

# Arguments:
# ${1}: /path/to/MODIS/inputs
# ${2}: water year

# command from UofU snow-rs package
# https://github.com/UofU-Cryosphere/snow-rs
# Converts the MODIS matlab to GeoTiff files
variable_from_modis --source-dir ${1} \
                    --water-year ${2} \
                    --variable albedo_observed_muZ

if [ $? != 0 ]; then
  echo "Error extracting variable from MODIS inputs"
  exit 1
fi

export ERW_NC="_ERW.nc"
export ERW_ONE_DAY_SUFFIX="_24.nc"

export CDO_call="cdo -O -z zip_4 -s"

# Extracts the ERW domain from the Western US MODIS albedo GeoTiffs
modis_erw() {
  ERW_TMP_VRT=${1/\.tif/_tmp.vrt}
  ERW_TMP_NC=${1/\.tif/_tmp.nc}

  gdalwarp -q -overwrite -multi\
    -r cubic \
    -t_srs EPSG:32613 -tr 50 50 -dstnodata 65535 \
    -te 315900.0 4280850.0 348700.0 4322700.0 \
    ${1} ${ERW_TMP_VRT}

  # There are negative resampling values when going
  # straight from MODIS GeoTiff to ERW NetCDF. Breaking
  # up in two steps via VRT
  gdalwarp -overwrite -multi -q \
    -co FORMAT=NC4C -co WRITE_BOTTOMUP=NO \
    ${ERW_TMP_VRT} ${ERW_TMP_NC}

  if [ $? != 0 ]; then
    printf "Error extracting domain from: \n   ${1}\n"
    return 1
  fi

  date=$(date -d $(basename $1 | cut -d '_' -f2) +%Y-%m-%d)
  # Set time and variable name in NetCDF
  ${CDO_call} \
    -expr,"Band1=((Band1 > 10000)) ? 10000 : Band1" \
    -setdate,"${date}" \
    ${ERW_TMP_NC} ${1/\.tif/${ERW_NC}}

  if [ $? != 0 ]; then
    echo "Error setting NetCDF variable name and time"
    return 1
  fi

  rm ${ERW_TMP_VRT}
  rm ${ERW_TMP_NC}
}
export -f modis_erw
parallel --tag --line-buffer --jobs ${SLURM_NTASKS} modis_erw ::: ${1}/wy${2}/*.tif

# Creates a NetCDF using the extracted ERW domain values and
# populates every hour of one day with those.
albedo_day() {
  HOUR_FILE=${1/\.nc$//}

  if [[ ! -f "${1}" ]]; then
    printf "Error: Source NetCDF:  \n  ${1}\n  does not exist\n"
    return 1
  fi

  for hour in {1..23}; do
    ${CDO_call} -shifttime,${hour}hour \
      ${1} ${HOUR_FILE}_${hour}.nc
  done

  ${CDO_call} mergetime -chname,Band1,albedo $1 \
    ${HOUR_FILE}*.nc ${1/\.nc/${ERW_ONE_DAY_SUFFIX}}

  if [ $? != 0 ]; then
    printf "Error: Could not merge hours for:\n  ${1}\n"
    return 1
  fi

  printf "*\n"

  rm ${HOUR_FILE}*.nc
  rm ${1}
}

export -f albedo_day
parallel --tag --line-buffer --jobs ${SLURM_NTASKS} albedo_day ::: ${1}/wy${2}/*${ERW_NC}

