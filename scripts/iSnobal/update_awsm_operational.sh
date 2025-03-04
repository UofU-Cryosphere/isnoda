#!/usr/bin/env bash

set -e

function display_help() {
    echo "Usage: $(basename $0) config.ini start_date days_to_run"
    echo "Description: This script updates the config file to run an input number of days from a certain date"
    echo "Arguments:"
    echo "  config.ini: Path to the config file."
    echo "  start_date: Date in YYYYMMDD format"
    echo "  days_to_run: Number of days to run, including start date and end date."
    echo
    echo "Example: $(basename $0) yahara_100m_awsm_2025.ini 20250214 7"
}

if [[ $1 == "--help" || $1 == "-h" ]]; then
    display_help
    exit 0
fi

if [ "$#" -lt 3 ] ; then
   echo "Missing input arguments: config.ini start_date days_to_run"
   exit 1
fi

# TODO
# improve comments and clarity
# Add handling for pickup restart - or create new script for restarts - edit init_file, storm_day_restart, and start_date
# Add handling for decay start and end dates
# Add handling for threads and cores used

inifile=$1
startdate=$2
days=$3
res=100
#TODO
# echo     Updating decay start and end dates


echo
echo "Running $0 $1 $2 $3"
echo " from $(pwd)"
echo

function update_verbose()
{
    echo "          Was: $1"
    echo "          Now: $2"
    sed -i "s|${1}|${2}|g" "$3"
    echo
}

if [ ! -e "$inifile" ] ; then
    echo "Cannot find ini to update"
    exit 1
else
    echo "Editing ${inifile}"
fi
echo

# Pull relevant info from config file
basin=$(basename ${inifile%%_"${res}"m*})
f=${inifile##*awsm_}
wy=${f%%_*}

# Update end date
echo "...Editing end dates for $inifile..."
current=$(awk '/end_date:/ {print $2}' "$inifile")
new=$(date -d "$startdate + ${days} days" +%Y-%m-%d)
update_verbose "$current" "$new" "$inifile"

# Update start date in config file
echo "...Editing start dates for $inifile..."
current=$(awk '/start_date:/ {print $2}' "$inifile")
new=$(date -d "$startdate" +%Y-%m-%d)
update_verbose "$current" "$new" "$inifile"

# Update init file
echo "...Editing init_file..."
current=$(awk '/init_file:/ {print $2}' "$inifile")
#modeloutdir=$(awk '/path_dr/ {print $2}' "$inifile")
modeloutdir=/uufs/chpc.utah.edu/common/home/skiles-group3/model_runs/${basin}_${res}m_isnobal/wy${wy}/${basin}_basin_${res}m

new=${modeloutdir}/run$(date -d "$startdate - 1 days" +%Y%m%d)/snow.nc
update_verbose "$current" "$new" "$inifile"

# Update storm day restart file
echo "...Editing storm_days_restart..."
current=$(awk '/storm_days_restart:/ {print $2}' "$inifile")
new=${modeloutdir}/run$(date -d "$startdate - 1 days" +%Y%m%d)/storm_days.nc
update_verbose "$current" "$new" "$inifile"

# Uncomments init and storm day restart if they are commented out (only removes one #)
sed -i 's/#init_file:/init_file:/g' "$inifile"
sed -i 's/#storm_days_restart:/storm_days_restart:/g' "$inifile"
echo