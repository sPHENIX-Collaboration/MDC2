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

source /opt/sphenix/core/bin/sphenix_setup.sh -n $8


if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    getinputfiles.pl $4
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit 1
fi
# arguments 
# $1: number of events
# $2: run number
# $3: sequence
# $4: lfn
# $5: raw data dir
# $6: output file
# $7: output dir
# $8: build tag
# $9: cdb tag

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(runnumber\): $2
echo arg3 \(sequence\): $3
echo arg4 \(lfn\): $4
echo arg5 \(raw data dir\): ${5}
echo arg6 \(output file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(build tag\): $8
echo arg9 \(cdb tag\): $9

runnumber=$(printf "%010d" $2)
sequence=$(printf "%05d" $3)

echo running root.exe -q -b Fun4All_Year1.C\($1,\"$4\",\"$6\",\"$7\",\"$9\"\)
root.exe -q -b  Fun4All_Year1.C\($1,\"$4\",\"$6\",\"$7\",\"$9\"\)

echo "script done"
