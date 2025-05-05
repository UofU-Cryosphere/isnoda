import copy
import glob
import os
from datetime import datetime, timedelta

import numpy as np
import math as m
from netCDF4 import Dataset
from topocalc.horizon import horizon

from snobedo.input import HrrrParameter
from snobedo.output import NetCDF
from snobedo.shortwave import TopoShade

# PROJ conda environ bug
os.environ['PROJ_LIB'] = '/uufs/chpc.utah.edu/common/home/skiles-group1/jmeyer/conda/envs/smeshr/share/proj'

## SPLITTING AND TOPOGRAPHIC FORCING FUNCTIONS

# load terrain parameters
def static_topo_vars(topo_file):
    # static topographic variables
    with Dataset(topo_file, 'r') as dem:
        sky_view_factor = dem['sky_view_factor'][:].astype(np.float64)
        dem = dem['dem'][:].astype(np.float64)
    # topographic variables
    topo_shade = TopoShade(
        topo_file, TopoShade.SolarMethods.SKYFIELD
    )
    return dem, sky_view_factor, topo_shade

# solar geom
def hrrr_solar_geom(hrrr_dswrf, topo_shade):
    """
    Calculate solar geometry for HRRR grib file and topo shade information
    """

    # DID NOT WORK
    # time range for solar angles
    # time_range = [
    #     hrrr_dswrf.timestep_for_band(10) + timedelta(hours=hour)
    #     for hour in range(0, 24)
    # ]
    # temporary
    hour = hrrr_dswrf.timestep_for_band(10)
    start_day = hour.strftime('%Y-%m-%d') 
    end_day = (hour + timedelta(days=1)).strftime('%Y-%m-%d')
    time_range = np.arange(str(start_day), str(end_day), np.timedelta64(1, 'h'), dtype='datetime64[s]')
    time_range = [datetime.fromisoformat(str(r)) for r in time_range]
    topo_shade.calculate(time_range)
    # # # #
    # calculate
    topo_shade.calculate(time_range)

    azimuth = {
        key.strftime('%Y-%m-%d %H:%M'): value
        for key, value in topo_shade.azimuth.items()
    }
    zenith = {
        key.strftime('%Y-%m-%d %H:%M'): value
        for key, value in topo_shade.zenith.items()
    }
    incidence = {
        key.strftime('%Y-%m-%d %H:%M'): value
        for key, value in topo_shade.illumination_angles.items()
    }
    # shading corrected incidence for a full day
    illumination = horizon_shader(topo_shade, zenith, incidence)

    # ADD flat DSW3 model for station comparison 
    cosZ = copy.deepcopy(illumination)
    for key in illumination:
        illum_val = illumination[key]
        zen_val = zenith[key]
    
        if isinstance(illum_val, (int, float)):
            # leave scalars of 0 to preserve shading, otherwise apply zenith angle
            if illum_val != 0:
                cosZ[key] = m.cos(m.radians(zen_val))
            continue
        if isinstance(illum_val, np.ndarray):
            if illum_val.shape == (1, 1):
                # check this section
                if illum_val[0, 0] != 0:
                    cosZ[key] = np.array([[zen_val]])
            else:
                # replace only non-zero values
                mask = illum_val != 0
                cosZ[key][mask] = np.cos(np.radians(zen_val))
        else:
            raise TypeError(f"Unexpected type for illumination[{key}]: {type(illum_val)}")

    del topo_shade

    return azimuth, zenith, incidence, illumination, cosZ


# for shade
def horizon_shader(topo_shade, zenith, illumination_angles):
    illumination_angles = copy.deepcopy(illumination_angles)
    horizon_angles = {
        key: horizon(value, topo_shade.topo.dem, topo_shade.topo.dx)
        for key, value in zenith.items()
    }
    for date, _val in zenith.items():
        if type(illumination_angles[date]) is np.ndarray:
            illumination_angles[date] = mask_sun(
                date, zenith, illumination_angles, horizon_angles
            )

    return illumination_angles

# shadows from horizon - Dozier
def mask_sun(date, zenith, inc_angles, horizon_angles):
    cos_z = np.cos(np.radians(zenith[date]))

    sun_angle = np.tan(np.pi / 2 - np.arccos(cos_z))
    no_sun_mask = (np.tan(np.abs(horizon_angles[date])) > sun_angle)
    inc_angles[date][no_sun_mask] = 0

    return inc_angles[date]

# topographic splitting models (4 total)
def toposplit(
    hrrr_dswrf, zenith, incidence_angles, illumination, cosZ, sky_view_factor
):
    """
    Topo models for HRRR
        Provides splitting method based on

    Returns:
        ghi  - global horizontal radiation (flat model)
        dsw1 - + illumination angle (inc)
        dsw2 - + inc + skyview (vf)
        dsw3 - + inc + vf + shading (COMPLETE)
        dsw3h - same as above but for pyranometer comparison

    """
    # define hour
    hour = hrrr_dswrf.timestep_for_band(10)
    hour = str(hour.strftime('%Y-%m-%d %H:%M'))

    # Check if sun is down
    if zenith[hour] == 0:
        # print("** Sun is down **")
        empty = np.zeros_like(sky_view_factor)
        return empty, empty, empty, empty, empty, empty

    # Warp once, then grab the bands
    hrrr_data = hrrr_dswrf.grib_file
    # DSWRF
    ghi = hrrr_data.GetRasterBand(10).ReadAsArray()
    # VBDSF - Visible Beam Downward Solar Flux
    direct_beam = hrrr_data.GetRasterBand(12).ReadAsArray()
    # VDDSF - Visible Diffuse Downward Solar Flux
    diffuse_beam = hrrr_data.GetRasterBand(13).ReadAsArray()

    # Early morning/late evening hours will have a zero or negative
    # (from interpolation) value in some pixels. Masking all calculations
    # where incoming is less than 1 W/m^2.
    # Also prevent division by zero for diffuse pixels with no values
    flux_mask = (ghi <= 1)
    ghi = np.where(flux_mask, 0, ghi)
    direct_mask = np.logical_or(flux_mask, direct_beam <= 1)
    direct_beam = np.where(direct_mask, 1, direct_beam)
    diffuse_mask = np.logical_or(flux_mask, diffuse_beam <= 1)
    diffuse_beam = np.where(diffuse_mask, 0, diffuse_beam)

    # print("  DSWRF mean: ", end='')
    # print(ghi.mean().round(2))

    ghi_vis = direct_beam * np.cos(np.radians(zenith[hour])) + diffuse_beam
    # print("  GHI vis: ", end='')
    # print(ghi_vis.mean().round(2))
    # print("    Direct: ", end='')
    # print(direct_beam.mean().round(2))
    # print("    Diffuse: ", end='')
    # print(diffuse_beam.mean().round(2))

    # Visible diffuse fraction
    k = diffuse_beam / ghi_vis
    # print("  K: ", end='')
    # print(k.mean().round(2))

    # Global diffuse fraction
    diffuse_g = ghi * k
    # Global direct
    direct_g = (ghi - diffuse_g) / np.cos(np.radians(zenith[hour]))

    ## Topo models
    # DSW1 - No cast shadows - no view factor
    dsw1 = direct_g * incidence_angles[hour] + diffuse_g
    # print("DSW1: ", end='')
    # print(dsw1.mean().round(2))

    # DSW2 - No cast shadows
    dsw2 = direct_g * incidence_angles[hour] + diffuse_g * sky_view_factor
    # print("DSW2: ", end='')
    # print(dsw2.mean().round(2))

    # DSW3 - Final model
    dsw3 = direct_g * illumination[hour] + diffuse_g * sky_view_factor
    # print("DSW3: ", end='')
    # print(dsw3.mean().round(2))
    
    # New final model on flat plane for pyranometer
    dsw3h = direct_g * cosZ[hour] + diffuse_g * sky_view_factor

    del hrrr_data
    return ghi, dsw1, dsw2, dsw3, dsw3h, k



# Single day
def toposplit_for_day(topo_file, hrrr_dir, resample_method='cubic'):
    """
    Runs toposplit on HRRR files for a full day (UTC)

    Args:
        :param topo_file: (str) Path to topo.nc
        :param hrrr_dir: (str) Path to HRRR folder (e.g., .../hrrr.20220301/)
        :param resample_method: (str) Resample method for HRRR grib file
    """
    dem, sky_view_factor, topo_shade = static_topo_vars(topo_file)

    # list of HRRR files for the day (UTC forecast 6)
    hrrr_files = sorted(
        glob.glob(
            os.path.join(hrrr_dir, 'hrrr.t*z.wrfsfcf06.grib2')
        )
    )

    if not hrrr_files:
        raise FileNotFoundError(f"No HRRR files found in {hrrr_dir}")

    # solar geometry once for day
    sample_dswrf = HrrrParameter(topo_file, hrrr_files[0])
    _azimuth, zenith, incidence_angles, illumination, cosZ = hrrr_solar_geom(
        sample_dswrf, topo_shade
    )

    # shape
    n_y, n_x = dem.shape
    n_t = len(hrrr_files)

    # time series arrays
    ghi_stack = np.zeros((n_t, n_y, n_x), dtype=np.float32)
    dsw1_stack = np.zeros_like(ghi_stack)
    dsw2_stack = np.zeros_like(ghi_stack)
    dsw3_stack = np.zeros_like(ghi_stack)
    dsw3h_stack = np.zeros_like(ghi_stack)
    k_stack = np.zeros_like(ghi_stack)
    time_list = []

    for i, file_path in enumerate(hrrr_files):
        try:
            hrrr_dswrf = HrrrParameter(topo_file, file_path, resample_method)
            hour = hrrr_dswrf.timestep_for_band(10)
            time_list.append(hour)

            # print(f" Processing {hour.strftime('%Y-%m-%d %H:%M')}")

            ghi, dsw1, dsw2, dsw3, dsw3h, k = toposplit(
                hrrr_dswrf,
                zenith,
                incidence_angles,
                illumination,
                cosZ,
                sky_view_factor
            )

            ghi_stack[i] = ghi
            dsw1_stack[i] = dsw1
            dsw2_stack[i] = dsw2
            dsw3_stack[i] = dsw3
            dsw3h_stack[i] = dsw3h
            k_stack[i] = k

            # print(f"[✓]")

        except Exception as e:
            print(f"[!] Error on {file_path}")
            raise e

    return ghi_stack, dsw1_stack, dsw2_stack, dsw3_stack, dsw3h_stack, k_stack, time_list

def write_nc(
    ghi_stack, 
    dsw1_stack, 
    dsw2_stack, 
    dsw3_stack, 
    dsw3h_stack,
    k_stack, 
    time_list, 
    out_path,
    topo_file
):
    with NetCDF.for_topo(out_path, topo_file) as outfile:
        for counter, timestep in enumerate(time_list):
            outfile[NetCDF.VARIABLE_TIME][counter] = NetCDF.date_to_number(
                timestep, outfile, counter == 0
            )

        for var in ['ghi', 'dsw1', 'dsw2', 'dsw3', 'dsw3h']:
            var = outfile.createVariable(
                var,
                'f4', ('time', 'y', 'x'), 
                zlib=True, complevel=4
            )
            var.setncattr('units', 'W/m^2')
            var.setncattr('missing_value', np.nan)

        outfile['ghi'][::] = ghi_stack
        outfile['ghi'].setncatts(
            {'description': 'HRRR DSWRF', 'source': 'HRRR Grib'}
        )
        outfile['dsw1'][::] = dsw1_stack
        outfile['dsw1'].setncatts(
            {'description': 'HRRR DSWRF - No cast shadows - no view factor'}
        )
        outfile['dsw2'][::] = dsw2_stack
        outfile['dsw2'].setncatts(
            {'description': 'HRRR DSWRF - No cast shadows'}
        )
        outfile['dsw3'][::] = dsw3_stack
        outfile['dsw3'].setncatts({'description': 'HRRR DSWRF - Final model'})

        outfile['dsw3h'][::] = dsw3h_stack
        outfile['dsw3h'].setncatts({'description': 'HRRR DSWRF - Final model horiz'})

        var = outfile.createVariable(
            'k',
            'f4', ('time', 'y', 'x'), 
            zlib=True, complevel=4
        )
        var.setncattr('units', 'None')
        var.setncatts(
            {'description': 'Fraction of diffuse/global in the visible'}
        )
        var.setncattr('missing_value', np.nan)
        var[::] = k_stack

        outfile.description = f'HRRR topographic split model'
        outfile.history = f'Created {datetime.now()}'
        outfile.source = 'HRRR model + custom topo-splitting'
