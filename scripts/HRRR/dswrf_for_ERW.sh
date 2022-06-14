#!/usr/bin/env bash
# Combine DSWRF for a day and crop to ERW
#
# NOTE: First argument needs to bin quotes to prevent shell expansion
#
# Arguments:
#   ./dswrf_for_ERW.sh <TOPO> <FOLDER_PATTERN> <HRRR_FILE_PATTERN> <OUTPUT_PATH_WITH_PREFIX>
# Sample call:
#   ./dswrf_for_ERW.sh /path/to/topo "hrrr.YYYYMM*" "hrrr.t*.f06.grib2" "/write/to/here/file_prefix"
#

# For wgrib
export OMP_NUM_THREADS=${SLURM_NTASKS:-4}
export OMP_WAIT_POLICY=PASSIVE

export TOPO_FILE=${1}
export HRRR_PATTERN=${3}
export NC_OUT_PREFIX=${4}

combine_day() {
  DAY=$1
  echo $DAY
  pushd $DAY > /dev/null

  TMP_FILE="${DAY}_f06.grib2"

  cat ${HRRR_PATTERN} | wgrib2 - -match "DSWRF:surface" -grib $TMP_FILE

  dswrf_for_day --topo "${TOPO_FILE}" \
                --hrrr_in ${TMP_FILE} \
                --nc_out "${NC_OUT_PREFIX}_${DAY}.hrrr.dswrf.nc"

  rm $TMP_FILE
  popd > /dev/null
}

export -f combine_day
parallel --jobs ${OMP_NUM_THREADS} combine_day ::: ${2}

