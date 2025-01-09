#!/bin/bash

#SBATCH --job-name=HRRR
#SBATCH --account=skiles
#SBATCH --partition=notchpeak

#SBATCH --time=3:00:00
#SBATCH --ntasks=24
#SBATCH --mem=24G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

# standard output directory setup
LOGDIR=$HOME/logs/hrrr_slurmlogs/
if [ ! -e $LOGDIR ] ; then
    mkdir -pv $LOGDIR
fi

# Log some items
echo "Running $0 [$HOME/git_dirs/isnoda/scripts/HRRR/HRRR.slurm] from $SLURM_SUBMIT_DIR"
echo "        with SLURM_JOB_ID:  $SLURM_JOB_ID"
echo "        with SLURM_JOB_PARTITION:  $SLURM_JOB_PARTITION"
echo "        with SLURM_JOB_NODELIST:  $SLURM_JOB_NODELIST"

export OMP_NUM_THREADS=${SLURM_NTASKS}
ml wgrib2

module use $HOME/MyModules
module load miniconda3/latest
conda activate work

cd /uufs/chpc.utah.edu/common/home/skiles-group3/HRRR_CBR
download_script=${HOME}/git_dirs/isnoda/scripts/HRRR/download_hrrr.sh
# cd /uufs/chpc.utah.edu/common/home/skiles-group3/HRRR_feather
# download_script=${HOME}/git_dirs/isnoda/scripts/HRRR/download_hrrr_feather.sh

YEAR=2024
MONTH=09

for NEXT in {0..1}; do
  CURRENT_MONTH=($(date -d "${YEAR}/${MONTH}/01 + ${NEXT} month" "+%m %Y"))
  CURRENT_YEAR=${CURRENT_MONTH[1]}
  CURRENT_MONTH=${CURRENT_MONTH[0]}

  >&1 echo "Processing: ${CURRENT_YEAR}${CURRENT_MONTH}"

  ${download_script} ${CURRENT_YEAR} ${CURRENT_MONTH}

  if [ $? -ne 0 ]; then
    >&2 echo "ERROR processing ${CURRENT_YEAR}${CURRENT_MONTH}"
    exit
  fi
done

# Move log files to log dir
mv slurm-${SLURM_JOB_ID}* $LOGDIR

