#!/usr/bin/env bash
# Links air temperature values from SMRF to be used for DLWRF calculation.
#
# Arguments:
#  ./tair_linker.sh <BASIN_DIR> <OUTPUT_DIR>
#

export BASIN_DIR=${1}
export OUTPUT_DIR=${2}

echo $BASIN_DIR
echo $OUTPUT_DIR
# Loop through all "runYYYMMDD" folders in the basin folder
for dir in "${BASIN_DIR}"/run[0-9]*; do
    
    if [ -d "$dir" ]; then
        RUN_DATE=$(basename "$dir")
	SRC_FILE="$dir/air_temp.nc"
	OUT_FILE="${OUTPUT_DIR}/air_temp.${RUN_DATE}.MST.nc"

	if [ -f "${SRC_FILE}" ]; then
	   ln -s "${SRC_FILE}" "${OUT_FILE}"

	   echo "Processed: $SRC_FILE -> $OUT_FILE"
	else
	   echo "Warning: $SRC_FILE not found."
	fi
    fi
done
