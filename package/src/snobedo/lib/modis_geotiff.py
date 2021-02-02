from dataclasses import dataclass, field, InitVar
from pathlib import PurePath

from osgeo import gdal, gdalconst


@dataclass
class ModisGeoTiff:
    data_dir: InitVar[PurePath] = None
    x_size: int = field(init=False)
    y_size: int = field(init=False)
    geo_transform: tuple = field(init=False)

    PROJECTION = '+proj=sinu +lon_0=0 +x_0=0 +y_0=0 ' \
                 '+a=6371007.181 +b=6371007.181 +units=m ' \
                 '+no_defs +nadgrids=@null +wktext'

    WESTERN_US_TEMPLATE = 'WesternUS.tif'

    def __post_init__(self, data_dir):
        self.__load_template_data(data_dir)

    def __load_template_data(self, data_dir):
        data_dir = PurePath(data_dir)
        template = gdal.Open(
            data_dir.joinpath(self.WESTERN_US_TEMPLATE).as_posix(),
            gdalconst.GA_ReadOnly
        )

        self.x_size = template.RasterXSize
        self.y_size = template.RasterYSize
        self.geo_transform = template.GetGeoTransform()

        del template
