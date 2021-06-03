#!/usr/bin/env bash
#
# Run for given day. Date format: 2017-10-01 00:00

source load_conda_env isnoda

# Initial run, no previous days
awsm_daily_airflow -c ${HOME}/project-data/iSnobal/ERW/ERW_subset_awsm_$(date -d "${1} + 1 year" +%Y).ini \
  --no_previous \
  --start_date $1
