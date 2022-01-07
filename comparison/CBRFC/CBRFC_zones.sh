#!/usr/bin/env bash

# Extract all zones in the modeled domain
ogr2ogr -spat 315900.00 4322700.00 348700.00 4280850.00 \
        -spat_srs EPSG:32613 -t_srs EPSG:32613 \
        -clipdst 315900.00 4322700.00 348700.00 4280850.00 \
        ERW_CBRFC_zones.geojson \
        '/data/iSnobal/CBRFC/CBRFC_Zones/CBRFC_Zones.shp'

# In QGIS
## Add an attribute to burn as raster value
## Add unique values to the attribute for the desired zones

# Create classification tiff
gdal_rasterize -l ERW_CBRFC_zones -a RASTER_VALUE \
               -tr 50.0 50.0 -a_nodata 0.0 \
               -te 315900.0 4280850.0 348700.0 4322700.0 -ot Byte -of GTiff \
               source.geojson destination.tif
