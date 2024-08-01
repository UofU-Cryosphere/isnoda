#!/usr/bin/env bash

# Script to extract albedo values for a model domain from MODIS.
# This prepares a NetCDF file with per grid cell albedo values for every
# hour of one day. It can be directly used to calculate net solar 
# with incoming shortwave radiation.

# Arguments:
# ${1}: /path/to/MODIS/inputs
# ${2}: water year

set -e

extract_modis() {
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
}

# Basin name and processing parameters
BASIN='yampa'
BASIN_EXTENT='156776.4 4426242.0 365276.4 4530442.0' #yampa
RES=100
EPSG='EPSG:32613'
BASIN_DOMAIN=" -t_srs $EPSG -tr $RES $RES -dstnodata 65535 -te $BASIN_EXTENT"

SLURM_NTASKS=4

export BASIN_NC="_${BASIN}.nc"
export BASIN_ONE_DAY_SUFFIX="_24.nc"

export CDO_call="cdo -O -z zip_4 -f nc4 -s"
export PARALLEL_call="parallel --tagstring {#} --tag --line-buffer --jobs ${SLURM_NTASKS}"

# Extracts the BASIN domain from the Western US MODIS albedo GeoTiffs
modis_basin() {
  BASIN_TMP_CUBIC=${1/\.tif/_cubic_tmp.vrt}
  BASIN_TMP_NN=${1/\.tif/_nn_tmp.vrt}
  BASIN_TMP=${1/\.tif/_tmp.tif}
  BASIN_TMP_NC=${1/\.tif/_tmp.nc}
  BASIN_DOMAIN="${@:2}"

  echo "BASIN_DOMAIN: ${BASIN_DOMAIN}"
  FILTER_MATH="A*(A<=numpy.max(B)) + numpy.max(B)*(A>numpy.max(B))" 
  echo "gdalwarp -q -overwrite -multi \
    -r cubic ${BASIN_DOMAIN} \
    ${1} ${BASIN_TMP_CUBIC}"

  # Use cubic resampling to smooth the image
  gdalwarp -q -overwrite -multi \
    -r cubic ${BASIN_DOMAIN} \
    ${1} ${BASIN_TMP_CUBIC}

  # Generate a nearest neighbor to get the max basin value as filter
  gdalwarp -q -overwrite -multi \
    ${BASIN_DOMAIN} \
    ${1} ${BASIN_TMP_NN}

  # Combine products, filter any values from cubic resampling higher
  # than the max of nearest neighbor and set to that value
  gdal_calc.py --overwrite --quiet --co COMPRESS=LZW \
    -A ${BASIN_TMP_CUBIC} -B ${BASIN_TMP_NN} \
    --calc="${FILTER_MATH}" \
    --outfile=${BASIN_TMP}

  # Convert to NetCDF
  gdalwarp -overwrite -multi -q \
    -co FORMAT=NC4C -co WRITE_BOTTOMUP=NO \
    ${BASIN_TMP} ${BASIN_TMP_NC}

  if [ $? != 0 ]; then
    printf "Error extracting domain from: \n   ${1}\n"
    return 1
  fi

  date=$(date -d $(basename $1 | cut -d '_' -f3) +%Y-%m-%d)
  # Set time and variable name in NetCDF
  ${CDO_call} \
    -chname,Band1,albedo \
    -setdate,"${date}" \
    -settunits,1hour \
    ${BASIN_TMP_NC} ${1/\.tif/${BASIN_NC}}

  if [ $? != 0 ]; then
    echo "Error setting NetCDF variable name and time"
    return 1
  fi

  printf "DONE: ${date}\n"

  rm ${BASIN_TMP_CUBIC}
  rm ${BASIN_TMP_NN}
  rm ${BASIN_TMP}
  rm ${BASIN_TMP_NC}
}
export -f modis_basin
echo "Extracting MODIS albedo"
${PARALLEL_call} modis_basin {} ${BASIN_DOMAIN} ::: ${1}/wy${2}/*.tif 

# Creates a NetCDF using the extracted model domain values and
# populates every hour of one day with those.
albedo_day() {
  HOUR_FILE=${1/\.nc$//}

  if [[ ! -f "${1}" ]]; then
    printf "Error: Source NetCDF:  \n  ${1}\n  does not exist\n"
    return 1
  fi

  # Duplicate the single day value for every hour
  for hour in {1..23}; do
    ${CDO_call} -shifttime,${hour}hour \
      ${1} ${HOUR_FILE}_${hour}.nc
  done

  # Make on file with values for every full hour and given file
  ${CDO_call} mergetime ${1} ${HOUR_FILE}*.nc ${1/\.nc/${BASIN_ONE_DAY_SUFFIX}}

  if [ $? != 0 ]; then
    printf "Error: Could not merge hours for:\n  ${1}\n"
    return 1
  fi

  printf "*\n"

  rm ${HOUR_FILE}*.nc
  rm ${1}
}

export -f albedo_day
echo "Creating NetCDFs"
${PARALLEL_call} albedo_day ::: ${1}/wy${2}/*${BASIN_NC}

