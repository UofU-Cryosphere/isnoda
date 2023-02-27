# SMESHR scripts

Snow Melt Energy from Shortwave Radiation (SMESHR)

Utilities to prepare using HRRR cloud cover (TCDC) and downward short-wave 
radiation flux (DSWRF) in iSnobal as forcing inputs.

## Steps
### For cloud cover
Run `tcdc_for_topo.sh`
Run `HRRR_linker.sh`

### For short-wave radiation

Execution steps when using SMRF albedo:
1. `dswrf_for_topo.sh`
2. Run SMRF and output variables `albedo_vis` and `albedo_ir`
3. `net_dswrf_for_topo.sh`
4. `HRRR_linker.sh`
