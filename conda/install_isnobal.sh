#!/usr/bin/env bash

set -e

ISNOBAL_HOME=${1:-/usr/local/isnobal}
mkdir -p ${ISNOBAL_HOME}

cd $ISNOBAL_HOME

declare -a repositories=(
  "https://github.com/USDA-ARS-NWRC/awsm.git"
  "https://github.com/USDA-ARS-NWRC/smrf.git"
  "https://github.com/USDA-ARS-NWRC/pysnobal.git"
  "https://github.com/USDA-ARS-NWRC/weather_forecast_retrieval.git"
)

for repository in "${repositories[@]}"
do
  git clone --depth 1 ${repository}
done

for repository in $(find . -maxdepth 1 ! -path . -type d); do
  pushd ${repository}
  pip install --no-deps -e .
  popd
done

declare -a packages=(
  "inicheck"
  "PyKrige"
  "snowav"
  "spatialnc"
  "tablizer"
)

for package in "${packages[@]}"
do
  pip install --no-deps ${package}
done

