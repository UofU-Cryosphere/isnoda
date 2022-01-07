#!/bin/bash

#SBATCH --job-name=SMRF-compact
#SBATCH --account=notchpeak-gpu
#SBATCH --partition=notchpeak-gpu

#SBATCH --time=4:00:00
#SBATCH --ntasks=12
#SBATCH --mem=4G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --chdir=/path/to/scratch/
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

export OMP_NUM_THREADS=${SLURM_NTASKS}

ml cdo/2.0.0
source load_conda_env snobedo

# Path to iSnobal output up to the daily outputs (e.g. runYYYYMMDD)
SOURCE_FOLDER=/path/to/iSnobal/output

smrf_compactor -sd ${SOURCE_FOLDER} --delete-originals
smrf_compactor -sd ${SOURCE_FOLDER} -eb --delete-originals

# Add compression to remaining files, not processed by the above
# `smrf_compactor` call. Utilizes the `parallel` command and tools from `cdo`.
parallel --jobs ${OMP_NUM_THREADS} \
  nccopy -s -u -d4 {} {.}_c.nc ::: ${SOURCE_FOLDER}/run*/{em,precip,snow}.nc
rename _c.nc .nc ${SOURCE_FOLDER}/run*/{em,precip,snow}_c.nc

# Remove all empty log folders
find ${SOURCE_FOLDER} -type d -empty -delete