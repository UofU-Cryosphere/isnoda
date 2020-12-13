#!/bin/bash

#SBATCH --job-name=katana
#SBATCH --account=notchpeak-shared-short
#SBATCH --partition=notchpeak-shared-short

#SBATCH --time=6:00:00
#SBATCH --ntasks=24
#SBATCH --mem=14G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=umail@utah.edu

#SBATCH --chdir=/path/to/pwd
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

export OMP_NUM_THREADS=${SLURM_NTASKS}
ml rclone

START_YEAR=2019
START_MONTH=10

PROJECT_DIR=${HOME}/project-data/iSnobal
OUTPUT_DIR=${HOME}/scratch/iSnobal/katana_ERW/
ARCHIVE_DIR=${HOME}/shared-cyrosphere/iSnobal/

for MONTH in {0..11}; do
  START=($(date -d "${START_MONTH}/01/${START_YEAR} + ${MONTH} month" "+%m %Y"))
  END=($(date -d "${START_MONTH}/01/${START_YEAR} + $((MONTH + 1)) month" "+%m %Y"))

  MONTH=${START[0]}
  YEAR=${START[1]}
  MONTH_END=${END[0]}
  YEAR_END=${END[1]}

  ARCHIVE=katana-${YEAR}${MONTH}.tar.bz2

  echo "Processing: ${YEAR}-${MONTH}"

  cd ${PROJECT_DIR}/katana
  sed -i -e "s/^start_date: .* UTC/start_date: ${YEAR}-${MONTH}-01 00:00:00 UTC/g" katana.ini
  sed -i -e "s/^end_date: .* UTC/end_date: ${YEAR_END}-${MONTH_END}-01 00:00:00 UTC/g" katana.ini

  ./singularity_katana.sh ${PROJECT_DIR}/ERW/topo/basin_setup/ \
    ${HOME}/scratch/iSnobal/hrrr_CBR \
    ${OUTPUT_DIR} &1>2

  echo "  Archiving"

  cd ${OUTPUT_DIR}
  tar -I pbzip2 -cf ${ARCHIVE_DIR}/katana/${ARCHIVE} data${YEAR}${MONTH}[0-3][0-9]

  echo "  Backup"

  cd ${ARCHIVE_DIR}
  rclone sync --include '*.bz2' katana/ isnoda:ERW_subset/katana/ --transfers 6
done
