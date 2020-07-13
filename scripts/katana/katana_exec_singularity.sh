#!/usr/bin/env bash
#
# Run all passed arguments as command from katana container

ml singularity

singularity exec --bind ~/scratch/iSnobal:/iSnobal katana_jm.sif $@
