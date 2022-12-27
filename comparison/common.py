import dask
import numpy as np
import pandas as pd
import xarray as xr

import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.patches as mpatches
import matplotlib.font_manager as font_manager

import holoviews as hv
from holoviews import dim, opts
from pathlib import Path

from pathlib import Path, PurePath

from snobedo.lib.dask_utils import start_cluster, client_ip_and_port
from snobedo.snotel import SnotelLocations

from raster_file import RasterFile

SHARED_STORE = PurePath('/uufs/chpc.utah.edu/common/home/skiles-group1')
DATA_DIR = SHARED_STORE.joinpath('jmeyer')

HRRR_DIR = SHARED_STORE.joinpath('HRRR_water_years')
SNOBAL_DIR = SHARED_STORE.joinpath('erw_isnobal')
MODIS_DIR = SHARED_STORE.joinpath('MODIS_albedo')

ASO_DIR = DATA_DIR.joinpath('ASO-data')
CBRFC_DIR = DATA_DIR.joinpath('CBRFC')
SNOTEL_DIR = DATA_DIR.joinpath( 'Snotel')
FIGURES_DIR = DATA_DIR.joinpath('figures')

# Plot styles
BOKEH_FONT = dict(
    fontsize={
        'title': 24,
        'labels': 24,
        'xlabel': 24,
        'ylabel': 24,
        'xticks': 20,
        'yticks': 20,
        'legend': 24,
    }
)
HV_PLOT_OPTS = dict(
    width=1200,
    height=600,
)
LINE_STYLE = dict(
    line_width=2
)
LEGEND_OPTS = dict(
    legend_position='top_left',
    legend_opts={ 'glyph_width':35 },
    legend_spacing=10,
    legend_padding=30,
)

# Xarray options
# Used in comparison to SNOTEL site locations
COARSEN_OPTS = dict(x=2, y=2)
RESAMPLE_1_DAY_OPTS = dict(time='1D', base=23)

## CBRFC zones
# Corresponds to values in classification tif
ALEC2HLF = 1
ALEC2HMF = 2
ALEC2HUF = 3

# CBRFC values are deliverd in inches
INCH_TO_MM = 25.4

def aspect_classes():
    aspects = RasterFile(DATA_DIR / 'project-data/iSnobal/ERW/aspect_class_ERW.tif')
    aspects_data = aspects.band_values()

    return aspects_data

def cbrfc_zones():
    zones = RasterFile(CBRFC_DIR / 'ERW_CBRFC_zones.tif')
    zone_data = zones.band_values()
    zone_data[zone_data==241] = 0

    return zone_data

# HRRR helpers
def hrrr_pixel_index(hrrr_file, site):
    x_index = np.abs(hrrr_file.longitude.values - hrrr_longitude(site.lon))
    y_index = np.abs(hrrr_file.latitude.values - site.lat)
    return np.unravel_index((x_index + y_index).argmin(), x_index.shape)

def hrrr_longitude(longitude):
    return longitude % 360

@dask.delayed
def hrrr_snotel_pixel(file, x_pixel_index, y_pixel_index):
    """
    Read GRIB file surface values, remove unsed dimensions, and
    set the time dimension.

    Required to be able to concatenate all GRIB file to a time series
    """
    hrrr_file = xr.open_dataset(
        file.as_posix(),
        engine='cfgrib',
        backend_kwargs={
            'errors': 'ignore',
            'indexpath': '',
            'filter_by_keys': {
                'level': 0,
                'typeOfLevel': 'surface',
            }
        },
    ).isel(x=[x_pixel_index], y=[y_pixel_index])
    del hrrr_file.coords['valid_time']
    del hrrr_file.coords['surface']
    del hrrr_file.coords['step']

    return hrrr_file.expand_dims(time=[hrrr_file.time.values])


# Plot settings and helpers
plt.rcParams.update(
    {
        'axes.labelsize': 10
    }
)

LEGEND_TEXT = "{0:10} {1:8}"
LEGEND_DATE = "%Y-%m-%d"


def legend_text(label, value, color='none'):
    return mpatches.Patch(
        color=color, label=LEGEND_TEXT.format(label, value)
    )


def add_legend_box(ax, entries):
    ax.legend(
        handles=entries,
        loc='upper left',
        prop=font_manager.FontProperties(
            family='monospace', style='normal', size=8
        ),
    )

## Use hvplot
def use_hvplot():
    import hvplot.xarray
    import hvplot.pandas
    pd.options.plotting.backend = 'holoviews'
