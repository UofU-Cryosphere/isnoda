#!/usr/bin/env bash
#
# Execute WindNinja_cli by itself (no katana wrapper)
#
# - ${1}: Directory with Topo
# - ${2}: HRRR input data home
# - ${3}: Output folder for SMRF to ingest it

ml singularity

export SINGULARITY_BIND="${1}:/data/topo,${2}:/data/input,${3}:/data/output"

singularity exec ${HOME}/project-data/iSnobal/katana/katana_jm.sif \
  WindNinja_cli /data/output/katana.ini
