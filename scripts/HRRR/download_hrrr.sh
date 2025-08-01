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

export HRRR_VARS='TMP:2 m|RH:2 m|DPT: 2 m|UGRD:10 m|VGRD:10 m|TCDC:|APCP:surface|DSWRF:surface|DLWRF:surface|HGT:surface'
export HRRR_FC_HOURS=(1 6)
export HRRR_DAY_HOURS=$(seq 0 23)

# Western United States from Denver West
export GRIB_AREA="-122.00:-105.00 32.00:49.00"
# Job control - the defaults require to have 32 CPUs for the job
## Number of jobs to download in parallel
PARALLEL_JOBS=16
## Number of Grib threads
export GRIB_THREADS="-ncpu 2"
## Log control
export LOG_OUTPUT="true"

# When adding a new archive, also add the variable to function:
#  check_alternate_archive
export UofU_ARCHIVE='UofU'
export AWS_ARCHIVE='AWS'
export Google_ARCHIVE='Google'
export Azure_ARCHIVE='Azure'

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
  elif [ $1 == ${Azure_ARCHIVE} ]; then
      export ARCHIVE_URL="https://noaahrrr.blob.core.windows.net/hrrr/hrrr.${HRRR_DAY}/conus/${FILE_NAME}"
  fi
}
export -f set_archive_url

check_file_in_archive() {
  set_archive_url $1
  STATUS_CODE=$(curl -s -o /dev/null -I -w "%{http_code}" ${ARCHIVE_URL})

  if [ "${STATUS_CODE}" == "404" ]; then
    >&2 printf "   missing\n"
    return 3
  fi

  >&2 printf "\n"
  unset ALT_DATE
  return 0
}
export -f check_file_in_archive

check_alternate_archive() {
    # If user inputs archive, update ARCHIVES to user input
    if [[ $1 == @($UofU_ARCHIVE|$AWS_ARCHIVE|$Google_ARCHIVE|$Azure_ARCHIVE) ]]; then
      ARCHIVES=($1)
     >&2 printf "  Input detected: $1"
    else
      ARCHIVES=($UofU_ARCHIVE $AWS_ARCHIVE $Google_ARCHIVE $Azure_ARCHIVE)
    fi

    >&2 printf "  Checking alternate archive: \n"
    for ALT_ARCHIVE in "${ARCHIVES[@]}"; do
      if [[ "${ALT_ARCHIVE}" == "${ARCHIVE}" ]]; then
        continue
      fi

      >&2 printf "   - ${ALT_ARCHIVE}"
      check_file_in_archive ${ALT_ARCHIVE}
      if [ $? -eq 0 ]; then
        return 0
      fi
    done

    unset ALT_DATE
    touch "${FILE_NAME}.missing"
    return 3
}
export -f check_alternate_archive

check_file_existence(){
  # Check for existing file on disk and that it is not zero in size
  if [[ -s "${FILE_NAME}" ]]; then
    if [[ "${1}" == "${LOG_OUTPUT}" ]]; then
      >&1 printf "  exists \n"
    fi
    exit 0
  fi
  return 3
}
export -f check_file_existence

get_grib_range(){
  INDEX_FILE="${1}.idx"
  RANGE_GREP="grep -A 1 -B 1 "

  INDEX_FILE=$(curl -s "${ARCHIVE_URL}.idx")

  export MIN_RANGE=$(echo "${INDEX_FILE}" | ${RANGE_GREP} -E "${HRRR_VARS}" | cut -d ":" -f 2 | head -n 1)
  export MAX_RANGE=$(echo "${INDEX_FILE}" | ${RANGE_GREP} -E "${HRRR_VARS}" | cut -d ":" -f 2 | tail -n 1)
}
export -f get_grib_range

download_hrrr() {
  DAY_HOUR=$1
  FC_HOUR=$2
  FILE_NAME="hrrr.t$(printf "%02d" $DAY_HOUR)z.wrfsfcf0${FC_HOUR}.grib2"

  printf "File: ${FILE_NAME} \n"

  # Clean up any old temporary pipes from previous runs
  find . -type p -name "${FILE_NAME}_tmp" -delete
  # Remove any previous downloads of empty grib files
  find . -type f -name ${FILE_NAME} -size 0 -delete
  # Remove any previously missing files in archives and try again
  find . -type f -name "${FILE_NAME}.missing" -size 0 -delete
 
  check_file_existence ${LOG_OUTPUT}

  check_file_in_archive ${ARCHIVE}

  if [[ $? -eq 3 ]]; then
    check_alternate_archive
  fi

  if [[ $? -eq 3 ]]; then
    >&2 printf "  ** Forecast hour ${FC_HOUR} not available **\n"

    # Try a previous hour of the day when getting either the F01 or F06 forecast
    if [[ ${FC_HOUR} -eq 1 ]] || [[ ${FC_HOUR} -eq 6 ]]; then
      NEW_DATE=$(date -u -d "${DATE} $(printf "%02d" $DAY_HOUR):00:00 1 hour ago" "+%Y%m%d%H")
      ALT_DATE=${NEW_DATE:0:-2}
      FILE_NAME="hrrr.t${NEW_DATE:(-2)}z.wrfsfcf0$(($FC_HOUR + 1)).grib2"

      >&2 printf "  ** Checking previous hour: hrrr.${ALT_DATE}/${FILE_NAME}"

      check_file_existence

      check_file_in_archive ${ARCHIVE}

      if [[ $? -eq 3 ]]; then
        check_alternate_archive

        if [[ $? -eq 3 ]]; then
          >&2 printf "  not available in previous hour\n"
          exit 0
        fi
      else
        >&2 printf "   found previous hour\n"
      fi
    else
      exit 0
    fi
  fi

  TMP_FILE="${FILE_NAME}_tmp"
  mkfifo $TMP_FILE

  # Reduce download size of GRIB file by requesting a specific range
  get_grib_range ${FILE_NAME}

  printf '\n'
  curl -s --range ${MIN_RANGE}-${MAX_RANGE} ${ARCHIVE_URL} -o $TMP_FILE | \
  wgrib2 $TMP_FILE -v0 ${GRIB_THREADS} -set_grib_type same -small_grib ${GRIB_AREA} - | \
  wgrib2 - -v0 ${GRIB_THREADS} -match "${HRRR_VARS}" -grib $FILE_NAME >&1
  rm $TMP_FILE

  # Check if the file was downloaded successfully and is not zero size
  check_file_existence

  # Handle zero size file
  if [[ $? -eq 3 ]]; then
    >&2 printf "File is zero size, checking alternate archives...\n"

    # Check alternate archives until downloaded file is no longer zero size
    # or all archives have been checked.
    ARCHIVES=($UofU_ARCHIVE $AWS_ARCHIVE $Google_ARCHIVE $Azure_ARCHIVE)
    for ALT_ARCHIVE in "${ARCHIVES[@]}"; do
      check_alternate_archive $ALT_ARCHIVE
      mkfifo $TMP_FILE
      if [[ $? -eq 0 ]]; then
        curl -s --range ${MIN_RANGE}-${MAX_RANGE} ${ARCHIVE_URL} -o $TMP_FILE | \
        wgrib2 $TMP_FILE -v0 ${GRIB_THREADS} -set_grib_type same -small_grib ${GRIB_AREA} - | \
        wgrib2 - -v0 ${GRIB_THREADS} -match "${HRRR_VARS}" -grib $FILE_NAME >&1
        find . -type f -name "${FILE_NAME}.missing" -size 0 -delete
        rm $TMP_FILE
        check_file_existence

        if [[ $? -eq 3 ]] ; then
            printf "  File is still zero size\n"
        fi
      fi
    done
  fi
  if [ $? -eq 0 ]; then
    >&1 printf " created \n"
  fi
}
export -f download_hrrr

# Parse the given user inputs
if [[ ! -z $2 ]] && [[ $2 != @($UofU_ARCHIVE|$AWS_ARCHIVE|$Google_ARCHIVE) ]]; then
  export YEAR=$1
  export MONTH=$(printf "%02d" "$2")
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
