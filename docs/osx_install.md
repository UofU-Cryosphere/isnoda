## OS X binaries
### Wgrib2
* Install wgrib2 using Macports
  * Takes a looooong time and compiles everything from source

### IPW
* Install gcc and OpenMP using Homebrew
    ```shell script
    brew install gcc@7 libomp
    ```
* Set required environment variables
  * `CC` environment variable to point to the installed gcc compiler
   ```shell script
    export CC='/usr/local/bin/gcc-7 -fopenmp'
    ```
  * Follow the steps described [in the official docs](https://github.com/USDA-ARS-NWRC/ipw/blob/master/Install)
  In a nutshell, it drills down to these sequence of commands:
  ````shell script
    cd <path to IPW directory>
    # Will throw an error with the `make` command if not set
    export IPW=`pwd`
    # Needed when running the commands later
    mkdir tmp
    export WORKDIR=${IPW}/tmp
    # Build ...
    ./configure
    make
    make install
  ````
  
 __NOTE__:
 * Don't get tempted to use parallel make command (`-j`). The files have to be compiled in sequence.
 * Using gcc-9 and OpenMP 5 is currently not supported.

## Conda
Use attached `environment.yml` and link the activation and deactivation scripts.
Also add the `bin` folder from Macports to the `$PATH` to have wgrib2 available.
