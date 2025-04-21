#!/usr/bin/env bash
# Check outputs of TCDC to ensure 24 timesteps (in a day) are present
# Arguments:
#   ./check_tcdc_outputs.sh <date> <date_end>
# Sample call:
#   ./check_tcdc_outputs.sh 20201213 20200104

# Ensure correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Incorrect number of input parameters"
    echo "Usage: ./check_tcdc_outputs.sh DATE_START DATE_END"
    exit 1
fi

# Load the cdo module
ml cdo

# Function to check on number of timesteps
check_timesteps() {
    dt=$1
    # Count the number of timesteps in the TCDC file
    counted_timesteps=$(cdo infon tcdc.UTC.${dt}.nc | grep timesteps | cut -f13 -d " ")

    # Check if counted_timesteps variable is equivalent to 24
    if [ ${counted_timesteps} -eq 24 ]; then
        echo "24 timesteps found for ${dt} in $(pwd)"
    else
        echo "ERROR: ${counted_timesteps} timesteps found for ${dt} in $(pwd)"
        cdo infon tcdc.UTC.${dt}.nc
        # Note this date in a log file
        echo "${dt} ${counted_timesteps} timesteps found" >> missing_timesteps.log
    fi
}

# Single date check
if [ -z "$2" ]; then
    check_timesteps $1
else
    # Ensure the second date is greater than the first date
    if [ $1 -gt $2 ]; then
        echo "ERROR: Second date must be greater than the first date"
        exit 1
    fi
    # convert the first and second inputs into date format
    date1=$(date -d $1 +%Y%m%d)
    date2=$(date -d $2 +%Y%m%d)

    # Run through the date range sequentially
    while [ "$date1" -le "$date2" ]; do
        check_timesteps $date1
        date1=$(date -d "$date1 + 1 day" +%Y%m%d)
    done
fi
