#!/usr/bin/bash

export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.335

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
# $2: hepmc input file
# $3: output file
# $4: no events to skip
# $5: output dir
# $6: runnumber
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(output file\): $2
echo arg4 \(output dir\): $3
echo arg5 \(runnumber\): $4
echo arg6 \(sequence\): $5

runnumber=$(printf "%010d" $4)
sequence=$(printf "%05d" $5)
filename=pythia8_pp_mb_pass1

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running prmon --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\"\)

prmon --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\"\)

mkdir -p /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1
rsync -av $txtfilename /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1
rsync -av $jsonfilename /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1
echo "script done"
