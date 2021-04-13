import argparse
from pathlib import Path

import xarray as xr

from snobedo.lib.command_line_helpers \
    import add_dask_options, check_paths_presence
from snobedo.lib.dask_utils import run_with_client

OUTPUT_FILE_SUFFIX = '.nc'
PATH_INPUT_ARGS = ['source_dir', 'output_dir']


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Combine iSnobal input or output NetCDF files.',
    )

    parser.add_argument(
        '--source-dir', '-sd',
        required=True,
        type=Path,
        help='Path to iSnobal output.'
             'Example: /data/input/erw_subset/devel/wy2020/runs',
    )
    parser.add_argument(
        '--source-file', '-sf',
        required=True,
        help='Output file from iSnobal to read the data from. '
             'Also accepts wildcards to read multiple. '
             'Examples: snow.nc, albedo*.nc',
    )
    parser.add_argument(
        '--output-dir', '-od',
        required=True,
        type=Path,
        help='Path to iSnobal write the output.'
             'Example: /data/output/',
    )
    parser.add_argument(
        '--output-file-name', '-ofn',
        type=str,
        default=None,
        help='Specify a name for the output file (Optional). '
             'Defaults to the source file name argument without the file '
             'suffix. Example: snow'
    )
    parser = add_dask_options(parser)

    return parser


def output_file(arguments):
    output_dir = arguments.output_dir
    output_dir.mkdir(exist_ok=True)

    if arguments.output_file_name is None:
        file_name = Path(arguments.source_file).stem + OUTPUT_FILE_SUFFIX
    else:
        file_name = arguments.output_file_name + OUTPUT_FILE_SUFFIX

    return output_dir.joinpath(file_name).as_posix()


def main():
    arguments = argument_parser().parse_args()

    check_paths_presence(arguments, PATH_INPUT_ARGS)

    with run_with_client(arguments.cores, arguments.memory):
        xr.open_mfdataset(
            arguments.source_dir.joinpath(
                '*', arguments.source_file
            ).as_posix(),
            parallel=True
        ).to_netcdf(
            output_file(arguments),
            compute=True
        )


if __name__ == '__main__':
    main()
