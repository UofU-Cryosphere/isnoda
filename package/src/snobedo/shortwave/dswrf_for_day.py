import argparse
from pathlib import Path

from snobedo.shortwave.hrrr_dswrf import HrrrDswrf


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Extract DSWRF variable from HRRR output for given day'
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

    hrrr_dswrf = HrrrDswrf(arguments.topo.as_posix(), hrrr_in)
    hrrr_dswrf.save(arguments.nc_out)
