from datetime import datetime, timezone
from osgeo import gdal, osr

from snobedo.output import NetCDF


class HrrrParameter:
    VSISTDIN = '/vsistdin/'
    MEM_TIFF = '/vsimem/grib.tif'

    def __init__(self, topo_file_path, grib_file_path=None):
        self._topo_file = topo_file_path
        self.grib_file = grib_file_path
        self._time_range = []

    @property
    def grib_file(self):
        return self._grib_file

    @grib_file.setter
    def grib_file(self, grib_file=None):
        if grib_file is None:
            grib_file = self.VSISTDIN

        self._grib_file = self.gdal_warp_and_cut(grib_file)

    @property
    def bands_from_grib_file(self):
        return range(1, self.grib_file.RasterCount + 1)

    @property
    def time_range(self):
        """
        Get all forecasted hours as Datetime for given grib file.

        :return: Array with Datetime objects
        """
        if len(self._time_range) == 0:
            for band in self.bands_from_grib_file:
                self._time_range.append(self.timestep_for_band(band))
        return self._time_range

    @staticmethod
    def gdal_osr_authority(spatial_info):
        return f'{spatial_info.GetAuthorityName(None)}' \
               f':{spatial_info.GetAuthorityCode(None)}'

    @staticmethod
    def gdal_output_bounds(topo):
        geo_transform = topo.GetGeoTransform()
        return [
            geo_transform[0],
            geo_transform[3] + geo_transform[5] * topo.RasterYSize,
            geo_transform[0] + geo_transform[1] * topo.RasterXSize,
            geo_transform[3]
        ]

    def gdal_warp_and_cut(self, in_file):
        """
        Cut and warp the grib file to the topo bounds and projection
        """
        topo = gdal.Open(self._topo_file, gdal.GA_ReadOnly)
        # Assume the first subDataSet holds the DEM info
        topo = gdal.Open(topo.GetSubDatasets()[0][0])
        spatial_info = osr.SpatialReference()
        spatial_info.SetFromUserInput(topo.GetProjection())

        options = gdal.WarpOptions(
            dstSRS=self.gdal_osr_authority(spatial_info),
            outputBoundsSRS=self.gdal_osr_authority(spatial_info),
            outputBounds=self.gdal_output_bounds(topo),
            xRes=topo.GetGeoTransform()[1],
            yRes=topo.GetGeoTransform()[1],
            multithread=True,
        )

        return gdal.Warp(self.MEM_TIFF, in_file, options=options)

    @staticmethod
    def grib_metadata(infile, band):
        # Metadata:
        # * GRIB_REF_TIME is in UTC, indicated by the 'Z' in field
        #   GRIB_IDS
        # * GRIB_VALID_TIME is the timestamp indicating the 'up to'
        #   valid time
        return infile.GetRasterBand(band).GetMetadata()

    def timestep_for_band(self, band):
        """
        Get forecasted time for given band. This is the actual GRIB forecast
        hour and when already converted when reading data that is for hours
        beyond 1.

        :param band: Band from warped and cut grib file

        :return: Datetime object converted to UTC timezone
        """
        return datetime.fromtimestamp(
            int(
                self.grib_metadata(
                    self.grib_file, band
                )['GRIB_VALID_TIME']
            )
        ).astimezone(timezone.utc)

    def save(self, out_file_path):
        """
        Save as netCDF with projection from initialized Topo

        :param out_file_path: String - Full path where file will be saved.
        """
        metadata = self.grib_metadata(self.grib_file, 1)

        with NetCDF.for_topo(out_file_path, self._topo_file) as outfile:
            field = outfile.createVariable(
                'DSWRF', 'f8', ('time', 'y', 'x',), zlib=True
            )
            field.setncattr('long_name', 'HRRR - DSWRF')
            field.setncattr('description', metadata['GRIB_COMMENT'])
            field.setncattr('units', metadata['GRIB_UNIT'])

            counter = 0
            for band in self.bands_from_grib_file:
                timestep = self.timestep_for_band(band)

                outfile['time'][counter] = NetCDF.date_to_number(
                    timestep, outfile, counter == 0
                )
                field[counter, :, :] = self.grib_file.GetRasterBand(band)\
                    .ReadAsArray()
                counter += 1

        gdal.Unlink(self.MEM_TIFF)
