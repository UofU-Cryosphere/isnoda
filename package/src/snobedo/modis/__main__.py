import argparse
from datetime import datetime, timedelta
from pathlib import Path
from typing import NamedTuple

import dask
import numpy as np

from snobedo.lib import ModisGeoTiff
from snobedo.lib.dask_utils import run_with_client
from snobedo.modis.geotiff_to_zarr import write_zarr
from snobedo.modis.matlab_to_geotiff import matlab_to_geotiff, warp_to

ONE_DAY = timedelta(days=1)


class ConversionConfig(NamedTuple):
    variable: str
    source_dir: Path
    output_dir: Path
    modis_us: ModisGeoTiff
    target_srs: str


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Convert matlab files to zarr',
    )

    parser.add_argument(
        '--source-dir',
        required=True,
        type=Path,
        help='Base directory. The files to convert are expected to be in a '
             'folder with the water year. Example: 2018'
             ' Other required file expected under this folder is the template '
             f'MODIS file with name: {ModisGeoTiff.WESTERN_US_TEMPLATE}',
    )
    parser.add_argument(
        '--water-year',
        required=True,
        type=int,
        help='Water year. Determines the date range to process'
    )
    parser.add_argument(
        '--variable',
        required=True,
        type=str,
        help='Variable to extract from the matlab files'
    )
    parser.add_argument(
        '--t-srs',
        type=str,
        default='EPSG:32613',
        help='Target EPSG. Default: EPSG:32613'
    )

    return parser


def config_for_arguments(arguments):
    output_dir = arguments.source_dir / f'wy{arguments.water_year}-zarr/'
    output_dir.mkdir(exist_ok=True)

    return ConversionConfig(
        variable=arguments.variable,
        source_dir=arguments.source_dir,
        output_dir=output_dir,
        modis_us=ModisGeoTiff(arguments.source_dir),
        target_srs=arguments.t_srs
    )


def date_range(water_year):
    d0 = datetime(water_year, 9, 1)
    d1 = datetime(water_year + 1, 10, 1)

    return np.arange(d0, d1, ONE_DAY).astype(datetime)


@dask.delayed
def write_date(date, config):
    file = matlab_to_geotiff(
        config.source_dir,
        config.output_dir,
        config.modis_us,
        date,
        config.variable,
    )
    file = warp_to(file, config.target_srs)
    write_zarr(file, date, config.variable, config.output_dir)


def main():
    arguments = argument_parser().parse_args()

    if not arguments.source_dir.exists():
        raise IOError(
            f'Given source folder does not exist: {arguments.source_dir}'
        )

    with run_with_client(4, 8):
        config = config_for_arguments(arguments)
        files = [
            write_date(date, config)
            for date in date_range(arguments.water_year)
        ]
        dask.compute(*files)


if __name__ == '__main__':
    main()
