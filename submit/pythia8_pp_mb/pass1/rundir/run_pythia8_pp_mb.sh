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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.348

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
else
    echo condor scratch NOT set
    exit -1
fi

# arguments 
# $1: number of events
# $2: output file
# $3: no events to skip
# $4: output dir
# $5: runnumber
# $6: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(output file\): $2
echo arg3 \(output dir\): $3
echo arg4 \(runnumber\): $4
echo arg5 \(sequence\): $5

runnumber=$(printf "%010d" $4)
sequence=$(printf "%05d" $5)
filename=pythia8_pp_mb_pass1

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running prmon --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\"\)

prmon --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\"\)

mkdir -p /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1/run$4
rsync -av $txtfilename /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1
rsync -av $jsonfilename /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1
echo "script done"
