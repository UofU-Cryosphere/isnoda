## OS X binaries
### Wgrib2
Command line binary to read GRIB-2 files.
([More Info](https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/))

* Install wgrib2 using [Macports](https://www.macports.org/)
  * Takes a looooong time and compiles everything from source.  
    __NOTE__: The `wgrib2` binary is not needed for the point model version of iSnobal.

### IPW
* Install the gcc compiler (version 7) and OpenMP using [Homebrew](https://brew.sh/)
    ```shell script
    brew install gcc@7 libomp
    ```
* Set required environment variables
  * `CC` environment variable to point to the installed gcc compiler
   ```shell script
    export CC='/usr/local/bin/gcc-7 -fopenmp'
    ```
  * Follow the steps described [in the official docs](https://github.com/USDA-ARS-NWRC/ipw/blob/master/Install).  
    The essential steps are also available this [install script](../conda/install_ipw.sh)
  
 __NOTE__:
 * Don't get tempted to use parallel make command (`-j`). The files have to be compiled in sequence.
 * Using gcc-9 and OpenMP 5 is currently not supported.

## Conda
Use attached `environment.yml` and link the activation and deactivation scripts.
Also add the `bin` folder from Macports to the `$PATH` to have wgrib2 available.
