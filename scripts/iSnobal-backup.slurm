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

# Enable CPU Hyper-threading
export OMP_NUM_THREADS=${SLURM_NTASKS}

cd /path/to/backup

# Compress and backup
BACKUP_SUFFIX=".tar.bz2"
START_MONTH=201710

for MONTH in {0..11}; do
  BACKUP_YEAR=$(date -d "${START_MONTH}01 + ${MONTH} month" +%Y%m)

  tar -I pbzip2 -cf run${BACKUP_YEAR}${BACKUP_SUFFIX} run${BACKUP_YEAR}[0-3][0-9]
done

rclone sync . isnoda:ERW_subset/ \
  --transfers ${SLURM_NTASKS} \
  --include "*${BACKUP_SUFFIX}" \
