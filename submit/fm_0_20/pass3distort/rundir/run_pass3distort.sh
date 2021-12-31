#!/usr/bin/bash

export HOME=/sphenix/u/${LOGNAME}

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc2.3

echo running: run_pass3distort.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC2/submit/fm_0_20/pass3distort/rundir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
    getinputfiles.pl $3
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: track g4hits input file
# $3: truth g4hits input file
# $4: output dir
# $5: run number
# $6: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(track g4hits file\): $2
echo arg3 \(truth g4hits file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(runnumber\): $5
echo arg6 \(sequence\): $6

runnumber=$(printf "%010d" $5)
sequence=$(printf "%05d" $6)
filename=fm_0_20_pass3distort

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running root.exe -q -b Fun4All_G4_Pass3TrkDistort.C\($1,\"$2\",\"$3\",\"\",\"\",0,\"$4\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename --  root.exe -q -b  Fun4All_G4_Pass3TrkDistort.C\($1,\"$2\",\"$3\",\"\",\"\",0,\"$4\"\)

mkdir -p /sphenix/user/sphnxpro/prmon/fm_0_20/pass3distort

rsync -av $txtfilename /sphenix/user/sphnxpro/prmon/fm_0_20/pass3distort
rsync -av $jsonfilename /sphenix/user/sphnxpro/prmon/fm_0_20/pass3distort

echo "script done"
