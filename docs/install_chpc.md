## CHPC iSnobal install
Specific instructions to run at the University of Utah CHPC environment.

### Load gcc with OpenMPI
Needed to compile `pysnobal` and `ipw`.

```shell script
module load gcc/6.4.0 openmpi/4.0.0
```

### Load wgrib
Needed to run SMRF
```shell script
module load wgrib2/2.0.8
```
