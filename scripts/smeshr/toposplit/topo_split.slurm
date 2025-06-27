#!/bin/bash

#SBATCH --job-name=Topo-Split
#SBATCH --account=owner-guest
#SBATCH --partition=notchpeak-guest

#SBATCH --time=1:00:00
#SBATCH --ntasks=8
#SBATCH --mem=12G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=email@address.com

#SBATCH --chdir=/scratch/general/vast/<UNID>
#SBATCH --output=slurm-%j.out-%N
#SBATCH --error=slurm-%j.err-%N

export OMP_NUM_THREADS=${SLURM_NTASKS}

source load_conda_env smeshr

toposplit_day() {
  python topo_split_batch.py $1
}
export -f toposlit_day

cd /path/to/python/files

# Process one month at a time
FOLDERS=$(find /path/to/HRRR/data/ -type d -maxdepth 1 -name hrrr.202110*)

parallel --tag --line-buffer --jobs 2 toposplit_day ::: ${FOLDERS}
