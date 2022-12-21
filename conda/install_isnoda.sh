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

ISNODA_HOME=${1:-$HOME/isnoda}
mkdir -p ${ISNODA_HOME}

cd $ISNODA_HOME

######
# GitHub repositories
# Will install from source
######

declare -a repositories=(
  "https://github.com/UofU-Cryosphere/awsm.git"
  "https://github.com/UofU-Cryosphere/smrf.git"
  "https://github.com/USDA-ARS-NWRC/pysnobal.git"
  "https://github.com/UofU-Cryosphere/weather_forecast_retrieval.git"
)

# Make sure to use the conda installed GCC
export CC=$(which gcc)

for repository in "${repositories[@]}"
do
  IFS='/'; FOLDER=(${repository}) 
  IFS='.'; FOLDER=(${FOLDER[-1]})
  unset IFS;

  echo "Installing: ${FOLDER}"

  if [[ ! -d ${FOLDER} ]]; then
    git clone --depth 1 ${repository}
  fi

  pushd ${FOLDER}
  pip install -v --no-deps -e .
  popd
done

#######
# ISNOBAL components not available via conda package
#######

declare -a packages=(
  "inicheck"
  "spatialnc"
  "topocalc"
)

for package in "${packages[@]}"
do
  pip install --no-deps ${package}
done
