#!/usr/bin/env bash
#
# Cut ASO and iSnobal to shape
# Take the difference between the two
#
# Required parameters:
# $1: Date of comparison
# $2: Areal coverage map of ASO flight


DAY=${1}
COVERAGE_JSON=${2}

if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  echo "Date and coverage file are required params"
  exit 1
fi

WARP_MEM=2048
export GDAL_CACHEMAX=512

DIFFERENCE_DIR=/data/iSnobal/ASO-data/Depth-Difference

## SNOBAL ##
SNOBAL_50M=${DIFFERENCE_DIR}/Snobal_thickness_${DAY}_50m.tif

gdal_translate --optfile $GDAL_OPTS \
  NETCDF:"/data/iSnobal/erw_isnobal/run${DAY}/snow.nc":thickness \
  ${SNOBAL_50M}

## Up-sample to 1m ##
SNOBAL_1M=${DIFFERENCE_DIR}/Snobal_thickness_${DAY}_1m.tif
ASO_1M=${DIFFERENCE_DIR}/ASO_50M_SD_USCOGE_${DAY}_1m.tif

rm ${SNOBAL_1M} ${ASO_1M} 2> /dev/null

gdal_translate --optfile $GDAL_OPTS -tr 1 1 ${SNOBAL_50M} ${SNOBAL_1M}
 
gdal_translate --optfile $GDAL_OPTS -tr 1 1 \
  /data/iSnobal/ASO-data/Depth/ASO_50M_SD_USCOGE_${DAY}.tif \
  ${ASO_1M}

## Cut ##
SNOBAL_1M_C=${DIFFERENCE_DIR}/Snobal_thickness_${DAY}_1m_coverage.tif
ASO_1M_C=${DIFFERENCE_DIR}/ASO_50M_SD_USCOGE_${DAY}_1m_coverage.tif

gdalwarp --optfile $GDAL_OPTS -multi -overwrite \
  -wm ${WARP_MEM} \
  -cutline ${COVERAGE_JSON} -crop_to_cutline \
  ${SNOBAL_1M} \
  ${SNOBAL_1M_C}

gdalwarp --optfile $GDAL_OPTS -multi -overwrite \
  -wm ${WARP_MEM} \
  -cutline ${COVERAGE_JSON} -crop_to_cutline \
  ${ASO_1M} \
  ${ASO_1M_C}

## Difference ##
DIFF_FILE=${DIFFERENCE_DIR}/Depth_difference_${DAY}_1m.tif

rm ${DIFF_FILE} 2> /dev/null

gdal_calc.py --co="TILED=YES" --co="COMPRESS=LZW" --co="NUM_THREADS=ALL_CPUS"  \
  --calc="A-B" \
  -A ${ASO_1M_C} \
  -B ${SNOBAL_1M_C} \
  --outfile ${DIFF_FILE}\
