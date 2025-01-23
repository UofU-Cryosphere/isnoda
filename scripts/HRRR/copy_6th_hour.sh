#!/usr/bin/env bash
# Script to copy previous 7th hour and make it the 6th for the following
#
# Example:
#   copy_6th_hour.sh hrrr.t09z.wrfsfcf07.grib2 hrrr.t10z.wrfsfcf06.grib2
#

SOURCE_FILE=$1
CREATED_FILE=$2
CREATED_HOUR=6

# Grab non-precip fields
wgrib2 -match "HGT|TMP|RH|UGRD|VGRD|TCDC|DSWRF" -set_date +1hr -set_ftime "${CREATED_HOUR} hour fcst" ${SOURCE_FILE} -grib ${CREATED_FILE}_1
# Instant precip for hour
wgrib2 -match "APCP:surface:${CREATED_HOUR}" -set_date +1hr -set_ftime "5-${CREATED_HOUR} hour acc fcst" ${SOURCE_FILE} -grib ${CREATED_FILE}_2

# Concatenate
cat ${CREATED_FILE}_{1,2} > ${CREATED_FILE}

# Remove tmp files
rm ${CREATED_FILE}_{1,2}

# Print to verify output
echo " ** Result **"
wgrib2 -s ${CREATED_FILE}
