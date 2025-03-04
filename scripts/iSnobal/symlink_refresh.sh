#!/usr/bin/env bash
# Script Name: symlink_refresh.sh
# Author: J. Michelle Hu | University of Utah
# Date: 2.21.25
# Description: Symbolically links snow and em netcdf files from specified basins for wy2025
# Usage: ./symlink_refresh.sh <BASIN_NAME>

if [ "$#" -ne 1 ]; then
    echo 'Provide basin name as sole argument'
    exit 1
fi

basin=$1
for v in snow em
do
	for f in /uufs/chpc.utah.edu/common/home/skiles-group3/model_runs/${basin}_100m_isnobal/wy2025/${basin}_basin_100m/*/${v}.nc
	do
		echo ln -s $f ${basin}/$(basename $(dirname $f))_${v}.nc
		ln -s $f ${basin}/$(basename $(dirname $f))_${v}.nc
	done
done
