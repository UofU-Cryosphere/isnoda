# Notes to install IPW on Linux

## `IPW` path variable
* Needs to be an absolute path that was not part of a symbolic link

## Conda
* Use supplied [environment file](../conda/ipw_linux64.yml) to setup compile
  environment. This uses the [Anaconda compiler tools](https://docs.conda.io/projects/conda-build/en/latest/resources/compiler-tools.html)

## Install process
* After activation, add the `-fopnemp` flag to the compiler
```shell
    export CC="${CC} -fopenmp"
```

* Use the supplied [general IPW install script](../conda/install_ipw.sh)
