## MODIS

Contains a converter utility to extract values for a given variable and extract from
a MODIS gap-filled product.

### Sample call:
```shell
variable_from_modis --source-dir /data/iSnobal/MODIS_albedo --water-year 2018 --variable albedo_observed_muZ
```

### Data required
The source dir needs to contain the 'WesternUS.tif' from the `data` folder of
this package.


### Technical note
Uses Dask to parallelize extraction on daily basis.