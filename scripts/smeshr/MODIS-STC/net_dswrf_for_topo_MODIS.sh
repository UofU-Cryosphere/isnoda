#!/usr/bin/env bash
# Script to prepare net_solar.nc from HRRR data in expected format by iSnobal
# Uses albedo from MODIS.
#
# Script argument notes:
# * Passed month should be based of a water year; October -> 0; September -> 11
# * Paths need to be absolute for the parallel command to be able to find files
#
# Example call:
#   ./net_HRRR_for_topo_MODIS.sh <YYYY> <MM> <DSWRF_in> <MODIS_in> <DSWRF_out>
#   ./net_HRRR_for_topo_MODIS.sh 2021 "0 1 2" /path/to/DSWRF /path/to/MODIS /path/to/destination

export OMP_NUM_THREADS=6
export OMP_WAIT_POLICY=PASSIVE

if [[ -z "$1" ]]; then
  echo "Start year is required"
  exit 1
else
  export WATER_YEAR=$((${1} - 1))
fi
export WATER_START_MONTH=10

export DSWRF_IN=${3}
export MODIS_IN=${4}
export DSWRF_OUT=${5}
export BASIN=$(dirname ${DSWRF_OUT##*SMESHR/})
export DAY_MST="${DSWRF_OUT}/net_dswrf.MST"

export CDO_COMMAND='cdo -z zip4 -O -s'
export HRRR_SELECT="-select,name=illumination_angle,DSWRF"
export NET_MATH="net_solar=(1-albedo*0.0001)*illumination_angle*DSWRF;"

# Merge by month to get one file per day starting at midnight MST.
# The 6-hour forecast requires to add the last day of the previous month
function net_hrrr_for_month() {
  pushd "${DSWRF_OUT}" || exit

  CURRENT_MONTH=$(date -d "${WATER_START_MONTH}/01/${WATER_YEAR} + ${1} month")
  if [[ $? != 0 ]]; then
    exit 1
  fi
  MONTH=$(date -d "${CURRENT_MONTH}" +%m)
  MONTH_SELECTOR=$(date -d "${CURRENT_MONTH}" +%Y%m)
  LAST_DAY=$(date -d "${CURRENT_MONTH} - 1 day" +%Y%m%d)

  echo "Processing: ${MONTH_SELECTOR}"

  echo "  Merge HRRR month"
  MONTH_FILE="${DSWRF_OUT}/dswrf.${MONTH_SELECTOR}.nc"
  echo "${CDO_COMMAND} ${HRRR_SELECT} [ -mergetime ${DSWRF_IN}/*${LAST_DAY}* ${DSWRF_IN}/*${MONTH_SELECTOR}* ] ${MONTH_FILE}"
  ${CDO_COMMAND} ${HRRR_SELECT} [ -mergetime ${DSWRF_IN}/*${LAST_DAY}* ${DSWRF_IN}/*${MONTH_SELECTOR}* ] ${MONTH_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error merging HRRR month **"
    exit 1
  fi

  echo "  Fetch Albedo"
  MODIS_MONTH="${MODIS_IN}/*${MONTH_SELECTOR}*${BASIN}_24.nc"
  MODIS_MERGE="${DSWRF_OUT}/MODIS.${MONTH_SELECTOR}.nc"
  echo "${CDO_COMMAND} mergetime ${MODIS_MONTH} ${MODIS_MERGE}"
  ${CDO_COMMAND} mergetime ${MODIS_MONTH} ${MODIS_MERGE}

  if [[ $? != 0 ]]; then
    echo "  ** Error getting MODIS Albedo **"
    exit 1
  fi

  echo "  Merge DSWRF and Albedo"
  MERGE_FILE="${DSWRF_OUT}/HRRR_MODIS.${MONTH_SELECTOR}.nc"
  echo "$CDO_COMMAND merge -selmonth,${MONTH} ${MODIS_MERGE} -selmonth,${MONTH} ${MONTH_FILE} ${MERGE_FILE}"
  $CDO_COMMAND merge -selmonth,${MONTH} ${MODIS_MERGE} -selmonth,${MONTH} ${MONTH_FILE} ${MERGE_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error merging MODIS and DSWRF **"
    exit 1
  fi

  echo "  Calculate Net Solar HRRR MODIS"
  MONTH_CALC_FILE="${DSWRF_OUT}/net_HRRR.${MONTH_SELECTOR}.nc"
  echo "${CDO_COMMAND} -aexpr,"${NET_MATH}" ${MERGE_FILE} ${MONTH_CALC_FILE}"
  ${CDO_COMMAND} -aexpr,"${NET_MATH}" ${MERGE_FILE} ${MONTH_CALC_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error calculating net DSWRF **"
    exit 1
  fi

  echo "  Split by day MST"
  ${CDO_COMMAND} splitday ${MONTH_CALC_FILE} ${DAY_MST}.${MONTH_SELECTOR}

  if [[ $? != 0 ]]; then
    echo "  ** Error processing ${MONTH_SELECTOR} **"
  else
    rm ${MONTH_FILE}
    rm ${MODIS_MERGE}
    rm ${MERGE_FILE}
  fi
}

export -f net_hrrr_for_month
parallel --tagstring month-{} --line-buffer --jobs ${OMP_NUM_THREADS} net_hrrr_for_month ::: ${2}

