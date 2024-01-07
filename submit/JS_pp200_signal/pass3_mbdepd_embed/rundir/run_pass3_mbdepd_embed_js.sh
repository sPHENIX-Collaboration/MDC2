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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.391


if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    getinputfiles.pl --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from getinputfiles.pl  --filelist inputfiles.list, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit -1
fi
# arguments 
# $1: number of events
# $2: mbd g4hits input file
# $3: truth g4hits input file
# $4: output file
# $5: output dir
# $6: jet trigger
# $7: run number
# $8: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(mbd g4hits file\): $2
echo arg3 \(truth g4hits file\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo arg6 \(jet trigger\): $6
echo arg7 \(runnumber\): $7
echo arg8 \(sequence\): $8

runnumber=$(printf "%010d" $7)
sequence=$(printf "%05d" $8)

echo running root.exe -q -b Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)
root.exe -q -b  Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)

echo "script done"
