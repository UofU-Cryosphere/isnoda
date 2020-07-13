#!/usr/bin/env bash
# Convert docker to singularity
#  singularity build ars-nwrc-katana.sif docker://usdaarsnwrc/katana
#
# - ${1}: Directory with Topo
# - ${2}: HRRR input data home
# - ${3}: Output folder for SMRF to ingest it

ml singularity

export SINGULARITY_BIND="${1}:/data/topo,${2}:/data/input,${3}:/data/output"

singularity exec ars-nwrc-katana.sif run_katana katana.ini
