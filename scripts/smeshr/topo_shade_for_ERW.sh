#!/usr/bin/env bash
# Iterate over time range and calculate ERW topographic shading
#
# Arguments:
#   ./topo_shade_for_ERW.sh <TOPO> <OUTPUT_PATH_WITH_PREFIX> <start_date> <end_date>
# Sample call:
#   ./topo_shade_for_ERW.sh /path/to/topo "/write/to/here/file_prefix"
#

export PROCESSES=${SLURM_NTASKS:-4}

export TOPO_FILE=${1}
export NC_OUT_PREFIX=${2}

shade_for_day() {
  START=$1
  echo $START
  END=$(date -I -d "${START} + 1 day")
  topo_shade_for_day -t $TOPO_FILE \
                     -nc "${NC_OUT_PREFIX}_$(date -d $START +%Y%m%d).nc" \
                     -sd $START -ed $END
}

declare -a DATES=()

start=${3}
until [[ ${start} > ${4} ]]; do
  DATES+=("${start}")
  start=$(date -I -d "$start + 1 day")
done

export -f shade_for_day
parallel --jobs ${PROCESSES} shade_for_day ::: "${DATES[@]}"