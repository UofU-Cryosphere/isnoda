import argparse
from pathlib import Path
import netCDF4

from snobedo.input import HrrrParameter
from snobedo.shortwave import TopoShade


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Extract variable from HRRR output for given day and'
                    'interpolate for given topo.'
    )

    parser.add_argument(
        '--topo', '-t',
        required=True,
        type=Path,
        help='Directory containing the topographic information (dem). \n'
             'This is also used as the target projection for the HRRR data.'
    )
    parser.add_argument(
        '--hrrr_in', '-hi',
        required=False,
        type=Path,
        help='Path to file with HRRR output or reads from stdin if not given.'
    )
    parser.add_argument(
        '--nc_out', '-nc',
        required=True,
        type=Path,
        help='Path to target netCDF destination file.'
    )
    parser.add_argument(
        '--add-shading', '-shading',
        action=argparse.BooleanOptionalAction,
        help='Add calculated topographic shading to netCDF output as variable.'
    )
    parser.add_argument(
        '--resample', '-r',
        required=False,
        type=str,
        choices=["nearest", "bilinear", "cubic", "cubic_spline", "lanczos", "average", "mode"],
        help='Optional: Choose the resampling algorithm for warping HRRR data. \n'
             'Options: nearest, bilinear, cubic, cubic_spline, lanczos, average, mode. \n'
             'If not specified, the default GDAL resampling method is used.'
    )

    return parser


def main():
    arguments = argument_parser().parse_args()

    if not arguments.topo.exists():
        raise IOError('Path to topo file does not exist')

    if arguments.hrrr_in and not arguments.hrrr_in.exists():
        raise IOError('Path to HRRR output does not exist')

    hrrr_in = None
    if arguments.hrrr_in:
        hrrr_in = arguments.hrrr_in.as_posix()

    # Pass the optional resampling method (defaults to None if not specified)
    hrrr_param = HrrrParameter(arguments.topo.as_posix(), hrrr_in, resample_method=arguments.resample)
    hrrr_param.save(arguments.nc_out)

    if arguments.add_shading:
        topo_shade = TopoShade(arguments.topo.as_posix())
        topo_shade.calculate(hrrr_param.time_range)
        with netCDF4.Dataset(arguments.nc_out, 'a') as outfile:
            topo_shade.add_illumination_angles(outfile)
