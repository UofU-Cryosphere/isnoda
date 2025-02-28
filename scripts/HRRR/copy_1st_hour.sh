#!/usr/bin/env bash
# Script to copy previous 2nd hour and make it the 1st for the following
#
# Example:
#   copy_1st_hour.sh hrrr.t09z.wrfsfcf02.grib2 hrrr.t10z.wrfsfcf01.grib2
#

SOURCE_FILE=$1
CREATED_FILE=$2
CREATED_HOUR=1

# Adjust datetime stamp and forecast time
wgrib2 -set_date +1hr -set_ftime "${CREATED_HOUR} hour fcst" ${SOURCE_FILE} -grib ${CREATED_FILE}

# Print to verify output
echo " ** Result **"
wgrib2 -s ${CREATED_FILE}
