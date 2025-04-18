#!/usr/bin/env bash
# Script to prepare net_solar.nc from HRRR data in expected format by iSnobal
# Uses time-decay albedo outputs from SMRF, compacted by the `smrf_compactor`
# command.
#
# Iterates over one water year.
# Example call:
#   ./net_HRRR_for_topo_SMRF.sh <YYYY> <MM> <DSWRF_in> <albedo_in> <DSWRF_out>
#   ./net_HRRR_for_topo_SMRF.sh 2021 "0 1 2" /path/to/DSWRF /path/to/SMRF /path/to/destination

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
export SMRF_IN=${4}
export DSWRF_OUT=${5}
export BASIN_DAY_MST="${DSWRF_OUT}/net_dswrf.UTC"

export CDO_COMMAND='cdo -z zip4 -O'
export HRRR_SELECT="-select,name=illumination_angle,DSWRF"
export SMRF_SELECT="-select,name=albedo_vis,albedo_ir"
export NET_MATH="\
albedo=(0.67*albedo_vis)+(0.33*albedo_ir);\
net_solar=(1-albedo)*illumination_angle*DSWRF;\
"

# Merge by month to get one file per day starting at midnight UTC.
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
  ${CDO_COMMAND} ${HRRR_SELECT} [ -mergetime ${DSWRF_IN}/*${LAST_DAY}* ${DSWRF_IN}/*${MONTH_SELECTOR}* ] ${MONTH_FILE}


  if [[ $? != 0 ]]; then
    echo "  ** Error merging HRRR month **"
    exit 1
  fi

  echo "  Fetch Albedo"
  SMRF_EB="${SMRF_IN}/run${MONTH_SELECTOR}*/smrf_energy_balance*.nc"
  SMRF_MERGE="${DSWRF_OUT}/SMRF.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} ${SMRF_SELECT} ${SMRF_EB} ${SMRF_MERGE}

  if [[ $? != 0 ]]; then
    echo "  ** Error fetching Albedo **"
    exit 1
  fi

  echo "  Merge DSWRF and Albedo"
  MERGE_FILE="${DSWRF_OUT}/HRRR_SMRF.${MONTH_SELECTOR}.nc"
  $CDO_COMMAND merge -selmonth,${MONTH} ${MONTH_FILE} -selmonth,${MONTH} ${SMRF_MERGE} ${MERGE_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error merging SRMF and DSWRF **"
    exit 1
  fi

  echo "  Calculate Net Solar HRRR"
  MONTH_CALC_FILE="${DSWRF_OUT}/net_HRRR.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} -aexpr,"${NET_MATH}" ${MERGE_FILE} ${MONTH_CALC_FILE}

  echo "  Split by day UTC"
  ${CDO_COMMAND} splitday ${MONTH_CALC_FILE} ${BASIN_DAY_MST}.${MONTH_SELECTOR}

  if [[ $? != 0 ]]; then
    echo "  ** Error processing ${MONTH_SELECTOR} **"
  else
    rm ${MONTH_FILE}
    rm ${SMRF_MERGE}
    rm ${MERGE_FILE}
  fi
}

export -f net_hrrr_for_month
parallel --tag --line-buffer --jobs ${OMP_NUM_THREADS} net_hrrr_for_month ::: ${2}
