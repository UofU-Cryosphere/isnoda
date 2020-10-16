### Katana running nodes

#### Wind Ninja
* Can use 24 cores at a time
* Needs roughly 0.5 GB per core of memory
* One month with 24 cores takes about 20 minutes run time
 
#### Possible error sources
* Bad HRRR grib files with no or corrupted data

### Debugging issues
#### Run single day
Use `wind_ninja_singularity.sh` and run the created `katana.ini` file that
gets created by katana. This file is the config used by Wind Ninja for a single
day. It is located on the root level of the output folder given to katana.
