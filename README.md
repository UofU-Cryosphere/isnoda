# iSnoda
iSnobal installation in a local conda environment that allows for editing of:
* [AWSM](https://github.com/USDA-ARS-NWRC/awsm)
* [SMRF](https://github.com/USDA-ARS-NWRC/smrf)
* [PySnobal](https://github.com/USDA-ARS-NWRC/pysnobal)

## Conda
Contains `environment.yml` file and de/activation scripts to setup required
env variables. Also has an install script to download the above components
(plus their dependencies) and adds them to the environment in editable mode.

## Config

Backup of configuration files.

## Docs

Install instructions for:
* [IPW](https://github.com/USDA-ARS-NWRC/ipw) on Mac OS and Linux environments.  
* [basin setup](https://github.com/USDA-ARS-NWRC/basin_setup) from source on Linux.

## Notebooks

Collection of Jupyter notebooks for mostly output analysis.

## Package

[Snobedo package](package/README.md)

## Scripts

Helper scripts to download or prepare data and execute the model components.

## Snobal 1D

Example on how to run the one dimensional implementation of Snobal.

## Development

Any updates to the conda installation needs to be done on a branch with
a `conda-` prefix. This will trigger a build on Travis and verifies integrity
of changes.

# Publications
This work was developed as part of two publications:
* Geoscientific Model Development  
  Zenodo [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7452230.svg)](https://doi.org/10.5281/zenodo.7452230)    
  Meyer, J., Horel, J., Kormos, P., Hedrick, A., Trujillo, E., and Skiles, S. M.: Operational water forecast ability of the HRRR-iSnobal combination: an evaluation to adapt into production environments, Geosci. Model Dev., 16, 233–250, https://doi.org/10.5194/gmd-16-233-2023, 2023.
  
* Journal of Hydrology  
  Zenodo [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.11245701.svg)](https://doi.org/10.5281/zenodo.11245701)   
  Meyer, J., Hedrick, A., and McKenzie Skiles, S.: A new approach to net solar radiation in a spatially distributed snow energy balance model to improve snowmelt timing, Journal of Hydrology, 131490, https://doi.org/10.1016/j.jhydrol.2024.131490, 2024.  
