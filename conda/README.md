# iSnoda - Conda Install

This folder contains conda environment files and install scripts.

## Model execution environment
The following steps create a new environment to execute the iSnobal model.

### Set up a new conda environment
```
  conda env create -f environment.yml
```

### Activate the environment
```
  conda activate isnoda
```

All done!

## Development environment
Set up a conda environment with the steps shown above.

### Run the install script
```
  ./install_isnoda_development.sh
```
The script takes a user-defined install location as the first argument. The
default location is: `$HOME/iSnobal` if none is provided.

### Releasing a new model version
Updating the [conda environment.yaml](environment.yaml) to use a newer version
of AWSM requires [creating a new release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository#creating-a-release) 
on the [AWSM GitHub repository](https://github.com/UofU-Cryosphere/awsm). AWSM
only depends on SMRF and any updates to the latter should be completed first
before creating a new referenced release from AWSM to SMRF.

All other model dependencies (i.e., pySnobal, TopoCalc) are managed within
[SMRF](https://github.com/UofU-Cryosphere/smrf). New releases of these dependencies
should be handled there.

Once the release is published, update the `- pip:` section in the environment YAML
that points to the GitHub URL. The URL has the form of:  
```
    - git+https://github.com/UofU-Cryosphere/awsm.git@_RELEASE_TAG_
```
The `_RELEASE_TAG_` is a placeholder in this case and should be replaced with
the actual release name.

## Other environments
### Basin Setup
Separate setup to run [basin_setup](https://github.com/USDA-ARS-NWRC/basin_setup)
to prepare a model domain.

### IPW
Experimental setup for the old 1-D version of Snobal. No support can be provided
for this.
