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

source /opt/sphenix/core/bin/sphenix_setup.sh

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
filename=eventcombine

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_Pass1_Tracking.C\($1,$2,$3,\"$4\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_Pass1_Tracking.C\($1,$2,$3,\"$4\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/rawdata/pass1_tracking

if [ ! -d $rsyncdirname ]
then
mkdir -p $rsyncdirname
fi
rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname


echo "script done"
