#!/usr/bin/env bash

YEAR=2020

for file in $HOME/shared-cyrosphere/Rittger_albedo/$YEAR-tif/*.tif;
do
  OUTFILE=$(basename $file)

  gdalwarp -t_srs EPSG:32613 -multi -r bilinear \
    $file \
    "$HOME/shared-cyrosphere/Rittger_albedo/$YEAR-32613/${OUTFILE/.tif/_32613.vrt}"
done

