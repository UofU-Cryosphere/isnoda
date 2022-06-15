#!/usr/bin/env bash

# Merge inidividual SMRF solar outputs into one netCDF file

CDO_MATH="\
ir_in = veg_ir_beam + veg_ir_diffuse;\
vis_in = veg_vis_beam + veg_vis_diffuse;\
ir_snow = (veg_ir_beam + veg_ir_diffuse) * (1 - albedo_ir);\
vis_snow = (veg_vis_beam + veg_vis_diffuse) * (1 - albedo_vis);\
sum_snow = ir_snow + vis_snow;\
"

# Merge SMRF outputs
cdo merge veg_*.nc albedo_*.nc cloud_factor.nc smrf_solar_out.nc

# Calculate components
cdo -P 4 expr,"${CDO_MATH}" smrf_solar_out.nc smrf_solar_sum.nc

# Merge SMRF inputs and outputs
cdo -O -P 4 -z zip_4 merge smrf_solar_* smrf_solar.nc

# Cleanup
rm veg_*.nc albedo_*.nc cloud_factor.nc smrf_solar_out.nc smrf_solar_sum.nc

