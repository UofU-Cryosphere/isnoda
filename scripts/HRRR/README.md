# HRRR scripts

## `check_bad_gribs.sh`
Quick check of GRIB files if they are readable with GDAL.

## `download_hrrr.sh`
Utility to download HRRR files from different available source.

## `grib2` command cheat sheet

### Fix date

Source: https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/set_date.html

```shell
wgrib2 <path_to_in_file> -set_date 2018120412 -grib <path_to_out_file>
```

### Local install notes

Set the compiler

```shell
export CC=gcc
export FC=gfortran
```

If the `wget` command fails, executed the download manually and restart the
`make` process.