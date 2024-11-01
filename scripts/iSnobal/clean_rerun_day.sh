#!/usr/bin/env bash
# Removes output variables for a given day based on input config.ini
# Usage: clean_rerun_day.sh /path/to/config.ini /path/to/runYYYYMMDD 
configini=$1
daytoclean=$2

outvars=$(echo $(grep variables: ${configini} | cut -d ":" -f2- | cut -d "," -f1- --output-delimiter=" "))

echo ${daytoclean}
for v in ${outvars[@]}
do
	echo "${v}.nc"
	rm ${daytoclean}/${v}.nc
done

# remove the snow state and energy balance files
echo "Removing snow.nc and em.nc..."
rm ${daytoclean}/snow.nc ${daytoclean}/em.nc

# also remove the logs directory
echo "rm -r ${daytoclean}/logs"
rm -r ${daytoclean}/logs
