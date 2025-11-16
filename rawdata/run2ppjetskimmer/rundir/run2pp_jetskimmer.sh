#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir

source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.518

hostname

echo running: run_jetskimmer.sh $*

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
# $2: dst outfile1
# $3: dst outfile2
# $4: dst outdir
# $5: qa outfile
# $6: qa outdir


echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(run number\) : $2
echo arg3 \(segment\) : $3
echo arg4 \(input file\): $4
echo arg5 \(dst outfile1\): $5
echo arg6 \(dst outfile2\): $6
echo arg7 \(dst outdir\): $7
echo arg8 \(qa outfile\): $8
echo arg9 \(qa outdir\): $9

runnumber=$(printf "%010d" $2)
getinputfiles.pl -dd $4
if [ $? -ne 0 ]
then
    echo error from getinputfiles.pl -dd $4, exiting
    exit -1
fi
ls -l
echo running root.exe -q -b Fun4All_JetSkimmedProductionYear2.CC\($1,\"$4\",\"$5\",\"$6\",\"$8\"\)
root.exe -q -b Fun4All_JetSkimmedProductionYear2.C\($1,\"$4\",\"$5\",\"$6\",\"$8\"\)
ls -l
if [ -f $5 ]
then
    perl copyscript.pl $5 -dd -mv -outdir $7
else
    echo could not find $5
fi
if [ -f $6 ]
then
    perl copyscript.pl $6 -dd -mv -outdir $7
else
    echo could not find $6
fi
if [ -f $8 ]
then
    perl copyscript.pl $8 -dd -mv -outdir $9
else
    echo could not find $9
fi

echo "script done"
