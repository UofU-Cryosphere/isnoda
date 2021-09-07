### `grib2` command cheat sheet
#### Fix date
Source: https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/set_date.html
```shell
wgrib2 <path_to_in_file> -set_date 2018120412 -grib <path_to_out_file>
```