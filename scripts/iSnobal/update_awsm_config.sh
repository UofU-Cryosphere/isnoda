#!/usr/bin/env bash

set -e

function display_help() {
    echo "Usage: $(basename $0) config.ini water_year basin_name [firstday_bool]"
    echo "Description: This script updates the config file."
    echo "Arguments:"
    echo "  config.ini: Path to the config file."
    echo "  water_year: Water year."
    echo "  basin_name: Name of the basin."
    echo "  firstday_bool: Optional boolean argument to edit config beyond first day run."
    echo
    echo "Example: $(basename $0) config.ini 2022 yahara false"
}

if [[ $1 == "--help" || $1 == "-h" ]]; then
    display_help
    exit 0
fi

if [ "$#" -lt 3 ] ; then
   echo "Missing input arguments: config.ini water_year basin_name [firstday_bool]" 
   exit 1
fi

# TODO
# improve comments and clarity
# Add handling for pickup restart - or create new script for restarts - edit init_file, storm_day_restart, and start_date
# Add handling for decay start and end dates
# Add handling for threads and cores used

inifile=$1
wy=$2
basin=$3
firstday=$4

res=100
outdir=.

echo
echo "Running $0 $1 $2 $3"
echo " from $(pwd)"
echo

function update_verbose()
{
    echo "          Formerly: $1"
    echo "          Now: $2"
    sed -i "s|${1}|${2}|g" $3 
    echo
}

updated_ini=${outdir}/${basin}_${res}m_awsm_${wy}.ini
if [ ! -e $updated_ini ] ; then
    echo "...Generating new ini: $updated_ini..." ; echo
    cp -pv $inifile $updated_ini
else
    echo "${updated_ini} exists, editing directly"
fi
echo

echo "...Editing topo.nc filepath..."
current=$(awk '/filename:/ {print $2}' $inifile)
start=$(dirname ${current%_s*})
#new=${start}/${basin}_setup/output_100m/topo.nc
new=${start}/${basin}_scripts/topo.nc

update_verbose $current $new $updated_ini

# # Not sure if this needs to be done anymore
# echo "...Editing model outputs path..."
# current=$(awk '/path_dr/ {print $2}' $inifile)
# echo "          Output path: $current"

echo "...Editing basin descriptions for $basin..."
current=$(awk '/basin:/ {print $2}' $inifile)
new=${basin}_${res}m_isnobal
update_verbose $current $new $updated_ini

echo "...Editing project_name..."
current=$(awk '/project_name:/ {print $2}' $inifile)
new=${basin}_basin_${res}m
update_verbose $current $new $updated_ini

echo "...Editing project_description..."
# need for handling multiple columns from space delimiter
yr=$(awk '/project_description:/ {print $NF}' $inifile)
current=$(echo "$(awk '/project_description:/ {print $2}' $inifile) water year ${yr}")
new=$(echo ${basin} water year ${wy})
# this func doesn't work for this one
# update_verbose ${current} ${new} ${updated_ini}
echo "          Formerly: $current"
echo "          Now: $new"
sed -i "s|${current}|${new}|g" $updated_ini 
echo

echo "...Edit wind_ninja directory path..."
current=$(awk '/wind_ninja_dir:/ {print $2}' $inifile)
new=$(dirname ${current})/${basin}_${res}m_katana/
update_verbose $current $new $updated_ini

startyear=$((${wy}-1))

if $firstday ; then
    echo "...Commenting out init_file and storm_days_restart..."
    sed -i 's/storm_days_restart/#storm_days_restart/g' $updated_ini 
    sed -i 's/init_file/#init_file/g' $updated_ini 
    
    echo "...Editing start and end dates for water year $wy..."
    current=$(awk '/start_date:/ {print $2}' $inifile)
    new=${startyear}-10-02
    update_verbose $current $new $updated_ini
    
    current=$(awk '/end_date:/ {print $2}' $inifile)
    new=${wy}-09-30
    update_verbose $current $new $updated_ini
    
else
    #TODO
    # echo     Updating decay start and end dates
    echo "...Uncommenting init_file and storm_days_restart..."
    sed -i 's/#storm_days_restart/storm_days_restart/g' $updated_ini 
    sed -i 's/#init_file/init_file/g' $updated_ini 
    
    echo "...Editing init_file and storm_days_restart..."
    current=$(awk '/init_file:/ {print $2}' $updated_ini)
    modeloutdir=$(awk '/path_dr/ {print $2}' $updated_ini)
    modeloutdir=${modeloutdir}/${basin}_${res}m_isnobal/wy${wy}/${basin}_basin_${res}m
    
    new=${modeloutdir}/run${startyear}1001/snow.nc
    update_verbose $current $new $updated_ini
    
    current=$(awk '/storm_days_restart:/ {print $2}' $updated_ini)
    new=${modeloutdir}/run${startyear}1001/storm_days.nc
    update_verbose $current $new $updated_ini
fi
echo
