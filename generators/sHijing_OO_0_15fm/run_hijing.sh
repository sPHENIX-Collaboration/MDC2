#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`

source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.530

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    cp $this_dir/OO_0_15fm.xml .
else
    echo condor scratch NOT set
    hostname
    exit -1
fi

# arguments 
# $1: number of events
# $2: seed
# $3: output file
# $4: output dir

echo number of events \(arg1\): $1
echo seed \(arg2\): $2
echo output file \(arg3\): $3
echo output dir \(arg4\): $4

xmlfile=OO_0_15fm.xml
echo running sHijing -n $1 -s $2 -o $3  $xmlfile
if [[ ! -f $xmlfile ]]
then
echo could not find $xmlfile
exit 1
fi
sHijing -n $1 -s $2 -o $3 $xmlfile
dd if=$3 of=$4/$3 bs=12M 2>&1

