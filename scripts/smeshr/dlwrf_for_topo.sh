#!/usr/bin/env bash
# Does the following sequence:
# * Extract DLWRF from given HRRR files for given topo extent
# * Uses cubic resampling to downscale the data
# * Creates daily output files organized in MST time zone
#
# NOTES:
# - First argument needs to be in quotes to prevent shell expansion
# - Months argument are relative to the start month of october
#
# Arguments:
#   ./dlwrf_for_topo.sh <TOPO> <FOLDER_PATTERN> <HRRR_FILE_PATTERN> <OUTPUT_PATH_WITH_PREFIX> <WATER_YEAR> <MONTHS> <SNOBAL_OUT> <RESAMPLE_METHOD>
# Sample call:
#   ./dlwrf_for_topo.sh /full/path/to/topo.nc \
#                     "hrrr.YYYYMM*" \
#                     "hrrr.t*f06.grib2" \
#                     /path/to/write/out/dlwrf/outputs/with/file_prefix \
#                     2021 \
#                     "1 2 3" \
#                     /input/read/from/isnobal \
#		      "cubic" (for cubic resampling, if not provided it will be default method)
#

# For wgrib
export OMP_NUM_THREADS=${SLURM_NTASKS:-4}
export OMP_WAIT_POLICY=PASSIVE

## Part 1 - Extract from HRRR Grib, crop and resample/interpolate to basin

export TOPO_FILE=${1}
HRRR_GLOB=${2}
export HRRR_PATTERN=${3}
export NC_OUT_PREFIX=${4}
export RESAMPLE_METHOD=${8:-}

get_day() {
  DAY=$1
  echo $DAY
  pushd $DAY > /dev/null

  TMPF=$DAY.grib2

  cat ${HRRR_PATTERN} | wgrib2 - -match "DLWRF:surface" -inv /dev/null -grib $TMPF
  echo $TMPF
  if [[ -n "$RESAMPLE_METHOD" ]]; then
    echo "Using resampling method: $RESAMPLE_METHOD"
    hrrr_param_for_topo --topo "${TOPO_FILE}" \
                        --hrrr_in "$TMPF" \
                        --nc_out "${NC_OUT_PREFIX}${DAY}.nc" \
                        --resample "$RESAMPLE_METHOD"
  else
    echo "Using default resampling method"
    hrrr_param_for_topo --topo "${TOPO_FILE}" \
                        --hrrr_in "$TMPF" \
                        --nc_out "${NC_OUT_PREFIX}${DAY}.nc"
  fi

  rm $TMPF
  popd > /dev/null
}

export -f get_day
parallel --tag --line-buffer --jobs ${OMP_NUM_THREADS} get_day ::: ${HRRR_GLOB}

## Part 2 - Organize by MST

## Reduce overload on disk with too many parallel processes
export OMP_NUM_THREADS=4

if [[ -z "$5" ]]; then
  echo "Start year is required"
  exit 1
else
  export WATER_YEAR=$((${5} - 1))
fi
export WATER_START_MONTH=10

export DLWRF_IN=${4}
export DLWRF_OUT=${7}

# Merge by month to get one file per day starting at midnight MST.
# The 6-hour forecast requires to add the last day of the previous month
function dlwrf_for_month() {
  CDO_COMMAND='cdo -z zip4 -O'

  # Need to add the 'hrrr' back in as it stems from the HRRR folder pattern
  DLWRF_IN="${DLWRF_IN}hrrr"
  BASIN_MONTH="${DLWRF_OUT}/BASIN_DLWRF"
  BASIN_DAY_MST="${DLWRF_OUT}/dlwrf.MST"

  pushd "${DLWRF_OUT}" || exit

  CURRENT_MONTH=$(date -d "${WATER_START_MONTH}/01/${WATER_YEAR} + ${1} month")
  if [[ $? != 0 ]]; then
    exit 1
  fi
  MONTH=$(date -d "${CURRENT_MONTH}" +%m)
  MONTH_SELECTOR=$(date -d "${CURRENT_MONTH}" +%Y%m)
  LAST_DAY=$(date -d "${CURRENT_MONTH} - 1 day" +%Y%m%d)

  echo "Processing: ${MONTH_SELECTOR}"

  echo "  Merge month"
  MONTH_FILE="${BASIN_MONTH}.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} mergetime -selmonth,${MONTH} ${DLWRF_IN}.${LAST_DAY}* ${DLWRF_IN}.${MONTH_SELECTOR}* ${MONTH_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error merging month ${MONTH_SELECTOR} **"
    exit 1
  fi

  echo "  Split by day MST"
  ${CDO_COMMAND} splitday -selmonth,${MONTH} ${MONTH_FILE} ${BASIN_DAY_MST}.${MONTH_SELECTOR}

  if [[ $? != 0 ]]; then
    echo "  ** Error splitting ${MONTH_SELECTOR} **"
  else
    rm ${MONTH_FILE}
  fi
}

export -f dlwrf_for_month
parallel --tag --line-buffer --jobs ${OMP_NUM_THREADS} dlwrf_for_month ::: ${6}

