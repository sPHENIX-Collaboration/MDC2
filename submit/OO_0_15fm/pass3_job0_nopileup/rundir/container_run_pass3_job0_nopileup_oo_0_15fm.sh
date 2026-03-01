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

anabuild=${5}

source /opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    perl getinputfiles.pl --dd $2
    if [ $? -ne 0 ]
    then
	echo error from perl getinputfiles.pl --dd $2, exiting
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
# $5: build
# $6: run number
# $7: sequence
# $8: git commit id

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(trkr cluster file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(build\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7
echo arg8 \(git commit id\): $8
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $7)
sequence=$(printf "%06d" $8)

echo running root.exe -q -b Fun4All_G4_sPHENIX_job0.C\($1,0,\"$2\",\"$3\",\"$4\",\"$cdbtag\",\"$8\"\)
root.exe -q -b  Fun4All_G4_sPHENIX_job0.C\($1,0,\"$2\",\"$3\",\"$4\",\"$cdbtag\",\"$8\"\)

echo "script done"
