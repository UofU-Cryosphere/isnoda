#!/usr/bin/env bash

# Update output variables to only solar relevant ones
# This command relies on the declaration of variables
# on line 211 in the config.ini files

for smfrcnf in */config.ini; do 
  sed -i "211s/.*/variables:                     net_solar, cloud_factor, albedo_vis, albedo_ir, veg_ir_beam, veg_ir_diffuse, veg_vis_beam, veg_vis_diffuse/" $smfrcnf; 
done

