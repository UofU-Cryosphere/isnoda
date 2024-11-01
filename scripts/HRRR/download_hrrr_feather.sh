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
# by passing 'UofU' or Amazon with 'AWS'.

# Colorado Basin River bounding box from:
# https://www.sciencebase.gov/catalog/item/4f4e4a38e4b07f02db61cebb
#
# List days after a download, where there are not 48 files for a day:
# find -L . -name *.grib2 -type f | cut -d/ -f2 | uniq -c | grep -v '48 ' | tr -s ' ' | cut -d '.' -f 2
#

HRRR_VARS='TMP:2 m|RH:2 m|DPT: 2 m|UGRD:10 m|VGRD:10 m|TCDC:|APCP:surface|DSWRF:surface|HGT:surface'
HRRR_FC_HOURS=( 1 6 )

UofU_ARCHIVE='UofU'
AWS_ARCHIVE='AWS'
Google_ARCHIVE='Google'
ARCHIVES=($UofU_ARCHIVE $AWS_ARCHIVE $Google_ARCHIVE)

OMP_NUM_THREADS=${SLURM_NTASKS:-4}

set_archive_url() {
  if [[ ! -v ALT_DATE ]]; then
    local HRRR_DAY=${DATE}
  else
    local HRRR_DAY=${ALT_DATE}
  fi

  if [ $1 == ${UofU_ARCHIVE} ]; then
      ARCHIVE_URL="https://pando-rgw01.chpc.utah.edu/hrrr/sfc/${HRRR_DAY}/${FILE_NAME}"
  elif [ $1 == ${AWS_ARCHIVE} ]; then
      ARCHIVE_URL="https://noaa-hrrr-bdp-pds.s3.amazonaws.com/hrrr.${HRRR_DAY}/conus/${FILE_NAME}"
  elif [ $1 == ${Google_ARCHIVE} ]; then
      ARCHIVE_URL="https://storage.googleapis.com/high-resolution-rapid-refresh/hrrr.${HRRR_DAY}/conus/${FILE_NAME}"
  fi
}

check_file_in_archive() {
  set_archive_url $1
  STATUS_CODE=$(curl -s -o /dev/null -I -w "%{http_code}" ${ARCHIVE_URL})

  if [ "${STATUS_CODE}" == "404" ]; then
    >&2 printf " - missing on $1\n"
    return 1
  fi

  >&2 printf "\n"
  unset ALT_DATE
  return 0
}

check_alternate_archive() {
    for ALT_ARCHIVE in "${ARCHIVES[@]}"; do
      if [[ "${ALT_ARCHIVE}" == "${ARCHIVE}" ]]; then
        continue
      fi

      >&2 printf "    Checking alternate archive:"
      check_file_in_archive ${ALT_ARCHIVE}
      if [ $? -eq 0 ]; then
        return 0
      fi
    done

    unset ALT_DATE
    touch "${FILE_NAME}.missing"
    return 1
}

check_file_existence(){
  # Check for existing file and that it is not zero in size
  if [[ -s "${FILE_NAME}" ]]; then
    >&1 printf " exists \n"
    return 0
  elif [[ -e "${FILE_NAME}.missing" ]]; then
    >&1 printf " missing in archives \n"
    return 0
  fi
  return 1
}

if [[ ! -z $2 ]] && [[ $2 != @($UofU_ARCHIVE|$AWS_ARCHIVE|$Google_ARCHIVE) ]]; then
  YEAR=$1
  MONTH=$2
  LAST_DAY=$(date -d "${MONTH}/01/${YEAR} + 1 month - 1 day" +%d)

  DATES=($(seq -f "${YEAR}${MONTH}%02g" 1 $LAST_DAY))
else
  IFS=','
  DATES=($1)
fi

if [[ "$2" == "${UofU_ARCHIVE}" ]] || [[ "$3" == "${UofU_ARCHIVE}" ]]; then
  ARCHIVE=${UofU_ARCHIVE}
elif [[ "$2" == "${AWS_ARCHIVE}" ]] || [[ "$3" == "${AWS_ARCHIVE}" ]]; then
  ARCHIVE=${AWS_ARCHIVE}
else
  ARCHIVE=${Google_ARCHIVE}
fi

printf "Getting files from: ${ARCHIVE}\n"

for DATE in "${DATES[@]}"; do
  printf "Processing: $DATE\n"

  FOLDER="hrrr.${DATE}"
  mkdir -p $FOLDER
  pushd $FOLDER > /dev/null

  for DAY_HOUR in {0..23}; do
    for FC_HOUR in "${HRRR_FC_HOURS[@]}"; do
        FILE_NAME="hrrr.t$(printf "%02d" $DAY_HOUR)z.wrfsfcf0${FC_HOUR}.grib2"

        printf "  File: ${FILE_NAME}"

        check_file_existence
        if [[ $? -eq 0 ]]; then
          continue
        fi

        check_file_in_archive ${ARCHIVE}

        if [ $? -eq 1 ]; then
          check_alternate_archive
        fi

        if [ $? -eq 1 ]; then
          >&2 printf "  ** File not available **\n"

          # Try a previous hour of the day when getting the F06 forecast
          if [[ ${FC_HOUR} -eq 6 ]]; then
            NEW_DATE=$(date -u -d "${DATE} $(printf "%02d" $DAY_HOUR):00:00 1 hour ago" "+%Y%m%d%H")
            ALT_DATE=${NEW_DATE:0:-2}
            FILE_NAME="hrrr.t${NEW_DATE:(-2)}z.wrfsfcf0$(($FC_HOUR + 1)).grib2"

            >&2 printf "  ** Checking previous hour: hrrr.${ALT_DATE}/${FILE_NAME}"

            check_file_existence
            if [[ $? -eq 0 ]]; then
              unset ALT_DATE
              continue
            fi
            check_file_in_archive $ARCHIVE

            if [[ $? -eq 1 ]]; then
              check_alternate_archive

              if [[ $? -eq 1 ]]; then
                >&2 printf "  ** File not present in previous hour\n"
                continue
              fi
            fi
          else
            continue
          fi
        fi

        TMP_FILE="${FILE_NAME}_tmp"
        mkfifo $TMP_FILE

        printf '\n'
        wget -q --no-check-certificate ${ARCHIVE_URL} -O $TMP_FILE | \
        wgrib2 $TMP_FILE -v0 -ncpu ${OMP_NUM_THREADS} -set_grib_type same \
               -small_grib -121.591:-120.073 39.427:40.576 - | \
        wgrib2 - -v0 -ncpu ${OMP_NUM_THREADS} -match "$HRRR_VARS" \
               -grib $FILE_NAME >&1

        rm $TMP_FILE

        if [ $? -eq 0 ]; then
          >&1 printf " created \n"
        fi
    done
  done

  popd > /dev/null
done
