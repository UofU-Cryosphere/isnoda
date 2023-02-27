import argparse
from datetime import datetime
from pathlib import Path

import numpy as np

from snobedo.shortwave import TopoShade


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Calculate topographic shading for a given day in one '
                    'hour increments.'
    )

    parser.add_argument(
        '--topo', '-t',
        required=True,
        type=Path,
        help='Directory containing the topographic information (dem).'
    )
    parser.add_argument(
        '--start-date', '-sd',
        required=True,
        help='Start date. Format: YYYY-MM-DD'
    )
    parser.add_argument(
        '--end-date', '-ed',
        required=True,
        help='End date. Format: YYYY-MM-DD'
    )
    parser.add_argument(
        '--nc_out', '-nc',
        required=True,
        type=Path,
        help='Path to the target netCDF destination file.'
    )
    parser.add_argument(
        '--solar-method', '-sm',
        required=False,
        type=str,
        choices=[TopoShade.SolarMethods.SKYFIELD, TopoShade.SolarMethods.SMRF],
        default=TopoShade.SolarMethods.SKYFIELD,
        help='Method to use for solar calculations. '
             'Default: skyfield; option: SMRF'
    )

    return parser


def time_range_for(start, end):
    time_range = np.arange(
        start,
        end,
        np.timedelta64(1, 'h'),
        dtype='datetime64[s]'
    )

    return [datetime.fromisoformat(str(r)) for r in time_range]


def main():
    arguments = argument_parser().parse_args()

    if not arguments.topo.exists():
        raise IOError('Path to topo file does not exist')

    topo_shade = TopoShade(
        arguments.topo.as_posix(), arguments.solar_method
    )
    topo_shade.calculate(
        time_range_for(arguments.start_date, arguments.end_date)
    )
    topo_shade.save(arguments.nc_out)
