## iSnobal utilities

Contains helper utilities for iSnobal data post-processing.

### Command line interfaces

All tools have a `--help` option to show all available parameters.

#### `smrf_compactor`

Combines forcing inputs from SMRF into one file and adds compression to each
stored variable in the NetCDF output. It loops over the individual daily output
folders and stores the merged file underneath that. As a default option, it
moves the individual forcing file to a folder. Deleting the files has to be
explicitly set via the `--delete-originals` parameter.

**Dependencies**

This utility requires the [CDO tools](https://code.mpimet.mpg.de/projects/cdo)
to be installed on the operating system.

Sample call:

```shell
smrf_compactor -sd <path/to/source/directory>
```