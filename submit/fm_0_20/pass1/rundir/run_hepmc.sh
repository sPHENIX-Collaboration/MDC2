#!/usr/bin/bash

export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc2.6

hostname

echo running: run_hepmc.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
  cd $_CONDOR_SCRATCH_DIR
  rsync -av /sphenix/u/sphnxpro/MDC2/submit/fm_0_20/pass1/rundir/* .
else
 echo condor scratch NOT set
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
echo arg2 \(hepmc file\): $2
echo arg3 \(output file\): $3
echo arg4 \(skip\): $4
echo arg5 \(output dir\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7

runnumber=$(printf "%010d" $7)
sequence=$(printf "%05d" $7)
filename=fm_0_20_pass1
txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running root.exe -q -b Fun4All_G4_Pass1.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename --  root.exe -q -b  Fun4All_G4_Pass1.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)

rsync -av $txtfilename /sphenix/user/sphnxpro/prmon/fm_0_20/pass1
rsync -av $jsonfilename /sphenix/user/sphnxpro/prmon/fm_0_20/pass1

echo "script done"
