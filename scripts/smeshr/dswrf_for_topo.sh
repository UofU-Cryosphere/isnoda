#!/usr/bin/env bash
# Extract DSWRF from given HRRR files for given topo extent
#
# NOTE: First argument needs to be in quotes to prevent shell expansion
#
# Arguments:
#   ./dswrf_for_topo.sh <TOPO> <FOLDER_PATTERN> <HRRR_FILE_PATTERN> <OUTPUT_PATH_WITH_PREFIX>
# Sample call:
#   ./dswrf_for_topo.sh /path/to/topo "hrrr.YYYYMM*" "hrrr.t*.f06.grib2" "/write/to/here/file_prefix"
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

  TMPF=$DAY.grib2
  cat ${HRRR_PATTERN} | wgrib2 - -match "DSWRF:surface" -inv /dev/null -grib $TMPF

  hrrr_param_for_topo --topo "${TOPO_FILE}" \
                      --hrrr_in $TMPF \
                      --nc_out "${NC_OUT_PREFIX}${DAY}.dswrf.nc" \
                      --add-shading

  rm $TMPF
  popd > /dev/null
}

export -f combine_day
parallel --tag --line-buffer --jobs ${OMP_NUM_THREADS} combine_day ::: ${2}
