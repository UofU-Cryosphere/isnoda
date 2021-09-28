#!/usr/bin/env bash
# Extract HRRR 6-hour precip forecast
#
# Script to extract HRRR precipitation forecast (APCP) for the 5-6 hour from
# the 6-hour forecast file. The result is renamed to the corresponding 1-hour
# forecast.
#
# Example:
#   6-hour forecast: hrrr.t00z.wrfsfcf06.grib2
#   Result: hrrr.t05z.wrfsfcf01.apcp06.grib2
#
# Usage:
# ~/extract_precip.sh path/to/HRRR/downloads/hrrr.*
#

# For wgrib
export OMP_NUM_THREADS=${SLURM_NTASKS:-4}
export OMP_WAIT_POLICY=PASSIVE


extract_apcp_fc06() {
  parallel --jobs ${OMP_NUM_THREADS} wgrib2 {} -match 'APCP:surface:5-6' -grib {.}.apcp.grib2 ::: $1
}

adjust_time() {
  APCP_FILE="apcp06.grib2"

  HRRR_FILE=$(readlink -f $1)
  if [ ! -s "${HRRR_FILE}" ]; then
    return
  fi
  TMP_FILE=${HRRR_FILE/grib2/$APCP_FILE}

#  printf "\nProcessing: ${HRRR_FILE}\n"
#  echo "  Filter to: ${TMP_FILE}"
  wgrib2 $1 -match 'APCP:surface:5-6' -set_date +5hr -set_ftime "0-1 hour acc fcst" -grib ${TMP_FILE} > /dev/null

  HRRR_DATETIME=$(wgrib2 -t ${TMP_FILE} | cut -d= -f2 | uniq)
  HRRR_DAY=${HRRR_DATETIME:0:-2}
  HRRR_HOUR=${HRRR_DATETIME:(-2)}

  DEST_FOLDER=$(dirname "$(dirname ${TMP_FILE})")
  mkdir -p "${DEST_FOLDER}/hrrr.${HRRR_DAY}"

  DEST_FILE="${DEST_FOLDER}/hrrr.${HRRR_DAY}/hrrr.t${HRRR_HOUR}z.wrfsfcf01.${APCP_FILE}"
#  echo "Moving to: ${DEST_FILE}"
  mv ${TMP_FILE} ${DEST_FILE}

  if [ "$HRRR_HOUR" == "23" ]; then
    printf "*";
  fi
}

export -f adjust_time
while [ ! -z "$1" ]; do
  parallel --jobs ${OMP_NUM_THREADS} adjust_time ::: ${1}/*wrfsfcf06.grib2
  shift
done

printf "\n\n"
