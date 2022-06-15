# Snobedo package

Python package for processing snow property information from remote sensing sources.
Also includes utility methods to convert data into data formats to process
information in parallel using [Dask](https://docs.dask.org/en/latest/)

## Installation for development

### Setup the environment via conda
Some dependent packages are only available via `pip`. To install all required
packages, first create a conda environment, and then add the missing packages
via `pip install`.

```shell
conda create -n snobedo -f environment.yml
conda activate snobedo
pip install -r requirements.txt --no-deps
```

### Add this package
_NOTE_: The '-e' flag installs the packages as editable from source.

```shell
git clone git@github.com:UofU-Cryosphere/isnoda.git
cd isnoda/package
python -m pip install -e .
```