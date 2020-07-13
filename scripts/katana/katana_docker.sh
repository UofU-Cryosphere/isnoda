#!/usr/bin/env bash

# Parameters:
# - ${1}: Directory with Topo
# - ${2}: HRRR input data home
# = ${3}: Output folder for SMRF to ingest it

docker run usdaarsnwrc/katana \
  --rm \
  -v ${1}:/data/topo \
  -v ${2}:/data/input \
  -v ${3}:/data/output \
  katana.ini
