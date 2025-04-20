#!/usr/bin/env bash

# Run iSnobal for the first day of the simulation
# Usage: run_first_day.sh <config_file> <start_date>
# Example: run_first_day.sh /path/to/awsm.ini 2017-10-01

awsm_ini=$1
start=$2

# Run for given day. Date format: 2017-10-01 00:00
if [[ -n "$CONDA_DEFAULT_ENV" && "$CONDA_DEFAULT_ENV" == "isnoda" ]]; then
  echo "Conda environment 'isnoda' is active."
else
  echo "Conda environment 'isnoda' is not active, exiting script"
  exit 1
fi

# Initial run, no previous days
awsm -c ${awsm_ini} --start_date ${start} -np

