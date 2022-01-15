#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc2.3

hostname
echo running: run_hfprod.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC2/submit/HF_pp200_signal/pass1/rundir/* .
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: charm or bottom production
# $3: output file
# $4: output dir

echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(charm or bottom\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(runnumber\): $5
echo arg6 \(sequence\): $6

runnumber=$(printf "%010d" $5)
sequence=$(printf "%05d" $6)
filename=HF_pp200_signal_pass1_$2

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running root.exe -q -b Fun4All_G4_HF_pp_signal.C\($1,\"$2\",\"$3\",\"\",0,\"$4\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_HF_pp_signal.C\($1,\"$2\",\"$3\",\"\",0,\"$4\"\)

mkdir -p /sphenix/user/sphnxpro/prmon/HF_pp200_signal/pass1_$2
rsync -av $txtfilename /sphenix/user/sphnxpro/prmon/HF_pp200_signal/pass1_$2
rsync -av $jsonfilename /sphenix/user/sphnxpro/prmon/HF_pp200_signal/pass1_$2

echo "script done"
