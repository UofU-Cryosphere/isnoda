#!/usr/bin/env bash
#
# Quick check of GRIB files if they are readable with GDAL.
#
# Uses the first parameter for directory to check and moves unreadable
# files into a 'corrupt' directory.
#
# Example to check current directory:
#   ./check_bad_gribs.sh $(pwd)
#

for file in ${1}/*.grib2;
do
  origin=$(gdalinfo $file | grep Origin) 
  if [ $? -ne 0 ]; then
    destination="$(dirname $file)/corrupt/"
    mkdir -p $destination
    mv $file $destination
    echo $file
  fi
done
