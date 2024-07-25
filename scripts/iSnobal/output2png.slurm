#!/bin/bash

#SBATCH --job-name=iSnobal
#SBATCH --account=owner-guest
#SBATCH --partition=notchpeak-guest

#SBATCH --time=8:00:00
#SBATCH --ntasks=2
#SBATCH --mem=12G

#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=user@utah.edu

#SBATCH --output=slurm-%j_outpng.out-%N
#SBATCH --error=slurm-%j_outpng.err-%N

# standard output directory setup
LOGDIR=$HOME/isnobal_slurmlogs/
if [ ! -e $LOGDIR ] ; then
    mkdir -pv $LOGDIR
fi

# Log some items
echo "Running $0 [$HOME/git_dirs/isnoda/scripts/iSnobal/output2png.slurm] from $SLURM_SUBMIT_DIR"
echo "        with SLURM_JOB_ID:  $SLURM_JOB_ID"
echo "        with SLURM_JOB_PARTITION:  $SLURM_JOB_PARTITION"
echo "        with SLURM_JOB_NODELIST:  $SLURM_JOB_NODELIST"

module use $HOME/MyModules
module load miniconda3/latest
conda activate work

# basindir contains all the daily model runs
# basindir=/uufs/chpc.utah.edu/common/home/skiles-group1/jmhu/test/erw_isnobal/wy2023/erw
basindir=$1

parallel "echo output_pngs.py {}; output_pngs.py {}" ::: ${basindir}/run*/

# Move log files to log dir
mv slurm-${SLURM_JOB_ID}* $LOGDIR
