#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

source /opt/sphenix/core/bin/sphenix_setup.sh -n new

hostname

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: production
# $3: output file
# $4: output dir
# $5: runnumber
# $6: sequence

echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(production\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(runnumber\): $5
echo arg6 \(sequence\): $6

runnumber=$(printf "%010d" $5)
sequence=$(printf "%05d" $6)

macroname=Fun4All_G4_Special_$2.C
if [[ ! -f $macroname ]]
then
  echo could not find $macroname
  exit 1
fi

echo running root.exe -q -b $macroname\($1,\"$3\",\"$4\"\)
root.exe -q -b $macroname\($1,\"$3\",\"$4\"\)

echo "script done"
