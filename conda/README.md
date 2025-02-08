# iSnoda - Conda Install

This folder contains conda environment files and a install script to create 
an execution environment from scratch.

## Model execution environment
The following steps create a new environment to execute the iSnobal model.

### Set up a new conda environment
```
  conda env create -f environment.yml
```
**NOTE**: Use the `environment_Mac_OSX.yml` if you are running on Mac OS X.

### Activate the environment
```
  conda activate isnoda
```

### Run the install script
```
  ./install_isnoda.sh
```
The script takes a user-defined install location as the first argument. The
default location is: `$HOME/iSnobal` if none is provided.

## Other environments
### Basin Setup
Separate setup to run [basin_setup](https://github.com/USDA-ARS-NWRC/basin_setup)
to prepare a model domain.

### IPW
Experimental setup for the old 1-D version of Snobal

