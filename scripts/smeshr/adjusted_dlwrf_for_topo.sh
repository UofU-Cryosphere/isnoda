#!/usr/bin/env bash
# Script to prepare thermal.nc from HRRR data in expected format by iSnobal
# Uses DLWRF from HRRR, distributed air_temp from SMRF and sky-view factor.
#
# Script argument notes:
# * Passed month should be based of a water year; October -> 0; September -> 11
# * Paths need to be absolute for the parallel command to be able to find files
#
# Example call:
#   ./adjusted_dlwrf_for_topo.sh <YYYY> <MM> <DLWRF_in> <TAIR_in> <TOPO_FILE> <DLWRF_out>
#   ./adjusted_dlwrf_for_topo.sh 2021 "0 1 2" /path/to/DLWRF \
#                                             /path/to/TAIR \
#					      /path/to/topo \
#                                             /path/to/destination

export OMP_NUM_THREADS=4
export OMP_WAIT_POLICY=PASSIVE

if [[ -z "$1" ]]; then
  echo "Start year is required"
  exit 1
else
  export WATER_YEAR=$((${1} - 1))
fi
export WATER_START_MONTH=10

export DLWRF_IN=${3}
export TAIR_IN=${4}
export TOPO=${5}
export DLWRF_OUT=${6}
export DAY_MST="${DLWRF_OUT}/adjusted_dlwrf.UTC"

export CDO_COMMAND='cdo -z zip4 -O -s'
export HRRR_SELECT="-select,name=DLWRF"
export SMRF_SELECT="-select,name=air_temp"
export TOPO_SELECT="-select,name=sky_view_factor"
export ADJUSTED_SELECT="-select,name=thermal"

# Define constants for the topography-adjusted calculation
EMISS_SNOW=0.98
STEF_BOLTZ=5.6697e-8
FREEZE=273.16

export NET_MATH="thermal=(DLWRF*sky_view_factor) + (1.0 - sky_view_factor)*$EMISS_SNOW*$STEF_BOLTZ*(air_temp+$FREEZE)^4;"

# Merge by month to get one file per day starting at midnight UTC.
# The 6-hour forecast requires to add the last day of the previous month
function net_hrrr_for_month() {
  pushd "${DLWRF_OUT}" || exit

  CURRENT_MONTH=$(date -d "${WATER_START_MONTH}/01/${WATER_YEAR} + ${1} month")
  if [[ $? != 0 ]]; then
    exit 1
  fi
  MONTH=$(date -d "${CURRENT_MONTH}" +%m)
  MONTH_SELECTOR=$(date -d "${CURRENT_MONTH}" +%Y%m)
  
  echo "Processing: ${MONTH_SELECTOR}"
  echo "  Merge DLWRF month"
  DLWRF_MONTH_FILE="${DLWRF_OUT}/dlwrf.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} ${HRRR_SELECT} [ -mergetime ${DLWRF_IN}/*${MONTH_SELECTOR}* ] ${DLWRF_MONTH_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error merging HRRR month **"
    exit 1
  fi

  echo "  Merge TAIR month"
  TAIR_MONTH_FILE="${DLWRF_OUT}/tair.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} ${SMRF_SELECT} [ -mergetime ${TAIR_IN}/*${MONTH_SELECTOR}* ] ${TAIR_MONTH_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error getting TAIR **"
    exit 1
  fi

  echo "  Fetching sky-view factor"
  SVF_FILE="${DLWRF_OUT}/svf.nc"

  # Check if the Svf file already exists
  if [[ -f ${SVF_FILE} ]]; then
    echo "  Using existing sky-view factor "
  else
    echo "  Extracting sky-view factor from topo file "
    $CDO_COMMAND ${TOPO_SELECT} ${TOPO} ${SVF_FILE}

    if [[ $? != 0 ]]; then
      echo "  ** Error fetching sky-view factor **"
      exit 1
    fi
  fi

  echo "  Merge DLWRF, TAIR and Svf"
  MERGE_FILE="${DLWRF_OUT}/dlwrf_final.${MONTH_SELECTOR}.nc"
  $CDO_COMMAND merge -selmonth,${MONTH} ${TAIR_MONTH_FILE} -selmonth,${MONTH} ${DLWRF_MONTH_FILE} ${SVF_FILE} ${MERGE_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error merging DLWRF, TAIR and Svf **"
    exit 1
  fi
 
  echo "  Calculate topography-adjusted DLWRF"
  MONTH_CALC_FILE="${DLWRF_OUT}/adjusted_dlwrf.${MONTH_SELECTOR}.nc"
  ${CDO_COMMAND} -aexpr,"${NET_MATH}" ${MERGE_FILE} ${MONTH_CALC_FILE}

  if [[ $? != 0 ]]; then
    echo "  ** Error calculating topo-adjusted DLWRF **"
    exit 1
  fi

  echo "  Split by day UTC"
  ${CDO_COMMAND} splitday ${ADJUSTED_SELECT} ${MONTH_CALC_FILE} ${DAY_MST}.${MONTH_SELECTOR}

  if [[ $? != 0 ]]; then
    echo "  ** Error processing ${MONTH_SELECTOR} **"
  else
    rm ${DLWRF_MONTH_FILE}
    rm ${TAIR_MONTH_FILE}
    rm ${MERGE_FILE}
    rm ${SVF_FILE}
  fi
}

export -f net_hrrr_for_month
parallel --tagstring month-{} --line-buffer --jobs ${OMP_NUM_THREADS} net_hrrr_for_month ::: ${2}

