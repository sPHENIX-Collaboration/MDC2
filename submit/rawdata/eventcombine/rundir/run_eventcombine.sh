#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir

source /opt/sphenix/core/bin/sphenix_setup.sh

hostname

echo running: run_eventcombine.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: runnumber
# $3: sequence
# $4: input dir


echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(runnumber\): $2
echo arg3 \(sequence\): $3
echo arg4 \(input dir\): $4

runnumber=$(printf "%010d" $5)
sequence=$(printf "%05d" $6)

echo running root.exe -q -b Fun4All_G4_EventCombine.C\($1,$2,$3,\"$4\"\)
root.exe -q -b Fun4All_G4_EventCombine.C\($1,$2,$3,\"$4\"\)

echo "script done"
