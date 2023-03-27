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
    exit 1
fi
# arguments 
# $1: number of events
# $2: run number
# $3: output file
# $4: output dir
# $5: calo g4hits file list
# $6: vertex file list
# $7: raw run number
# $8: raw sequence
# $9: raw data dir

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(runnumber\): $2
echo arg3 \(sequence\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo arg6 \(calo g4hits file\): $6
echo arg7 \(vertex file\): $7
echo arg8 \(raw runnumber\): $8
echo arg9 \(raw sequence\): $9
echo arg10 \(raw data dir\): ${10}

runnumber=$(printf "%010d" $2)
sequence=$(printf "%05d" $3)
filename=caloreco

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_CaloReco.C\($1,\"$4\",\"$5\",\"$6\",\"$7\",$8,$9,\"${10}\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_CaloReco.C\($1,\"$4\",\"$5\",\"$6\",\"$7\",$8,$9,\"${10}\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/rawdata/caloreco
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname

echo "script done"
