# SMESHR scripts

Snow Melt Energy from Shortwave Radiation (SMESHR)

Utilities to prepare using HRRR cloud cover (TCDC) and downward short-wave 
radiation flux (DSWRF) in iSnobal as forcing inputs.

## Required Tools
Most scripts rely on these commands to be available/installed:
* [Climate Data Operators (CDO)](https://code.mpimet.mpg.de/projects/cdo)
* [GNU parallel](https://www.gnu.org/software/parallel/parallel_tutorial.html)

Both are available via [conda forge](https://conda-forge.org/)

All below scripts also require ths `snobedo` package of this repository to be 
installed. See the [installation instructions](../../package/README.md) for 
getting this step complete.

### Conda
The provided (environment.yaml)[/environment.yaml] in this directory
can be used to setup a execution environment. It also includes the above
listed packages and the libraries needed for the `snobedo` package.

## Steps
Below the order execution of scripts to create forcing input files for iSnobal
in the expected format. Each script has it's functionality described in the
header.

### For cloud cover
1. `tcdc_for_topo.sh`
1. `HRRR_linker.sh`

### For shortwave radiation
There are two options to use the HRRR variable and produce a `net_solar.nc` 
required to run iSnobal:
* Combine with Time-Decay albedo (SMRF default)
* Use the MODIS STC product

#### Common steps in both cases
Extract the HRRR shortwave information for model domain
1. `dswrf_for_topo.sh`

#### MODIS Albedo
__REQUIRED SOFTWARE__:  
The UofU [snow-rs](https://github.com/UofU-Cryosphere/snow-rs) package is 
required to extract the relevant albedo variable from the MODIS STC product.
The supplied conda environment of that package is not needed and already
included with the provided `environment.yaml` of this directory.

__IMPORTANT__:  
The scripts are currently tailored to the East-River domain.
Please adjust the domain extent as needed in `MODIS_albedo_ERW.sh` line 37

Steps:  
1. `MODIS_albedo_ERW.sh`
1. `net_dswrf_for_topo_MODIS.sh`
1. `HRRR_linker.sh`

#### SMRF Albedo
1. Run SMRF and output variables `albedo_vis` and `albedo_ir`
1. `net_dswrf_for_topo_SMRF.sh`
1. `HRRR_linker.sh`
