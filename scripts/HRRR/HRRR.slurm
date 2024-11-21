#!/bin/bash

#SBATCH --job-name=HRRR
#SBATCH --account=notchpeak-shared-short
#SBATCH --partition=notchpeak-shared-short

#SBATCH --time=6:00:00
#SBATCH --ntasks=12
#SBATCH --mem=1G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --chdir=/path/to/scratch/
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

export OMP_NUM_THREADS=${SLURM_NTASKS}
ml wgrib2

YEAR=2018
MONTH=09

cd ${HOME}/skiles-group1/HRRR_CBR

for NEXT in {0..2}; do
  CURRENT_MONTH=($(date -d "${YEAR}/${MONTH}/01 + ${NEXT} month" "+%m %Y"))
  CURRENT_YEAR=${CURRENT_MONTH[1]}
  CURRENT_MONTH=${CURRENT_MONTH[0]}

  >&1 echo "Processing: ${CURRENT_YEAR}${CURRENT_MONTH}"

  ${HOME}/projects/ARS/isnoda/scripts/HRRR/download_hrrr.sh ${CURRENT_YEAR} ${CURRENT_MONTH}

  if [ $? -ne 0 ]; then
    >&2 echo "ERROR processing ${CURRENT_YEAR}${CURRENT_MONTH}"
    exit
  fi
done
