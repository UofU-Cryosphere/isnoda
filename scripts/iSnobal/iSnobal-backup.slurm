#!/bin/bash

#SBATCH --job-name=iSnobal-backup
#SBATCH --account=owner-guest
#SBATCH --partition=notchpeak-guest

#SBATCH --time=2:00:00
#SBATCH --ntasks=16
#SBATCH --mem=2G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --chdir=/path/to/scratch/
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

ml rclone
export OMP_NUM_THREADS=${SLURM_NTASKS}

START_MONTH=201810
WATER_YEAR="wy$(date -d "${START_MONTH}01 + 1 year" +%Y)"

BACKUP_PREFIX="run"
BACKUP_ORIGIN="runs"

BACKUP_SUFFIX=".tar.bz2"

BACKUP_DIR="${HOME}/shared-cryosphere/iSnobal/${BACKUP_ORIGIN}/${WATER_YEAR}"
mkdir -p $BACKUP_DIR

cd ${HOME}/scratch/iSnobal/ERW_subset/output/erw_subset/devel/${WATER_YEAR}/initial_run/${BACKUP_ORIGIN}/

for MONTH in {0..11}; do
  BACKUP_YEAR=$(date -d "${START_MONTH}01 + ${MONTH} month" +%Y%m)

  tar -I pbzip2 -cf ${BACKUP_DIR}/${BACKUP_PREFIX}${BACKUP_YEAR}${BACKUP_SUFFIX} \
    ${BACKUP_PREFIX}${BACKUP_YEAR}[0-3][0-9]
done

cd ${BACKUP_DIR}

rclone copy . isnoda:ERW_subset/${BACKUP_ORIGIN}/${WATER_YEAR}/ \
  --transfers ${SLURM_NTASKS} \
  --include "*${BACKUP_SUFFIX}"
