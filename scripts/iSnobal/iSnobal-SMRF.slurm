#!/bin/bash

#SBATCH --job-name=iSnobal
#SBATCH --account=notchpeak-gpu
#SBATCH --partition=notchpeak-gpu

#SBATCH --time=2:00:00
#SBATCH --ntasks=8
#SBATCH --mem=8G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --chdir=/path/to/scratch/
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

export OMP_NUM_THREADS=${SLURM_NTASKS}

module load cdo
source load_conda_env snobedo

SOURCE_FOLDER=/uufs/chpc.utah.edu/common/home/skiles-group1/erw_isnobal/wy2018/erw

smrf_compactor -sd ${SOURCE_FOLDER}
smrf_compactor -sd ${SOURCE_FOLDER} -eb

parallel --jobs ${OMP_NUM_THREADS} nccopy -s -u -d4 {} {.}_c.nc ::: ${SOURCE_FOLDER}/run*/{em,precip,snow}.nc
rename _c.nc .nc ${SOURCE_FOLDER}/run*/{em,precip,snow}_c.nc
