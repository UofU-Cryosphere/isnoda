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
set -e

export HRRR_VARS='TMP:2 m|RH:2 m|DPT: 2 m|UGRD:10 m|VGRD:10 m|TCDC:|APCP:surface|DSWRF:surface|HGT:surface'
export HRRR_FC_HOURS=(1 6)
export HRRR_DAY_HOURS=$(seq 0 23)

export GRIB_AREA="-112.322:-105.628 35.556:43.452"
# Job control - the defaults require to have 32 CPUs for the job
## Number of jobs to donwload in parallel
PARALLEL_JOBS=4
## Number of Grib threads
export GRIB_THREADS="-ncpu 8"

export UofU_ARCHIVE='UofU'
export AWS_ARCHIVE='AWS'
export Google_ARCHIVE='Google'
export ARCHIVES=($UofU_ARCHIVE $AWS_ARCHIVE $Google_ARCHIVE)

set_archive_url() {
  if [[ ! -v ALT_DATE ]]; then
    local HRRR_DAY=${DATE}
  else
    local HRRR_DAY=${ALT_DATE}
  fi

  if [ $1 == ${UofU_ARCHIVE} ]; then
      export ARCHIVE_URL="https://pando-rgw01.chpc.utah.edu/hrrr/sfc/${HRRR_DAY}/${FILE_NAME}"
  elif [ $1 == ${AWS_ARCHIVE} ]; then
      export ARCHIVE_URL="https://noaa-hrrr-bdp-pds.s3.amazonaws.com/hrrr.${HRRR_DAY}/conus/${FILE_NAME}"
  elif [ $1 == ${Google_ARCHIVE} ]; then
      export ARCHIVE_URL="https://storage.googleapis.com/high-resolution-rapid-refresh/hrrr.${HRRR_DAY}/conus/${FILE_NAME}"
  fi
}
export -f set_archive_url

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
export -f check_file_in_archive

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
export -f check_alternate_archive

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
export -f check_file_existence

download_hrrr() {
  DAY_HOUR=$1
  FC_HOUR=$2
  FILE_NAME="hrrr.t$(printf "%02d" $DAY_HOUR)z.wrfsfcf0${FC_HOUR}.grib2"

  printf "  File: ${FILE_NAME}"

  # Clean up any old temporary pipes from previous runs
  find . -type p -name "*_tmp" -delete
  # Remove any previous downloads of empty grib files
  find . -type f -name "*.grib2" -size 0 -delete

  check_file_existence
  if [[ $? -eq 0 ]]; then
    return
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
        return
      fi
      check_file_in_archive $ARCHIVE

      if [[ $? -eq 1 ]]; then
        check_alternate_archive

        if [[ $? -eq 1 ]]; then
          >&2 printf "  ** File not present in previous hour\n"
          return
        fi
      fi
    else
      return
    fi
  fi

  TMP_FILE="${FILE_NAME}_tmp"
  mkfifo $TMP_FILE

  printf '\n'
  wget -q --no-check-certificate ${ARCHIVE_URL} -O $TMP_FILE | \
  wgrib2 $TMP_FILE -v0 ${GRIB_THREADS} -set_grib_type same -small_grib ${GRIB_AREA} - | \
  wgrib2 - -v0 ${GRIB_THREADS} -match "$HRRR_VARS" -grib $FILE_NAME >&1

  rm $TMP_FILE

  if [ $? -eq 0 ]; then
    >&1 printf " created \n"
  fi
}
export -f download_hrrr

# Parse the given user inputs
if [[ ! -z $2 ]] && [[ $2 != @($UofU_ARCHIVE|$AWS_ARCHIVE|$Google_ARCHIVE) ]]; then
  export YEAR=$1
  export MONTH=$2
  export LAST_DAY=$(date -d "${MONTH}/01/${YEAR} + 1 month - 1 day" +%d)

  export DATES=($(seq -f "${YEAR}${MONTH}%02g" 1 $LAST_DAY))
else
  IFS=','
  export DATES=($1)
fi

# Set the archive
if [[ "$2" == "${UofU_ARCHIVE}" ]] || [[ "$3" == "${UofU_ARCHIVE}" ]]; then
  export ARCHIVE=${UofU_ARCHIVE}
elif [[ "$2" == "${AWS_ARCHIVE}" ]] || [[ "$3" == "${AWS_ARCHIVE}" ]]; then
  export ARCHIVE=${AWS_ARCHIVE}
else
  export ARCHIVE=${Google_ARCHIVE}
fi

printf "Getting files from: ${ARCHIVE}\n"

# Get the data
for DATE in "${DATES[@]}"; do
  printf "Processing: $DATE\n"
  export DATE=${DATE}

  FOLDER="hrrr.${DATE}"
  mkdir -p $FOLDER
  pushd $FOLDER > /dev/null

  parallel --tag --line-buffer --jobs ${PARALLEL_JOBS} download_hrrr ::: ${HRRR_DAY_HOURS} ::: "${HRRR_FC_HOURS[@]}"

  popd > /dev/null
done
