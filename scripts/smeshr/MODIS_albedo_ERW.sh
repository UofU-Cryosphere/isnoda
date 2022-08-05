#!/usr/bin/env bash
# Script to extract albedo values for ERW model domain from MODIS.
# This prepares a NetCDF file with per grid cell albedo values. It can be
# directly used to calculate net solar with incoming shortwave radiation.

# Arguments:
# ${1}: /path/to/MODIS/inputs
# ${2}: water year
# ${3}: /path/to/extracted/MODIS/albedo

# command from isnoda snobedo package
variable_from_modis --source-dir ${1} \
                    --water-year ${2} \
                    --variable albedo_observed_muZ

export ERW_NC="_ERW.nc"
export ERW_ONE_DAY_SUFFIX="_24.nc"

# First argument is the tif; second the boundaries
modis_erw() {
  ERW_TMP=${1/\.tif/_tmp.nc}

  gdalwarp -overwrite -multi\
  -co FORMAT=NC4C -co WRITE_BOTTOMUP=NO -ot Float32 \
  -t_srs EPSG:32613 -tr 50 50 -dstnodata -1\
  -te 315900.0 4280850.0 348700.0 4322700.0 \
  ${1} ${ERW_TMP}

  if [ $? != 0 ]; then
    printf "Error extracting domain from: \n   ${1}\n"
    return 1
  fi

  date=$(date -d $(echo $1 | cut -d '_' -f2) +%Y-%m-%d)
  # Set time and variable name in NetCDF
  cdo -O -z zip_4 -chname,Band1,albedo \
                  -setdate,"${date}" \
                  ${ERW_TMP} ${1/\.tif/${ERW_NC}}

  if [ $? != 0 ]; then
    echo "Error setting NetCDF variable name and time"
    return 1
  fi

  rm ${ERW_TMP}
  rm ${1}
}
export -f modis_erw
parallel --tag --line-buffer --jobs ${SLURM_NTASKS} modis_erw ::: ${3}

albedo_day() {
  HOUR_FILE="shift_${1}"
  HOUR_FILE=${HOUR_FILE/\.nc$//}

  if [[ ! -f "${1}" ]]; then
    printf "Error: Source NetCDF:  \n  ${1}\n  does not exist\n"
    return 1
  fi

  for hour in {1..23}; do
    cdo -O -z zip_4 -shifttime,${hour}hour $1 ${HOUR_FILE}_${hour}.nc
  done

  cdo -O -z zip_4 mergetime $1 ${HOUR_FILE}*.nc ${1/\.nc/${ERW_ONE_DAY_SUFFIX}}

  if [ $? != 0 ]; then
    printf "Error: Could not merge hours for:\n  ${1}\n"
    return 1
  fi

  rm ${HOUR_FILE}*.nc
  rm ${1}
}

export -f albedo_day
parallel --tag --line-buffer --jobs ${SLURM_NTASKS} albedo_day ::: *${ERW_NC}
