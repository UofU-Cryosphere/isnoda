import shutil

import xarray as xr

OUTPUT_FILE = "WesternUS_{date:%Y%m%d}.zarr"
SCALE_FACTOR = 0.0001
RASTERIO_ATTRS = ['scales', 'offsets', 'is_tiled']


def write_zarr(file, date, key, output_folder):
    day = xr.open_rasterio(file).expand_dims({'time': [date]})

    # Added by Xarray open_rasterio
    [day.attrs.pop(attr) for attr in RASTERIO_ATTRS]

    # Xarray applies this factor when reading dataset variables
    day.attrs['scale_factor'] = SCALE_FACTOR
    day.name = key

    del day.coords['band']
    day = day.squeeze('band').to_dataset()

    output_file = output_folder.joinpath(OUTPUT_FILE.format(date=date))
    if output_file.exists():
        shutil.rmtree(output_file)

    day.to_zarr(output_file.as_posix())

    del day
