#!/usr/bin/env bash
# Check outputs of SMESHR to determine entry points prepare_MODIS_HRRR_inputs.sh
#
# Arguments:
#   ./check_smeshr_outputs.sh <BASIN> <WY>
# Sample call:
#   ./check_smeshr_outputs.sh yampa 2022

# Ensure correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Incorrect number of input parameters"
    echo "Usage: ./check_smeshr_outputs.sh <BASIN> <WY>"
    exit 1
fi
# Set variables
BASIN=$1
WY=$2

SMESHR_DIR=/uufs/chpc.utah.edu/common/home/skiles-group3/SMESHR/
ALBEDO_DIR=/uufs/chpc.utah.edu/common/home/skiles-group3/MODIS_albedo/

# Basin-specific directories
BASIN_SMESHR_DIR=${SMESHR_DIR}${BASIN}
TCDC_out=${BASIN_SMESHR_DIR}/TCDC_out
DSWRF_DIR=${BASIN_SMESHR_DIR}/DSWRF
NET_SOLAR_DIR=${BASIN_SMESHR_DIR}/net_HRRR_MODIS

# Check if SMESHR outputs exist for input basin and water year
# by checking for first and last day of water year files
LAST_DAY=${WY}0930
if [ ! -e ${TCDC_out}/tcdc.MST.${LAST_DAY}.nc ]; then
    echo "*************************************************************"
    echo "Last day of WY missing: ${TCDC_out}/tcdc.MST.${LAST_DAY}.nc"
    echo "for HRRR cloud cover outputs <TCDC_out> for ${BASIN} ${WY}"
    echo "Setting ENTRY_POINT to 0"
    echo "*************************************************************"
    export ENTRY_POINT=0
    exit 1
elif [ ! -e ${DSWRF_DIR}/hrrr.${LAST_DAY}.dswrf.nc ]; then
    echo "*************************************************************"
    echo "Last day of WY missing: ${DSWRF_DIR}/hrrr.${LAST_DAY}.nc"
    echo "for HRRR SW radiation outputs <DSWRF> for ${BASIN} ${WY}"
    # check for the last processed day of this water year, if it exists
    LAST_PROCESSED_DAY=$(ls -1 ${DSWRF_DIR}/hrrr.${WY}*dswrf.nc | tail -n 1)
    echo "Last processed day of this WY ${WY} is ${LAST_PROCESSED_DAY}"
    echo "Setting ENTRY_POINT to 1"
    echo "*************************************************************"
    export ENTRY_POINT=1
    exit 1
elif [ ! -e ${ALBEDO_DIR}/wy${WY}/westernUS_Terra_${LAST_DAY}_*albedo_${BASIN}_24.nc ]; then
    echo "*************************************************************"
    echo "Last day of WY missing: ${ALBEDO_DIR}/wy${WY}/westernUS_Terra_${LAST_DAY}_*_albedo_${BASIN}_24.nc"
    echo " for MODIS albedo outputs <ALBEDO_DIR> for ${BASIN} ${WY}"
    # check for the last processed day of this water year, if it exists
    LAST_PROCESSED_DAY=$(ls -1 ${ALBEDO_DIR}/wy${WY}/westernUS_Terra_${WY}*_albedo_${BASIN}_24.nc | tail -n 1)
    echo "Last processed day of this WY ${WY} is ${LAST_PROCESSED_DAY}"
    echo "Setting ENTRY_POINT to 2"
    echo "*************************************************************"
    export ENTRY_POINT=2
    exit 1
elif [ ! -e ${NET_SOLAR_DIR}/net_dswrf.MST.${LAST_DAY}.nc ]; then
    echo "*************************************************************"
    echo "Last day of WY missing for net solar merged outputs <net_HRRR_MODIS> for ${BASIN} ${WY}"
    # check for the last processed day of this water year, if it exists
    LAST_PROCESSED_DAY=$(ls -1 ${NET_SOLAR_DIR}/net_dswrf.MST.${WY}*.nc | tail -n 1)
    echo "Last processed day of this WY ${WY} is ${LAST_PROCESSED_DAY}"
    echo "Setting ENTRY_POINT to 3"
    echo "*************************************************************"
    export ENTRY_POINT=3
    exit 1
else
    BASIN_CAP=$(echo $BASIN | tr '[:lower:]' '[:upper:]')
    echo ""
    echo "All SMESHR outputs (and HRRR-MODIS modified inputs) found for"
    echo ""
    echo "                 == ${BASIN_CAP} WY ${WY} =="
    echo ""
    echo "$(ls ${TCDC_out}/tcdc.MST.${LAST_DAY}.nc)"
    echo "$(ls ${DSWRF_DIR}/hrrr.${LAST_DAY}.dswrf.nc)"
    echo "$(ls ${ALBEDO_DIR}/wy${WY}/westernUS_Terra_${LAST_DAY}_*albedo_${BASIN}_24.nc)"
    echo "$(ls ${NET_SOLAR_DIR}/net_dswrf.MST.${LAST_DAY}.nc)"
    echo ""
    echo ">>> Proceed to HRRR-MODIS first day runs <<<"
    echo ""
    echo ""
fi
# capitalize BASIN variable
