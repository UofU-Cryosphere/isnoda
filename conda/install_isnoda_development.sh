#!/usr/bin/env bash
# Script to install all required components from GitHub repositories for
# development. Requires to have a fully setup and activated conda environment.
#
# The below components are installed with the latest from the master branch:
#  - AWSM (University of Utah)
#  - SMRF (University of Utah)
#
# Install location is given via the first parameter or defaults to $HOME/iSnobal

set -e

ISNODA_HOME=${1:-$HOME/iSnobal}
mkdir -p ${ISNODA_HOME}

cd $ISNODA_HOME

######
# GitHub repositories
# Will install from source and editable
######

declare -a repositories=(
  "https://github.com/UofU-Cryosphere/awsm.git"
  "https://github.com/UofU-Cryosphere/smrf.git"
)

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
