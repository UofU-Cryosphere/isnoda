# HRRR

## Conda envrionment
Use the supplied [hrrr.yaml](hrrr.yaml) to create a conda environment that
has the required software packages installed.

Command to create the environment:
```bash
conda env create -f hrrr.yaml
```

## Scripts
### [check_bad_gribs.sh](check_bad_gribs.sh)
Quick check of GRIB files if they are readable with GDAL.

### [download_hrrr.sh](download_hrrr.sh)
Utility to download HRRR files from different available data sources.
These are: Google, Amazon, and Azure

### Copy hour scripts
Example helper script that uses the `wgrib2` command to copy a previous
hour exisiting HRRR file to a missing hour. This is helpful for the cases 
that none of the data archives has a good file for that hour. See the script
headers for more information.

Two examples for the
* [copy_1st_hour.sh](copy_1st_hour.sh)
* [copy_6th_hour.sh](copy_6th_hour.sh)


## `grib2` command cheat sheet

### Fix date

Source: https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/set_date.html

```shell
wgrib2 <path_to_in_file> -set_date 2018120412 -grib <path_to_out_file>
```
