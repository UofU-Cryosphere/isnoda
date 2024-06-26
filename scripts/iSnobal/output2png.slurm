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

# Enable CPU Hyper-threading
export OMP_NUM_THREADS=${SLURM_NTASKS}

module use $HOME/MyModules
module load miniconda3/latest
conda activate work

#rundir=/uufs/chpc.utah.edu/common/home/skiles-group1/jmhu/test/erw_isnobal/wy2023/erw
rundir=$1
for f in ${rundir}/run202107*/
do 
    echo output_pngs.py ${f}
    output_pngs.py ${f}
done

# Move log files to log dir
mv slurm-${SLURM_JOB_ID}* $LOGDIR
