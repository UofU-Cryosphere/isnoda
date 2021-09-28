#!/usr/bin/env bash
#
# Run all passed arguments as command in the katana container
#

## Update these two variables with actual paths ##
KATANA_IMAGE=/path/to/katana.sif
SCRATCH_DIR=${HOME}/scratch/iSnobal
## -------------------------------- ##

ml singularity

singularity exec --bind ${SCRATCH_DIR}:/iSnobal ${KATANA_IMAGE} $@
