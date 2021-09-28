#!/usr/bin/env bash
# Convert docker to singularity
#  singularity build ars-nwrc-katana.sif docker://usdaarsnwrc/katana
#
# - ${1}: Basin setup directory with topo
# - ${2}: Path to HRRR input data
# - ${3}: Output folder for SMRF to ingest it

## Update these two variables with actual paths ##
KATANA_IMAGE=/path/to/katana.sif
KATANA_INI=/path/to/katana.ini
## ------------------------------ ##

ml singularity

export SINGULARITY_BIND="${1}:/data/topo,${2}:/data/input,${3}:/data/output"

singularity exec ${KATANA_IMAGE} run_katana ${KATANA_INI}
