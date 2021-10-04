# ASO coverage map
gdalwarp --optfile $GDAL_OPTS -multi -wm 128 \
  -cutline ../Boundaries/ERW_subset_domain.geojson -crop_to_cutline \
  infile.tif outfile.tif

gdal_calc.py  --calc="(A > -1) * 1" \
  -A infile.tif \
  --outfile=outfile.tif

gdal_polygonize.py -nomask -f GeoJSON infile.tif outfile.geojson

gdal_translate -ot Byte --optfile $GDAL_OPTS -tr 1 1 \
  infile.tif outfile.tif
