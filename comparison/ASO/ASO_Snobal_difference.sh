#!/usr/bin/env bash
#
# Translate ASO to the iSnobal grid
# Take the difference by subtracting iSnobal from ASO
#
# Required parameters:
# $1: Date (YYYMMMDD)


if [[ -z "$1" ]]; then
  echo "Date is a required parameter"
  exit 1
else
  DAY=${1}
fi

WARP_MEM=2048
export GDAL_CACHEMAX=512

SNOBAL_HOME="/data/iSnobal"
DIFFERENCE_DIR="${SNOBAL_HOME}/ASO-data/Depth-Difference"

## Convert iSNOBAL netcdf to tif ##
SNOBAL_50M=${DIFFERENCE_DIR}/Snobal_thickness_${DAY}_50m.tif

gdal_translate --optfile $GDAL_OPTS \
  NETCDF:"${SNOBAL_HOME}/erw_isnobal/ASO-compare-F06/run${DAY}/snow.nc":thickness \
  ${SNOBAL_50M}

## Translate ASO ##
ASO_50M=${SNOBAL_HOME}/ASO-data/Depth/ASO_50M_SD_USCOGE_${DAY}.tif
ASO_50M_SG=${DIFFERENCE_DIR}/ASO_50M_SD_USCOGE_${DAY}_iSnobal_grid.tif

rm ${ASO_1M} 2> /dev/null

gdal_translate --optfile $GDAL_OPTS \
               -projwin 315900.00 4322700.00 348700.00 4280850.00 \
               -tr 50 50 -r average \
               ${ASO_50M} ${ASO_50M_SG}

## Difference ##
DIFF_FILE=${DIFFERENCE_DIR}/Depth_difference_${DAY}_50m.tif

rm ${DIFF_FILE} 2> /dev/null

gdal_calc.py --co="TILED=YES" --co="COMPRESS=LZW" --co="NUM_THREADS=ALL_CPUS"  \
  --calc="A-B" \
  -A ${ASO_50M_SG} \
  -B ${SNOBAL_50M} \
  --outfile ${DIFF_FILE}