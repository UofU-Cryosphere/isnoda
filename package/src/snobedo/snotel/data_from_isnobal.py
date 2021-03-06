import argparse
from pathlib import Path

import xarray as xr

from snobedo.lib.command_line_helpers \
    import add_dask_options, check_paths_presence
from snobedo.lib.dask_utils import run_with_client
from snobedo.lib.isnobal_helpers import day_filter, hour_filter
from snobedo.snotel.snotel_locations import SnotelLocations

OUTPUT_FILE_SUFFIX = '.zarr'
PATH_INPUT_ARGS = ['source_dir', 'output_dir', 'sites']


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Extract SNOTEL site data from iSnobal files to zarr.',
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
        '--sites',
        required=True,
        type=Path,
        help='File the SNOTEL sites with coordinates.',
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
    parser.add_argument(
        '--output-time', '-ot',
        type=int,
        default=23,
        help='Select a specific output time from the Snobal outputs. '
             'An argument value of 0 will get all output hours from each day.'
             'Default: 23',
    )
    parser = add_dask_options(parser)

    return parser


def output_file(arguments, site):
    output_dir = arguments.output_dir / f'{site.name}-snotel'
    output_dir.mkdir(exist_ok=True)

    if arguments.output_file_name is None:
        file_name = Path(arguments.source_file).stem + OUTPUT_FILE_SUFFIX
    else:
        file_name = arguments.output_file_name + OUTPUT_FILE_SUFFIX

    return output_dir.joinpath(file_name).as_posix()


def main():
    arguments = argument_parser().parse_args()

    check_paths_presence(arguments, PATH_INPUT_ARGS)

    sites = SnotelLocations.parse_json(arguments.sites.as_posix())

    mfdataset_args = dict(
        parallel=True
    )

    if arguments.output_time == 0:
        mfdataset_args['preprocess'] = day_filter

    with run_with_client(arguments.cores, arguments.memory):
        for site in sites:
            print(f"Processing SNOTEL site: {site.name}")
            method = 'nearest' if (type(site.lat) != list) else None

            dataset = xr.open_mfdataset(
                arguments.source_dir.joinpath(
                    '*', arguments.source_file
                ).as_posix(),
                **mfdataset_args
            )

            if arguments.output_time != 0:
                dataset = hour_filter(dataset)

            dataset.sel(
                x=site.lon,
                y=site.lat,
                method=method,
            ).to_zarr(
                output_file(arguments, site),
                compute=True
            )


if __name__ == '__main__':
    main()
