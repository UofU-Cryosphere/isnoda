import argparse
import datetime
import json
from pathlib import Path

import xarray as xr

from snobedo.lib.command_line_helpers import add_dask_options
from snobedo.lib.dask_utils import run_with_client

OUTPUT_FILE_SUFFIX = '.zarr'


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Extract SNOTEL site data from iSnobal files to zarr.',
    )

    parser.add_argument(
        '--source-dir',
        required=True,
        type=Path,
        help='Path to iSnobal output.'
             'Example: /data/input/erw_subset/devel/wy2020/runs',
    )
    parser.add_argument(
        '--source-file',
        required=True,
        help='Output file from iSnobal to read the data from. '
             'Example: snow.nc',
    )
    parser.add_argument(
        '--sites',
        required=True,
        type=Path,
        help='File the SNOTEL sites with coordinates.',
    )
    parser.add_argument(
        '--output-dir',
        required=True,
        type=Path,
        help='Path to iSnobal write the output.'
             'Example: /data/output/',
    )
    parser.add_argument(
        '--output-time',
        type=int,
        default=23,
        help='Select a specific output time from the Snobal outputs. '
             'Default: 23',
    )
    parser = add_dask_options(parser)

    return parser


def main():
    arguments = argument_parser().parse_args()

    if not arguments.source_dir.exists():
        raise IOError(
            f'Given source folder does not exist: {arguments.source_dir}'
        )

    sites = json.load(
        open(arguments.sites.as_posix(), 'r')
    )

    with run_with_client(arguments.cores, arguments.memory):
        for site, coords in sites.items():
            method = 'nearest' if (type(coords['lat']) != list) else None

            output_dir = arguments.output_dir / f'{site}-snotel'
            output_dir.mkdir(exist_ok=True)

            output_file = Path(arguments.source_file).stem + OUTPUT_FILE_SUFFIX

            snow = xr.open_mfdataset(
                arguments.source_dir.joinpath(
                    '*', arguments.source_file
                ).as_posix(),
                parallel=True,
            ).sel(
                time=datetime.time(arguments.output_time)
            )

            snow.sel(
                x=coords['lon'],
                y=coords['lat'],
                method=method,
            ).to_zarr(
                output_dir.joinpath(output_file).as_posix(),
                compute=True
            )


if __name__ == '__main__':
    main()
