#!/usr/bin/env bash
# J. Michelle Hu
# University of Utah
# Feb 2025
# Script to compress the snow.nc and em.nc output files from iSnobal runs

set -e

function display_help() {
   echo "Usage: $(basename $0) <dirpath>"
   echo "Description: This script compresses the snow.nc and em.nc output files from iSnobal runs."
   echo "Arguments:"
   echo "  dir: Path to directory containing daily run folders. Defaults to current directory."
   echo
   echo "Example: $(basename $0) model_runs/animas_100m_isnobal/wy2021/animas_basin_100m/"
}
if [[ $1 == "--help" || $1 == "-h" ]]; then
   display_help
   exit 0
fi

ml cdo

# if no input detected, use current directory
if [ -z "$1" ]; then
	thisdir=./
else
	thisdir=$1
fi
for outvar in snow em
do
	parallel --plus --jobs 4 "echo cdo -P 4 -z zip_4 merge {} {/.nc/_c.nc} ; cdo -P 4 -z zip_4 merge {} {/.nc/_c.nc}" ::: "$thisdir"/run*/${outvar}.nc
	# Rename the compressed files to the original filename
	for f in "$thisdir"/run*/"${outvar}"_c.nc
	do
		echo mv "$f" "${f%_*}".nc
		mv "$f" "${f%_*}".nc
	done
done