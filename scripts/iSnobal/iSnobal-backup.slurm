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

BACKUP_ORIGIN="run"
BACKUP_SUFFIX=".tar.bz2"

BACKUP_SOURCE="${HOME}/scratch/iSnobal/outputs/${WATER_YEAR}/"
BACKUP_DIR="${HOME}/shared-cryosphere/iSnobal/runs/${WATER_YEAR}/"

mkdir -p $BACKUP_DIR

if [ ! -d "${BACKUP_SOURCE}" ]; then
  printf "Backup source does not exist:\n  ${BACKUP_SOURCE}\n"
  exit -1
else
  cd ${BACKUP_SOURCE}
fi

for MONTH in {0..11}; do
  BACKUP_YEAR=$(date -d "${START_MONTH}01 + ${MONTH} month" +%Y%m)

  tar cf - ${BACKUP_ORIGIN}${BACKUP_YEAR}[0-3][0-9] | \
    pbzip2 -m1024 -r > "${BACKUP_DIR}${BACKUP_ORIGIN}-${BACKUP_YEAR}${BACKUP_SUFFIX}"

  if [ $? != 0 ]; then
    printf "Error creating archive for month:\n   ${BACKUP_YEAR}\n"
    exit -1
  fi
done

cd ${BACKUP_DIR}

rclone copy . isnoda:ERW_subset/runs/${WATER_YEAR}/ \
  --transfers 4 \
  --include "*${BACKUP_SUFFIX}"

