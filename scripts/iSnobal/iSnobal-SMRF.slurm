#!/bin/bash

#SBATCH --job-name=iSnobal-SMRF
#SBATCH --account=notchpeak-gpu
#SBATCH --partition=notchpeak-gpu

#SBATCH --time=24:00:00
#SBATCH --ntasks=24
#SBATCH --mem=12G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --chdir=/path/to/scratch
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

# Enable CPU Hyper-threading
export OMP_NUM_THREADS=48

source load_conda_env isnoda

cd /path/to/SMRF/out_location/

for DAY in run*; do
  run_smrf $DAY/config.ini
done

