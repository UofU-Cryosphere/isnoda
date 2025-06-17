#!/bin/bash

#SBATCH --job-name=SMRF-compact
#SBATCH --account=owner-gpu-guest
#SBATCH --partition=notchpeak-gpu-guest

#SBATCH --time=4:00:00
#SBATCH --ntasks=12
#SBATCH --mem=4G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=j.michelle.hu@utah.edu

#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

export OMP_NUM_THREADS=${SLURM_NTASKS}
# Log some items
echo "Running $0 from $SLURM_SUBMIT_DIR"
echo "        with SLURM_JOB_ID:  $SLURM_JOB_ID"
echo "        with SLURM_JOB_PARTITION:  $SLURM_JOB_PARTITION"
echo "        with SLURM_JOB_NODELIST:  $SLURM_JOB_NODELIST"

module use $HOME/MyModules
module load miniconda3/latest
conda activate snobedo

ml cdo/2.0.0

# Path to iSnobal output up to the daily outputs (e.g. runYYYYMMDD)
SOURCE_FOLDER=$1

compact_smrf() {
  smrf_compactor -sd ${1} --delete-originals
  smrf_compactor -sd ${1} -eb --delete-originals
}

export -f compact_smrf
parallel --tag --line-buffer --jobs ${OMP_NUM_THREADS} compact_smrf ::: ${SOURCE_FOLDER}

# Add compression to remaining files, not processed by the above
# `smrf_compactor` call. Utilizes the `parallel` command and tools from `cdo`.
parallel --tag --line-buffer --jobs ${OMP_NUM_THREADS} \
  nccopy -s -u -d4 {} {.}_c.nc ::: ${SOURCE_FOLDER}/{em,snow}.nc
rename _c.nc .nc ${SOURCE_FOLDER}/{em,snow}_c.nc

# Remove all empty log folders
find ${SOURCE_FOLDER} -type d -empty -delete
