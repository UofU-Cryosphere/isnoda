import argparse
import os
import shutil
import subprocess
from pathlib import Path

from snobedo.lib.command_line_helpers import add_dask_options

DAY_FOLDER_PREFIX = 'run'
OUTPUT_FILES = [
    'air_temp.nc',
    'cloud_factor.nc',
    'percent_snow.nc',
    'precip_temp.nc',
    'snow_density.nc',
    'storm_days.nc',
    'thermal.nc',
    'vapor_pressure.nc',
    'wind_speed.nc',
]
MERGE_FILE_NAME = 'smrf_{day}.nc'
COMBINED_FOLDER = 'combined'
CDO_COMMAND = ['cdo', '-P', '4', '-z', 'zip_4', 'merge']


def argument_parser():
    parser = argparse.ArgumentParser(
        description='Compress and combine SMRF output for given water year.'
                    'This will combine individual output files into one'
    )

    parser.add_argument(
        '--source-dir', '-sd',
        required=True,
        type=Path,
        help='Directory containing each individual day output folders. '
             'The day folders have the pattern of: runYYYYMMDD'
    )
    parser.add_argument(
        '--delete-originals',
        action='store_true',
        required=False,
        help='Delete instead of moving the original files.'
    )
    parser = add_dask_options(parser)

    return parser


def combined_file_name(day_folder):
    outfile = (
            day_folder /
            MERGE_FILE_NAME.format(
                day=day_folder.name.replace(DAY_FOLDER_PREFIX, '')
            )
    )

    if outfile.exists():
        print(f"Output file {outfile.as_posix()} already exists - Skipping")
        return None
    else:
        return outfile


def combine_files(day_folder, outfile):
    day_files = [(day_folder / file).as_posix() for file in OUTPUT_FILES]
    call = subprocess.run(
        CDO_COMMAND + day_files + [outfile],
        stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True
    )

    if call.returncode == 0:
        print(f"Combined files saved to: {outfile}")
        return day_files
    else:
        print(call.stderr)
        return []


def main():
    arguments = argument_parser().parse_args()

    if not arguments.source_dir.exists():
        raise IOError(
            f'Given source folder does not exist: {arguments.source_dir}'
        )

    day_folders = arguments.source_dir.glob(DAY_FOLDER_PREFIX + '*')

    for day in day_folders:
        outfile = combined_file_name(day)

        if outfile is None:
            continue

        day_files = combine_files(day, outfile.as_posix())
        if day_files:
            if not arguments.delete_originals:
                destination = (day / COMBINED_FOLDER)
                destination.mkdir(exist_ok=True)
                print(f'  Moving files to: {destination.as_posix()}')
                for file in day_files:
                    shutil.move(file, destination)
            else:
                for file in day_files:
                    print(f'  Delete file: {file}')
                    os.remove(file)
