#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir

source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.502

hostname

echo running: run_eventcombine.sh $*

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
# $2: runnumber
# $3: daqhost
# $4: output dir


echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(runnumber\): $2
echo arg3 \(daqhost\): $3
echo arg4 \(outdir\): $4

runnumber=$(printf "%010d" $2)

perl CreateListFiles.pl $2 $3
ls -l
echo running root.exe -q -b Fun4All_New_Prdf_Combiner.C\($1,\"$3\",\"$4\"\)
root.exe -q -b Fun4All_New_Prdf_Combiner.C\($1,\"$3\",\"$4\"\)

echo "script done"
