#!/usr/bin/bash
export HOME=/sphenix/u/${LOGNAME}
source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc2.2

echo running: run_pass3calo.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC2/submit/HF_pp200_signal/pass3calo_nopileup/rundir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    hostname
    exit -1
fi
# arguments 
# $1: number of events
# $2: calo g4hits input file
# $3: output file
# $4: output dir

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(calo g4hits file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo running root.exe -q -b Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)
root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)
echo "script done"
