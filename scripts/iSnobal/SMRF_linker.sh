#!/usr/bin/env bash
#
# Link files compacted via `smrf_compactor` for re-running the model
#

SMRF_FILES = (
    'air_temp.nc'
    'cloud_factor.nc'
    'percent_snow.nc'
    'precip_temp.nc'
    'snow_density.nc'
    'storm_days.nc'
    'thermal.nc'
    'vapor_pressure.nc'
    'wind_speed.nc'
)
SMRF_EB_FILES = (
    'net_solar.nc'
)

for FILE in ${SMRF_FILES}; do
  ln -s smrf_${$1}.nc ${FILE}
done

for FILE in ${SMRF_EB_FILES}; do
  ln -s smrf_energy_balance_${$1}.nc ${FILE}
done
