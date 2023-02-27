#!/usr/bin/env bash

modis_erw() {
  ERW_TMP=${1/\.tif/_ERW.tif}

  gdalwarp -overwrite -multi\
  --optfile $GDAL_OPTS \
  -ot Float32 \
  -t_srs EPSG:32613 -tr 50 50 -dstnodata -1\
  -te 315900.0 4280850.0 348700.0 4322700.0 \
  ${1} ${ERW_TMP}

  if [ $? != 0 ]; then
    printf "Error extracting domain from: \n   ${1}\n"
    return 1
  fi
}
export -f modis_erw
# parallel --tag --line-buffer --jobs ${SLURM_NTASKS} modis_erw ::: ${1}

resample_diff() {
  ERW_REF=${1}
  ERW_RESAMPLE=${1/\_ERW.tif/_bilinear.tif}

  gdal_calc.py --overwrite --co COMPRESS=ZSTD --co PREDICTOR=2 --co TILED=YES \
    -A $ERW_REF -B $ERW_RESAMPLE --calc="B-A" --outfile=${1/\_ERW.tif/_bilinear_diff.tif}
}
export -f resample_diff
parallel --tag --line-buffer --jobs ${SLURM_NTASKS} resample_diff ::: ${1}


