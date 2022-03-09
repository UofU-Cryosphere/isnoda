## Install basin setup

Instructions to
install [ARS basin_setup](https://github.com/USDA-ARS-NWRC/basin_setup)
with a conda environment. This installs the
[tauDEM](https://github.com/dtarb/TauDEM) dependency from source. Compilation
utilizes the
[conda  compiler](https://docs.conda.io/projects/conda-build/en/latest/resources/compiler-tools.html)
tools to get gcc-7 for the conda environment.

### Conda Environment

Use the 'basin_setup.yaml' in this folder to create a new conda environment.

```shell
conda env create -f basin_setup.yaml
```

### tauDEM Installation

__NOTE__: Make sure to activate the conda environment before installing tauDEM.

* Create an installation destination for tauDEM.<br>
  Example used here: `/data/iSnobal/`
* Download and extract tauDEM
  ```shell
  wget -O - https://github.com/dtarb/TauDEM/archive/f927ca639a1834565a76cb3df5acbcd2909d6d0d.tar.gz | \
  tar -xz -C /data/iSnobal/
  ```
* Rename the extracted folder
  ```shell
  mv TauDEM-f927ca639a1834565a76cb3df5acbcd2909d6d0d tauDEM
  ```

* Compile and install
  ```shell
  cd /data/iSnobal/tauDEM/
  # Directory for build
  mkdir build
  # Destination for the binaries
  mkdir build_install
  # Compile steps
  cd build
  cmake -DCMAKE_INSTALL_PREFIX=/data/iSnobal/tauDEM/build_install ../src
  make -j 8
  make install
  ```
* After this the binaries for tauDEM are in the `build_install` directory:
  `/data/iSnobal/tauDEM/build_install`

## `basin_setup` Installation

Install the basin package.<br>
__IMPORTANT__: The `--no-dpes` enforces to use the installed conda packages
and skips the installation via pip.
```shell
pip install --no-deps .
```