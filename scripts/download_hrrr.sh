#!/usr/bin/env bash
# Download HRRR data from CHPC hosted Pando archive.
# Can either be given two arguments for year and month:
# ./download_hrrr.sh YYYY MM
# or will loop over dates set on line 19 with no arguments given.

# Colorado Basin River bounding box from:
# https://www.sciencebase.gov/catalog/item/4f4e4a38e4b07f02db61cebb

HRRR_VARS='TMP:2 m|RH:2 m|DPT: 2 m|UGRD:10 m|VGRD:10 m|TCDC:|APCP:surface|DSWRF:surface|HGT:surface'

if [ ! -z "$1" ] && [ ! -z "$2" ]; then
  YEAR=$1
  MONTH=$2
  LAST_DAY=$(date -d "${MONTH}/01/${YEAR} + 1 month - 1 day" +%d)

  DATES=($(seq -f "${YEAR}${MONTH}%02g" 1 $LAST_DAY))
else
  declare -a DATES=(
  )
fi

for DATE in "${DATES[@]}"; do
  printf "Processing: $DATE\n"

  FOLDER="hrrr.${DATE}"
  mkdir -p $FOLDER
  pushd $FOLDER

  for HOUR in {0..23}; do
    for FIELD in {0..1}; do
        FILE_NAME="hrrr.t$(printf "%02d" $HOUR)z.wrfsfcf0${FIELD}.grib2"

        wget -nv --no-check-certificate "https://pando-rgw01.chpc.utah.edu/hrrr/sfc/${DATE}/${FILE_NAME}" -O - | \
        wgrib2 - -v0 -ncpu ${SLURM_NTASKS} -small_grib -112.322:-105.628 35.556:43.452 -| \
        wgrib2 - -v0 -ncpu ${SLURM_NTASKS} -match "$HRRR_VARS" -GRIB $FILE_NAME | \

        printf "${FILE_NAME} created \n"
    done
  done

  popd
done
