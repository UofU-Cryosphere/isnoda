#!/bin/bash

#SBATCH --job-name=HRRR
#SBATCH --account=notchpeak-shared-short
#SBATCH --partition=notchpeak-shared-short

#SBATCH --time=2:00:00
#SBATCH --ntasks=8
#SBATCH --mem=1G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --chdir=/path/to/scratch/
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

ml wgrib2 rclone

YEAR=2018
MONTH=09

cd ${HOME}/skiles-group1/HRRR_CBR
${HOME}/projects/ARS/isnoda/scripts/HRRR/download_hrrr.sh ${YEAR} ${MONTH}

if [ $? -ne 0 ]; then
  >&2 echo "ERROR processing ${YEAR}${MONTH}"
  exit
fi

ARCHIVE="hrrr${YEAR}${MONTH}.tar.bz2"
tar -I pbzip2 -cf ${ARCHIVE} hrrr.${YEAR}${MONTH}[0-3][0-9]

rclone copy $ARCHIVE isnoda:HRRR_CBR/
rm $ARCHIVE
