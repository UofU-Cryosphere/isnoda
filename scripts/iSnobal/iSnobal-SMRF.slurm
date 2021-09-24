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

ml gcc/8.3.0 intel-mpi/2019.8.254 cdo/1.9.9
source load_conda_env snobedo

smrf_compactor -sd /uufs/chpc.utah.edu/common/home/skiles-group1/erw_isnobal/wy2018/erw/

