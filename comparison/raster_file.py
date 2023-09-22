import errno
import os

import numpy as np
from osgeo import gdal, gdal_array


class RasterFile(object):
    def __init__(self, filename, band_number=1):
        self.file = str(filename)
        self._band_number = band_number

        self._geotransform = None
        self._extent = None
        self._xy_meshgrid = None

    @property
    def file(self):
        return self._file

    @file.setter
    def file(self, filename):
        if os.path.exists(filename):
            self._file = gdal.Open(filename)
        else:
            raise FileNotFoundError(
                errno.ENOENT, os.strerror(errno.ENOENT), filename
            )

    @property
    def band_number(self):
        return self._band_number

    @band_number.setter
    def band_number(self, band_number):
        self._band_number = band_number

    @property
    def geo_transform(self):
        if self._geotransform is None:
            self._geotransform = self.file.GetGeoTransform()
        return self._geotransform

    @property
    def x_top_left(self):
        return self.geo_transform[0]

    @property
    def y_top_left(self):
        return self.geo_transform[3]

    @property
    def x_resolution(self):
        return self.geo_transform[1]

    @property
    def y_resolution(self):
        return self.geo_transform[5]

    @property
    def extent(self):
        if self._extent is None:
            x_bottom_right = \
                self.x_top_left + self.file.RasterXSize * self.x_resolution
            y_bottom_right = \
                self.y_top_left + self.file.RasterYSize * self.y_resolution

            self._extent = (
                self.x_top_left, x_bottom_right,
                self.y_top_left, y_bottom_right
            )
        return self._extent

    @property
    def xy_meshgrid(self):
        """
        Upper Left coordinate for each cell

        :return: Numpy meshgrid
        """
        if self._xy_meshgrid is None:
            x_size = self.file.RasterXSize
            y_size = self.file.RasterYSize
            self._xy_meshgrid = np.meshgrid(
                np.arange(
                    self.x_top_left,
                    self.x_top_left + x_size * self.x_resolution,
                    self.x_resolution,
                    dtype=np.half,
                ),
                np.arange(
                    self.y_top_left,
                    self.y_top_left + y_size * self.y_resolution,
                    self.y_resolution,
                    dtype=np.half,
                )
            )
        return self._xy_meshgrid

    def band_values(self, **kwargs):
        """
        Method to read band from arguments or from initialized raster.
        Will mask values defined in the band NoDataValue.

        :param kwargs:
            'band_number': band_number to read instead of the one given with
                           the initialize call.

        :return: Numpy masked array
        """
        band_number = kwargs.get('band_number', self.band_number)

        band = self.file.GetRasterBand(band_number)
        no_data = band.GetNoDataValue()
        values = np.ma.masked_values(
            gdal_array.BandReadAsArray(band),
            no_data if no_data is not None else np.nan,
            copy=False
        )

        del band
        return values
