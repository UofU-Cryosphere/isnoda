#!/usr/bin/env bash
# Script to install all required components from the USDA ARS NWRC
# GitHub repositories.
#
# These components are installed with the latest from the master branch:
#  - AWSM
#  - SMRF
#  - PySnobal
#  - Weather Forecast Retrieval
#  - IPW
#
# Other packages are installed via the latest available version as pip package.

set -e

ISNODA_HOME=${1:-$HOME/isnoda}
mkdir -p ${ISNODA_HOME}

cd $ISNODA_HOME

# Python based repositories
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
  "spatialnc"
)

for package in "${packages[@]}"
do
  pip install --no-deps ${package}
done

# IPW
git clone --depth 1 https://github.com/USDA-ARS-NWRC/ipw.git
pushd ipw

./configure
export IPW=`pwd`
export WORKDIR=${IPW}/tmp
make
make install

popd
