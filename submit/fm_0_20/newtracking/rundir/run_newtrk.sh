#!/usr/bin/bash
export HOME=/sphenix/u/${LOGNAME}
echo "running on"

hostname

source /opt/sphenix/core/bin/sphenix_setup.sh -n new

echo running: run_newtrk.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC2/submit/fm_0_20/newtracking/rundir/* .
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
# $2: trkr cluster input file
# $3: output file
# $4: output dir

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(trkr cluster file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo running root.exe -q -b Fun4All_G4_Trkr.C\($1,\"$2\",\"$3\",\"\",0,\"$4\"\)
prmon  --filename $3.txt -- root.exe -q -b  Fun4All_G4_Trkr.C\($1,\"$2\",\"$3\",\"\",0,\"$4\"\)

rsync -av $3.txt /sphenix/user/sphnxpro/prmon/fm_0_20/newtracking

echo "script done"
