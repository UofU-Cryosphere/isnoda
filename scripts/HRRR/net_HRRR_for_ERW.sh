#!/usr/bin/env bash
# Script to prepare net_solar.nc from HRRR as expected to ingest for iSnobal
# Iterates over one water year.
# Example call:
#   ./net_HRRR_for_ERW.sh <YYYY> <DSWRF_in> <albedo_in> <DSWRF_out>
#   ./net_HRRR_for_ERW.sh 2021 /path/to/DSWRF /path/to/SMRF /path/to/destination

export OMP_NUM_THREADS=${SLURM_NTASKS:-4}
export OMP_WAIT_POLICY=PASSIVE

if [[ -z "$1" ]]; then
  echo "Start year is required"
  exit 1
else
  export WATER_YEAR=$((${1} - 1))
fi
export WATER_START_MONTH=10

export DSWRF_IN=${2}
export SMRF_IN=${3}
export DSWRF_OUT=${4}

# Merge by month to get one file per day starting at midnight MST.
# The 6-hour forecast requires to add the last day of the previous month
function net_hrrr_for_month() {
  CDO_COMMAND='cdo -z zip4 -O'
  SMRF_SELECT="select,name=albedo"
  NET_MATH="aexpr,net_HRRR=albedo*illumination_angle*DSWRF"

  ERW_HRRR="${DSWRF_IN}/ERW_hrrr"
  ERW_MONTH="${DSWRF_OUT}/ERW_dswrf"
  ERW_DAY_MST="${DSWRF_OUT}/net_HRRR.MST"

  pushd "${DSWRF_OUT}" || exit

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
  ${CDO_COMMAND} mergetime ${ERW_HRRR}.${LAST_DAY}* ${ERW_HRRR}.${MONTH_SELECTOR}* ${MONTH_FILE}

  echo "  Fetch Albedo"
  SMRF_ALBEDO="${SMRF_IN}/run${MONTH_SELECTOR}*/smrf_solar_al.nc"
  SMRF_MONTH="${DSWRF_OUT}/SMRF_albedo.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} ${SMRF_SELECT} ${SMRF_ALBEDO} ${SMRF_MONTH}

  echo "  Merge DSWRF and Albedo"
  MERGE_FILE="${DSWRF_OUT}/HRRR_SMRF.${MONTH_SELECTOR}.nc"
  $CDO_COMMAND merge -selmonth,${MONTH} ${MONTH_FILE} -selmonth,${MONTH} ${SMRF_MONTH} ${MERGE_FILE}

  echo "  Calculate Net Solar HRRR"
  MONTH_CALC_FILE="${DSWRF_OUT}/net_HRRR.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} ${NET_MATH} ${MERGE_FILE} ${MONTH_CALC_FILE}

  echo "  Split by day MST"
  ${CDO_COMMAND} splitday ${MONTH_CALC_FILE} ${ERW_DAY_MST}.${MONTH_SELECTOR}

  if [[ $? != 0 ]]; then
    echo "  ** Error processing ${MONTH_SELECTOR} **"
  else
    # TODO: Execute these once tested and happy
    rm ${MONTH_FILE}
    rm ${SMRF_MONTH}
    echo "rm ${MERGE_FILE}"
  fi
}

export -f net_hrrr_for_month
parallel --jobs ${OMP_NUM_THREADS} net_hrrr_for_month ::: {0..11}
