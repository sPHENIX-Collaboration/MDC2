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
# $4: qa outfile1
# $5: qa outfile2
# $6: qa outdir


echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(run number\) : $2
echo arg3 \(segment\) : $3
echo arg4 \(dst outfile\): $4
echo arg5 \(dst outdir\): $5
echo arg6 \(qa outfile1\): $6
echo arg7 \(qa outfile2\): $7
echo arg8 \(qa outdir\): $8

runnumber=$(printf "%010d" $2)

perl CreateListFiles.pl $2 $3
getinputfiles.pl -dd --filelist files.list
if [ $? -ne 0 ]
then
    cat inputfiles.list
    echo error from getinputfiles.pl  --filelist inputfiles.list, exiting
    exit -1
fi
ls -l
echo running root.exe -q -b Fun4All_New_HCalCosmics.C\($1,\"files.list\",\"$4\",\"$6\",\"$7\"\)
root.exe -q -b Fun4All_New_HCalCosmics.C\($1,\"files.list\",\"$4\",\"$6\",\"$7\"\)
ls -l
if [ -f $4 ]
then
    copyscript.pl $4 -dd -mv -outdir $5
else
    echo could not find $4
fi
if [ -f $6 ]
then
    copyscript.pl $6 -dd -mv -outdir $8
else
    echo could not find $6
fi
if [ -f $7 ]
then
    copyscript.pl $7 -dd -mv -outdir $8
else
    echo could not find $7
fi

echo "script done"
