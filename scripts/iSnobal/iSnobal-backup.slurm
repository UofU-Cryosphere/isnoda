#!/bin/bash

#SBATCH --job-name=iSnobal
#SBATCH --account=owner-guest
#SBATCH --partition=notchpeak-guest

#SBATCH --time=4:00:00
#SBATCH --ntasks=16
#SBATCH --mem=2G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --chdir=/path/to/scratch/
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

ml rclone
export OMP_NUM_THREADS=${SLURM_NTASKS}

BACKUP_PREFIX="run"
BACKUP_SUFFIX=".tar.bz2"
BACKUP_ORIGIN="runs"
BACKUP_DIR="${HOME}/shared-cyrosphere/iSnobal/${BACKUP_ORIGIN}"
START_MONTH=201810

cd ${HOME}/scratch/iSnobal/ERW_subset/output/erw_subset/devel/wy2019/initial_run/${BACKUP_ORIGIN}/

for MONTH in {0..11}; do
  BACKUP_YEAR=$(date -d "${START_MONTH}01 + ${MONTH} month" +%Y%m)

  tar -I pbzip2 -cf ${BACKUP_DIR}/${BACKUP_PREFIX}${BACKUP_YEAR}${BACKUP_SUFFIX} \
    ${BACKUP_PREFIX}${BACKUP_YEAR}[0-3][0-9]
done

cd ${BACKUP_DIR}

rclone copy . isnoda:ERW_subset/${BACKUP_ORIGIN}/ \
  --transfers ${SLURM_NTASKS} \
  --include "*${BACKUP_SUFFIX}"
