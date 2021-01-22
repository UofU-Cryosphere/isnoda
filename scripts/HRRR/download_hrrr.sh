#!/usr/bin/env bash
# Download HRRR data
#
# Can either be given two arguments for year and month:
#   ./download_hrrr.sh YYYY MM (Archive)
# or loop over the dates given as one argument separated by comma.
#   ./download_hrrr.sh YYYYMMDD,YYYYMMDD (Archive)
#
# The third is optional and can specify the archive source. Default
# is to get from Google and can be changed to the University of Utah by
# by passing 'UofU'.

# Colorado Basin River bounding box from:
# https://www.sciencebase.gov/catalog/item/4f4e4a38e4b07f02db61cebb

HRRR_VARS='TMP:2 m|RH:2 m|DPT: 2 m|UGRD:10 m|VGRD:10 m|TCDC:|APCP:surface|DSWRF:surface|HGT:surface'
UofU_ARCHIVE='UofU'

set_archive_url() {
  if [ $1 == 'UofU' ]; then
      ARCHIVE_URL="https://pando-rgw01.chpc.utah.edu/hrrr/sfc/${DATE}/${FILE_NAME}"
  elif [ $1 == 'Google' ]; then
      ARCHIVE_URL="https://storage.googleapis.com/high-resolution-rapid-refresh/hrrr.${DATE}/conus/${FILE_NAME}"
  fi
}

if [ ! -z "$1" ] && [ ! -z "$2" ] && [[ $2 != $UofU_ARCHIVE ]]; then
  YEAR=$1
  MONTH=$2
  LAST_DAY=$(date -d "${MONTH}/01/${YEAR} + 1 month - 1 day" +%d)

  DATES=($(seq -f "${YEAR}${MONTH}%02g" 1 $LAST_DAY))
else
  IFS=','
  DATES=($1)
fi

if [ ! -z "$3" ] || [[ $2 = $UofU_ARCHIVE ]]; then
  ARCHIVE=$UofU_ARCHIVE
else
  ARCHIVE='Google'
fi

printf "Getting files from: ${ARCHIVE}\n"

for DATE in "${DATES[@]}"; do
  printf "Processing: $DATE\n"

  FOLDER="hrrr.${DATE}"
  mkdir -p $FOLDER
  pushd $FOLDER

  for HOUR in {0..23}; do
    for FIELD in {0..1}; do
        FILE_NAME="hrrr.t$(printf "%02d" $HOUR)z.wrfsfcf0${FIELD}.grib2"

        TMP_FILE="${FILE_NAME}_tmp"
        mkfifo $TMP_FILE

        set_archive_url ${ARCHIVE}
        wget -nv --no-check-certificate ${ARCHIVE_URL} -O $TMP_FILE | \
        wgrib2 $TMP_FILE -v0 -ncpu ${SLURM_NTASKS} -small_grib -112.322:-105.628 35.556:43.452 - | \
        wgrib2 - -v0 -ncpu ${SLURM_NTASKS} -match "$HRRR_VARS" -grib $FILE_NAME

        rm $TMP_FILE

        printf "$URL"

        printf "${FILE_NAME} created \n"
    done
  done

  popd
done
