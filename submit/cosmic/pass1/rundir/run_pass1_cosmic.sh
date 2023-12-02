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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.391

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
else
    echo condor scratch NOT set
    exit 1
fi

# arguments 
# $1: number of events
# $2: output file
# $3: output dir
# $4: magnetic field on/off
# $5: runnumber
# $6: sequence

echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(output file\): $2
echo arg3 \(output dir\): $3
echo arg4 \(magnetic field\): $4
echo arg5 \(runnumber\): $5
echo arg6 \(sequence\): $6

runnumber=$(printf "%010d" $5)
sequence=$(printf "%05d" $6)

echo running root.exe -q -b Fun4All_G4_Cosmic.C\($1,\"$2\",\"$3\",\"$4\"\)
root.exe -q -b Fun4All_G4_Cosmic.C\($1,\"$2\",\"$3\",\"$4\"\)

echo "script done"
