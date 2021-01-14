### Notes on script usage

#### Required libraries
* GDAL
* [Mat 7.3](https://github.com/skjerns/mat7.3)

### `clean_albedo.py`

Script that extracts clean albedo values from the downloaded
Matlab files and stores them in a copy of the `WesternUS.tif`
template.

### `warp_modis.sh`

Reproject from MODIS Sinusodial to EPSG:32613 using a `.vrt`

### Creating NetCDF

See notebooks `Albedo_tif_to_nc`.
Uses dask to parallelize conversion process.
