#!/usr/bin/env bash
# Does the following sequence:
# * Extract TCDC from given HRRR files for given topo extent
# * Calculates the cloud factor in format expected by iSnobal
# * Creates daily output files organized in MST time zone
#
# NOTES:
# - First argument needs to bin quotes to prevent shell expansion
# - Months argument are relative to the start month of october
#
# Arguments:
#   ./tcdc_for_topo.sh <TOPO> <FOLDER_PATTERN> <HRRR_FILE_PATTERN> <OUTPUT_PATH_WITH_PREFIX> <WATER_YEAR> <MONTHS> <SNOBAL_OUT>
# Sample call:
#   ./tcdc_for_topo.sh /full/path/to/topo.nc \
#                     "hrrr.YYYYMM*" \
#                     "hrrr.t*f06.grib2" \
#                     /path/to/write/out/tcdc/outputs/with/file_prefix \
#                     2021 \
#                     "1 2 3" \
#                     /input/read/from/isnobal
#

# For wgrib
export OMP_NUM_THREADS=${SLURM_NTASKS:-4}
export OMP_WAIT_POLICY=PASSIVE

## Part 1 - Extract from HRRR Grib, crop and interpolate to ERW

export TOPO_FILE=${1}
HRRR_GLOB=${2}
export HRRR_PATTERN=${3}
export NC_OUT_PREFIX=${4}

get_day() {
  DAY=$1
  echo $DAY
  pushd $DAY > /dev/null

  TMPF=$DAY.grib2

  echo "cat ${HRRR_PATTERN} | wgrib2 - -match "TCDC:entire atmosphere" -inv /dev/null -grib $TMPF"
  cat ${HRRR_PATTERN} | wgrib2 - -match "TCDC:entire atmosphere" -inv /dev/null -grib $TMPF


  echo "hrrr_param_for_topo --topo ${TOPO_FILE} --hrrr_in ${TMPF} --nc_out ${NC_OUT_PREFIX}${DAY}.tcdc.nc"
  hrrr_param_for_topo --topo "${TOPO_FILE}" \
                      --hrrr_in $TMPF \
                      --nc_out "${NC_OUT_PREFIX}${DAY}.tcdc.nc" \

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

export TCDC_IN=${4}
export TCDC_OUT=${7}

# Merge by month to get one file per day starting at midnight MST.
# The 6-hour forecast requires to add the last day of the previous month
function tcdc_for_month() {
  CDO_COMMAND='cdo -z zip4 -O'
  # SMRF uses 1.0 as clear sky and 0.0 as full cloud cover
  CDO_MATH="TCDC=(100-TCDC)*0.01"

  # Need to add the 'hrrr' back in as it stems from the HRRR folder pattern
  TCDC_IN="${TCDC_IN}hrrr"
  ERW_MONTH="${TCDC_OUT}/ERW_TCDC"
  ERW_DAY_MST="${TCDC_OUT}/tcdc.MST"

  pushd "${TCDC_OUT}" || exit

  CURRENT_MONTH=$(date -d "${WATER_START_MONTH}/01/${WATER_YEAR} + ${1} month")
  if [[ $? != 0 ]]; then
    exit 1
  fi
  MONTH=$(date -d "${CURRENT_MONTH}" +%m)
  MONTH_SELECTOR=$(date -d "${CURRENT_MONTH}" +%Y%m)
  LAST_DAY=$(date -d "${CURRENT_MONTH} - 1 day" +%Y%m%d)

  echo "Processing: ${MONTH_SELECTOR}"

  echo "  Merge month"
  MONTH_FILE="${ERW_MONTH}.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} mergetime -selmonth,${MONTH} ${TCDC_IN}.${LAST_DAY}* ${TCDC_IN}.${MONTH_SELECTOR}* ${MONTH_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error merging month ${MONTH_SELECTOR} **"
    exit 1
  fi

  echo "  Split by day MST and convert to fraction"
  ${CDO_COMMAND} splitday -selmonth,${MONTH} -expr,"${CDO_MATH}" ${MONTH_FILE} ${ERW_DAY_MST}.${MONTH_SELECTOR}

  if [[ $? != 0 ]]; then
    echo "  ** Error splitting ${MONTH_SELECTOR} **"
  else
    rm ${MONTH_FILE}
  fi
}

export -f tcdc_for_month
parallel --tag --line-buffer --jobs ${OMP_NUM_THREADS} tcdc_for_month ::: ${6}

