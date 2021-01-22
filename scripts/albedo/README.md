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

### MODIS

The `WesternUS` template consists of the following original
MODIS tiles:
* h08v04
* h09v04
* h10v04
* h08v05
* h09v05

#### MODIS coordinates:
```
 iv  ih    lon_min    lon_max   lat_min   lat_max
  4   8  -155.5724  -117.4758   40.0000   50.0000
  4   9  -140.0151  -104.4217   40.0000   50.0000
  4  10  -124.4579   -91.3676   40.0000   50.0000
  5   8  -130.5407  -103.9134   30.0000   40.0000
  5   9  -117.4867   -92.3664   30.0000   40.0000
```

#### MODIS projection:
```
+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs +nadgrids=@null +wktext
```
