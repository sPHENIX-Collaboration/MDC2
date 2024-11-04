#!/usr/bin/bash

export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

anabuild=${4}

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
else
    echo condor scratch NOT set
    exit -1
fi

singularity exec -B /home -B /sphenix/u -B /sphenix/lustre01 -B /gpfs02 /cvmfs/sphenix.sdcc.bnl.gov/singularity/rhic_sl7_ext.sif ./run_pythia8_container_pp_mb.sh $*


echo "wrapper script done"
