#!/bin/bash
#SBATCH --partition=rtx3090

#SBATCH --nodes=1

#SBATCH --ntasks-per-node=2

#SBATCH --time=168:00:00

#SBATCH --account=ddp358

#SBATCH --gpus=1

#SBATCH --qos=condo-gpu

#set -xv

echo Running on host $(hostname)
echo "Job id: $SLURM_JOB_ID"
echo "Number of tasks (cores): $SLURM_NTASKS_PER_NODE"
echo "Number of GPUs: $SLURM_GPUS"
echo Time is $(date)
echo Current directory is $(pwd)

env|grep SLURM_

# load gcc environment and amber
module purge
module load gpu slurm
module load gcc/8.5.0-mf5bqu2 intel-mpi/2019.10.317-f7l5rk4
module load amber

#cat > min2.in <<EOF
#
# &cntrl
# imin=1, maxcyc=100000,
# ntpr=1000,
# /
#EOF
#
#$AMBERHOME/bin/pmemd -O -i $PWD/min2.in -p $PWD/complex.prmtop -c $PWD/complex.inpcrd -o $PWD/min2.out -r $PWD/min2.restrt
#
#cat > heat1.in <<EOF
#&cntrl
#   imin=0, irest=0, ntx=1,
#   ntpr=10000, ntwx=10000, nstlim=1000000,
#   dt=0.001, ntt=3, tempi=10,
#   temp0=310, gamma_ln=1.0, ig=-1,
#   ntp=0, ntc=2, ntf=2,
#   ntb=1, nmropt=1
# /
# &wt
#   TYPE='TEMP0', ISTEP1=1, ISTEP2=1000000,
#   VALUE1=10.0, VALUE2=310.0,
# /
# &wt TYPE='END' /
#EOF
#
#$AMBERHOME/bin/pmemd.cuda -O -i $PWD/heat1.in -p $PWD/complex.prmtop -c $PWD/min2.restrt -o $PWD/heat1.out -r $PWD/heat1.rst

cat > heat2.in <<EOF
&cntrl
   imin=0, irest=1, ntx=5,
   ntwr=1000, ntwx=1000, nstlim=1000000,
   dt=0.001, ntt=3,
   temp0=300, gamma_ln=5.0,
   ntp=1, ntc=2, ntf=2,
   ntb=2, taup=2.0
/
EOF

$AMBERHOME/bin/pmemd.cuda -O -i $PWD/heat2.in -p $PWD/complex.prmtop -c $PWD/heat1.rst -o $PWD/heat2.out -r $PWD/heat2.rst

cat > md.in <<EOF
&cntrl
   imin=0, irest=1, ntx=5,
   ntpr=100000, ntwx=100000,
   ntwr=100000, nstlim=500000000,
   iwrap=1,
   dt=0.002, ntt=3, gamma_ln=5,
   temp0=300, ig=-1,
   ntp=1, ntc=2, ntf=2,
   ntb=2, taup=2.0,

   pseudoBD_cycles=250,
   refer_1_start=557, refer_1_end=2561,
   refer_2_start=2598, refer_2_end=4284,
   refer_3_start=4603, refer_3_end=4665,
   solvent_start=4666, solvent_end=44786
/
EOF

/tscc/lustre/ddn/scratch/h9wei/work_4/amber24/bin/pmemd.cuda_SPFP_1126 -O -i $PWD/md.in -p $PWD/complex.prmtop -c $PWD/heat2.rst -o $PWD/md.out -r $PWD/md.rst -x mdcrd


rm *.in
