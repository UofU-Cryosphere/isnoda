#!/usr/bin/env bash
# Script to install all required components from the USDA ARS NWRC
# GitHub repositories.
#
# These components are installed with the latest from the master branch:
#  - AWSM
#  - SMRF
#  - PySnobal
#  - Weather Forecast Retrieval
#
# Other packages are installed via the latest available version as pip package.

set -e

ISNOBAL_HOME=${1:-$HOME/isnobal}
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
  pip install -v --no-deps -e .
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
