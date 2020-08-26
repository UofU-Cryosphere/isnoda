## OS X binaries
* Install wgrib2 using Macports
  * Takes a looooong time and compiles everything from source

* Install gcc and OpenMP using Homebrew
    ```shell script
    brew install gcc-7 libomp
    ```
   * Set `CC` environment variable to point to the installed gcc compiler
   * Using gcc-9 and OpenMP 5 is currently breaking pysnobal

## Conda
Use attached `environment.yml` and link the activation and deactivation scripts.
Also add the `bin` folder from Macports to the `$PATH` to have wgrib2 available.
