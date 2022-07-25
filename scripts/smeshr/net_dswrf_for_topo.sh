#!/usr/bin/env bash
# Script to prepare net_solar.nc from HRRR data in expected format by iSnobal
# Uses time-decay albedo outputs from SMRF, compacted by the `smrf_compactor`
# command.
#
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
  SMRF_ALBEDO_MATH="albedo=(0.67 * albedo_vis) + (0.33 * albedo_ir);"
  NET_MATH="aexpr,net_solar=(1-albedo)*illumination_angle*DSWRF"

  ERW_HRRR="${DSWRF_IN}/ERW_hrrr"
  ERW_MONTH="${DSWRF_OUT}/ERW_dswrf"
  ERW_DAY_MST="${DSWRF_OUT}/net_dswrf.MST"

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
  SMRF_EB="${SMRF_IN}/run${MONTH_SELECTOR}*/smrf_energy_balance*.nc"
  SMRF_MONTH="${DSWRF_OUT}/SMRF_albedo.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} -expr="${SMRF_ALBEDO_MATH}" ${SMRF_EB} ${SMRF_MONTH}

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
    rm ${MONTH_FILE}
    rm ${SMRF_MONTH}
    rm ${MERGE_FILE}
  fi
}

export -f net_hrrr_for_month
parallel --jobs ${OMP_NUM_THREADS} net_hrrr_for_month ::: {0..11}
