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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.403


if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit -1
fi
# arguments 
# $1: number of events
# $2: g4hits input file
# $3: calo cluster input file
# $4: pedestal input file
# $5: output file
# $6: output dir
# $7: run number
# $8: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(g4hits file\): $2
echo arg3 \(calo cluster file\): $3
echo arg4 \(pedestal file\): $4
echo arg5 \(output file\): $5
echo arg6 \(output dir\): $6
echo arg7 \(runnumber\): $7
echo arg8 \(sequence\): $8

runnumber=$(printf "%010d" $7)
sequence=$(printf "%05d" $8)

echo running root.exe -q -b Fun4All_G4_Waveform.C\($1,\"$2\",\"$3\",\"$4\",\"$5\,\"$6\"\)
root.exe -q -b  Fun4All_G4_Waveform.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\"\)

echo "script done"
