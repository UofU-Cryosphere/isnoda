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

## Update these variables with the actual paths ##
INPUT_DIR=${HOME}/skiles-group1/HRRR_CBR/

BASIN_SETUP=/path/to/basin_setup/

KATANA_DIR=/path/to/katana/config_and_image/
KATANA_OUTPUT_DIR=/path/to/katana/output/
## -------------------------------------------- ##
KATANA_INI=${KATANA_DIR}/katana.ini

BACKUP_DESTINATION="isnoda:ERW_subset/katana/"

for MONTH in {0..11}; do
  START=($(date -d "${START_MONTH}/01/${START_YEAR} + ${MONTH} month" "+%m %Y"))
  END=($(date -d "${START_MONTH}/01/${START_YEAR} + $((MONTH + 1)) month" "+%m %Y"))

  MONTH=${START[0]}
  YEAR=${START[1]}
  MONTH_END=${END[0]}
  YEAR_END=${END[1]}

  echo "Processing: ${YEAR}-${MONTH}"

  # Update the config to the month processed
  sed -i -e "s/^start_date: .* UTC/start_date: ${YEAR}-${MONTH}-01 00:00:00 UTC/g" ${KATANA_INI}
  sed -i -e "s/^end_date: .* UTC/end_date: ${YEAR_END}-${MONTH_END}-01 00:00:00 UTC/g" ${KATANA_INI}

  # Backup the used configuration of the processed month
  cp ${KATANA_INI} ${KATANA_OUTPUT_DIR}katana_${YEAR}${MONTH}.ini

  ${KATANA_DIR}/katana_singularity.sh ${BASIN_SETUP} \
    ${INPUT_DIR} \
    ${KATANA_OUTPUT_DIR} 1>&2

  if [ $? -ne 0 ]; then
    >&2 echo "ERROR processing ${YEAR}${MONTH}"
    continue
  fi

  ## ------------------------------------------------------------------ ##
  # Below archiving requires the `rclone` command to be setup. It also
  # uses the `pbzip2` command to create the archive with parallel
  # processes.
  # Currently this uses a remote destination with the alias `isnoda`.
  # The destination can be changed via the $BACKUP_DESTINATION variable.
  ## ------------------------------------------------------------------ ##

  echo "  Archiving"
  ARCHIVE=katana-${YEAR}${MONTH}.tar.bz2

  cd ${KATANA_OUTPUT_DIR}
  tar -I pbzip2 -cf ${KATANA_OUTPUT_DIR}${ARCHIVE} data${YEAR}${MONTH}[0-3][0-9]
  cp katana.log katana_${YEAR}${MONTH}.log

  echo "  Backup to remote destination: ${BACKUP_DESTINATION}"

  rclone copy --include '*.bz2' ${ARCHIVE} ${BACKUP_DESTINATION}
  if [ $? -eq 0 ]; then
    rm ${ARCHIVE}
  fi
done
