#!/usr/bin/env bash
# Iterate over time range and calculate ERW topographic shading
#
# Arguments:
#   ./SMRF_merge_solar.sh <TOPO> SMRF_DAY_OUTPUT
# Sample call:
#   ./SMRF_merge_solar.sh "/path/to/smrf/output"
#

export PROCESSES=${SLURM_NTASKS:-4}

solar_for_day() {
  echo $1
  pushd $1 || exit
  ~/isnoda/scripts/smeshr/CDO_smrf.sh
  popd
}

export -f solar_for_day
parallel --jobs ${PROCESSES} solar_for_day ::: ${1}
