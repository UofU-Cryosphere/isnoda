import os
from datetime import datetime, timedelta
from pathlib import PurePath

import mat73
import numpy as np
from osgeo import gdal, gdalconst, gdalnumeric

MODIS_PROJECTION = '+proj=sinu +lon_0=0 +x_0=0 +y_0=0 ' \
                   '+a=6371007.181 +b=6371007.181 +units=m ' \
                   '+no_defs +nadgrids=@null +wktext'

BAND_DATA_TYPE = gdalconst.GDT_UInt16
BAND_NO_DATA_VALUE = 65535
BAND_NUMBER = 1

DRIVER = gdal.GetDriverByName('GTiff')
DRIVER_OPTS = [
    "COMPRESS=LZW",
    "TILED=YES",
    "BIGTIFF=IF_SAFER",
    "NUM_THREADS=ALL_CPUS"
]

HOME_DIR = PurePath(f"{os.environ['HOME']}/shared-cyrosphere")
DATA_DIR = HOME_DIR / 'Rittger_albedo'


def extract_albedo(date):
    year = date.year
    date = date.strftime('%Y%m%d')

    print(f"Processing: {date}")

    western_us_empty = gdal.Open(
        DATA_DIR.joinpath('WesternUS.tif').as_posix(),
    )

    albedo_dict = mat73.loadmat(
        DATA_DIR.joinpath(
            str(year),
            f"westernUS_Terra_{date}_mindays10_minthresh05_ndsimin0.00_zthresh08000800.mat"
        )
    )

    template = DRIVER.Create(
        DATA_DIR.joinpath(f"{year}-tif", f'WesternUS_{date}_albedo_muz.tif').as_posix(),
        western_us_empty.RasterXSize, western_us_empty.RasterYSize,
        BAND_NUMBER, BAND_DATA_TYPE,
        options=DRIVER_OPTS
    )

    template.SetGeoTransform(western_us_empty.GetGeoTransform())
    template.SetProjection(MODIS_PROJECTION)

    modis_band = template.GetRasterBand(BAND_NUMBER)
    modis_band.SetNoDataValue(BAND_NO_DATA_VALUE)

    gdalnumeric.BandWriteArray(
        modis_band,
        albedo_dict['albedo_observed_muZ']
    )

    modis_band.ComputeStatistics(0)
    modis_band.FlushCache()

    del modis_band, albedo_dict


if __name__ == '__main__':
    d0 = datetime(2020, 1, 1)
    d1 = datetime(2021, 1, 1)
    dt = timedelta(days=1)
    dates = np.arange(d0, d1, dt).astype(datetime)

    [extract_albedo(date) for date in dates]

