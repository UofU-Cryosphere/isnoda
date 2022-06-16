#!/usr/bin/env bash

# Merge individual SMRF solar outputs into one netCDF file

CDO_MATH="\
ir_in = veg_ir_beam + veg_ir_diffuse;\
vis_in = veg_vis_beam + veg_vis_diffuse;\
ir_snow = (veg_ir_beam + veg_ir_diffuse) * (1 - albedo_ir);\
vis_snow = (veg_vis_beam + veg_vis_diffuse) * (1 - albedo_vis);\
sum_snow = ir_snow + vis_snow;\
"

# Merge SMRF outputs
cdo merge veg_*.nc albedo_*.nc cloud_factor.nc smrf_solar_out.nc

if [ $? != 0 ]; then
  printf "ERROR: Could not merge SMRF files"
  exit 1
fi

# Calculate components
cdo -P 4 expr,"${CDO_MATH}" smrf_solar_out.nc smrf_solar_sum.nc

if [ $? != 0 ]; then
  printf "ERROR: Could not calculate SMRF components"
  exit 1
fi

# Merge SMRF inputs and outputs
cdo -O -P 4 -z zip_4 merge smrf_solar_* smrf_solar.nc

if [ $? != 0 ]; then
  printf "ERROR: Could not merge final files"
  exit 1
fi

# Cleanup
rm veg_*.nc albedo_*.nc cloud_factor.nc smrf_solar_out.nc smrf_solar_sum.nc

