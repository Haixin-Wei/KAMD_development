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

cat > min1.in <<EOF

 &cntrl
 imin=1, maxcyc=100000,
 ntpr=1000, nmropt=1
/
&wt
   TYPE='REST', ISTEP1=0, ISTEP2=0,
   VALUE1=1.0, VALUE2=1.0,
/
&wt TYPE='END'
/
DISANG=rst.f
EOF

pmemd.cuda_DPFP -O -i $PWD/min1.in -p $PWD/complex.prmtop -c $PWD/complex.inpcrd -o $PWD/min1.out -r $PWD/min1.restrt

cat > min2.in <<EOF

 &cntrl
 imin=1, maxcyc=100000,
 ntpr=1000, nmropt=1
/
&wt
   TYPE='REST', ISTEP1=0, ISTEP2=0,
   VALUE1=1.0, VALUE2=1.0,
/
&wt TYPE='END'
/
DISANG=rst.f
EOF

pmemd.cuda_SPFP -O -i $PWD/min2.in -p $PWD/complex.prmtop -c $PWD/min1.restrt -o $PWD/min2.out -r $PWD/min2.restrt

cat > heat1.in <<EOF
&cntrl
   imin=0, irest=0, ntx=1,
   ntpr=10000, ntwx=10000, nstlim=500000,
   dt=0.002, ntt=3, tempi=10,
   temp0=310, gamma_ln=1.0, ig=-1,
   ntp=0, ntc=2, ntf=2,
   ntb=1, nmropt=1
 /
 &wt
   TYPE='TEMP0', ISTEP1=1, ISTEP2=500000,
   VALUE1=10.0, VALUE2=310.0,
/
&wt
   TYPE='REST', ISTEP1=0, ISTEP2=0,
   VALUE1=1.0, VALUE2=1.0,
/
&wt TYPE='END'
/
DISANG=rst.f
EOF

pmemd.cuda -O -i $PWD/heat1.in -p $PWD/complex.prmtop -c $PWD/min2.restrt -o $PWD/heat1.out -r $PWD/heat1.rst

cat > heat2.in <<EOF
&cntrl
   imin=0, irest=1, ntx=5,
   ntpr=1000, ntwx=1000, nstlim=500000,
   dt=0.002, ntt=3,
   temp0=293.15, gamma_ln=5.0,
   ntp=1, ntc=2, ntf=2,
   ntb=2, taup=2.0,
   nmropt=1
/
&wt
   TYPE='REST', ISTEP1=0, ISTEP2=0,
   VALUE1=1.0, VALUE2=1.0,
/
&wt TYPE='END'
/
DISANG=rst.f
EOF

pmemd.cuda -O -i $PWD/heat2.in -p $PWD/complex.prmtop -c $PWD/heat1.rst -o $PWD/heat2.out -r $PWD/heat2.rst

cat > md.in <<EOF
&cntrl
   imin=0, irest=1, ntx=5,
   ntpr=100000, ntwx=100000,
   ntwr=100000, nstlim=500000000,
   iwrap=1,
   dt=0.002, ntt=3, gamma_ln=5,
   temp0=293.15, ig=-1,
   ntp=0, ntc=2, ntf=2,
   ntb=1,
   nmropt=1,

   pseudoBD_cycles=250,
   refer_1_start=110, refer_1_end=1502,
   refer_2_start=1680, refer_2_end=3071,
   refer_3_start=3140, refer_3_end=3227,
   solvent_start=3231, solvent_end=48219
/
&wt
   TYPE='REST', ISTEP1=0, ISTEP2=0,
   VALUE1=1.0, VALUE2=1.0,
/
&wt TYPE='END'
/
DISANG=rst.f
EOF

/tscc/lustre/ddn/scratch/h9wei/work_4/amber24/bin/pmemd.cuda_SPFP_1126 -O -i $PWD/md.in -p $PWD/complex.prmtop -c $PWD/heat2.rst -o $PWD/md.out -r $PWD/md.rst -x mdcrd


rm *.in
