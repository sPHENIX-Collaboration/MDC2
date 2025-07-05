#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir

source /opt/sphenix/core/bin/sphenix_setup.sh -n new

hostname

echo running: run_waveformfitting.sh $*

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
# $2: dst outfile
# $3: dst outdir
# $4: qa outfile
# $5: qa outdir


echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(run number\) : $2
echo arg3 \(segment\) : $3
echo arg4 \(input file\): $4
echo arg5 \(dst outfile\): $5
echo arg6 \(dst outdir\): $6
echo arg7 \(qa outfile\): $7
echo arg8 \(qa outdir\): $8

runnumber=$(printf "%010d" $2)

ls -l
echo running root.exe -q -b Fun4All_Year2_Calib.C\($1,\"$4\",\"$5\",\"$7\"\)
root.exe -q -b Fun4All_Year2_Calib.C\($1,\"$4\",\"$5\",\"$7\"\)
ls -l
if [ -f $5 ]
then
    copyscript.pl $5 -mv -outdir $6
else
    echo could not find $5
    exit 1
fi
if [ -f $7 ]
then
    copyscript.pl $7 -mv -outdir $8
else
    echo could not find $7
fi

echo "script done"
