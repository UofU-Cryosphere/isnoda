#!/bin/bash

#SBATCH --job-name=katana
#SBATCH --account=notchpeak-shared-short
#SBATCH --partition=notchpeak-shared-short

#SBATCH --time=30:00
#SBATCH --ntasks=24
#SBATCH --mem=12G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=umail@utah.edu

#SBATCH --chdir=/path/to/pwd
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

export OMP_NUM_THREADS=${SLURM_NTASKS}

# ml rclone
# cd ${HOME}/scratch/iSnobal
# rclone sync katana_ERW isnoda:katana_ERW/ --transfers ${SLURM_NTASKS}

cd ${HOME}/project-data/iSnobal/katana

./singularity_katana.sh ${HOME}/project-data/iSnobal/ERW/topo/basin_setup/ \
  ${HOME}/scratch/iSnobal/hrrr_CBR \
  ${HOME}/scratch/iSnobal/katana_ERW/

