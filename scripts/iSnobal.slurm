#!/bin/bash

#SBATCH --job-name=iSnobal
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

cd ${HOME}/scratch/iSnobal/hrrr_CBR
${HOME}/projects/ARS/isnoda/scripts/download_hrrr.sh 2018 09

cd ${HOME}/scratch/iSnobal
rclone sync hrrr_CBR isnoda:HRRR_CBR/ --transfers ${SLURM_NTASKS}
