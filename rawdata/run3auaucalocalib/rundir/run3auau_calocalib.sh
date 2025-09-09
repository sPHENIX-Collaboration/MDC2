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

echo running: run3auau_calocalib.sh $*

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
# $5: dst outfile
# $6: dst outdir
# $7: qa outfile
# $8: qa outdir
# $9: calib ep outfile
# $10: calib ep outdir


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
echo arg9 \(calib ep outfile\): $9
echo arg10 \(calib ep outdir\): ${10}

runnumber=$(printf "%010d" $2)

getinputfiles.pl -dd $4
if [ $? -ne 0 ]
then
    echo error from getinputfiles.pl  $4, exiting
    exit -1
fi
ls -l
echo running root.exe -q -b Fun4All_Year2_Calib.C\($1,\"$4\",\"$5\",\"$7\",\"$9\"\)
root.exe -q -b Fun4All_Year2_Calib.C\($1,\"$4\",\"$5\",\"$7\",\"$9\"\)
ls -l
if [ -f $5 ]
then
    copyscript.pl $5 -dd -mv -outdir $6
else
    echo could not find $5
    exit 1
fi
if [ -f $7 ]
then
    copyscript.pl $7 -dd -mv -outdir $8
else
    echo could not find $7
fi
if [ -f $9 ]
then
    copyscript.pl $9 -dd -mv -outdir ${10}
else
    echo could not find $9
fi

echo "script done"
