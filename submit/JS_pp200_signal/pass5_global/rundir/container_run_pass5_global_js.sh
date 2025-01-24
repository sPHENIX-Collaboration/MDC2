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

anabuild=${6}

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    getinputfiles.pl --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from getinputfiles.pl --filelist inputfiles.list, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    hostname
    exit -1
fi

# arguments 
# $1: number of events
# $2: tracks input file
# $3: mbd_epd input file
# $4: output file
# $5: output dir
# $6: build
# $7: run number
# $8: sequence
# $9: git commit id

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(tracks file\): $2
echo arg3 \(mbd/epd file\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo arg6 \(build\): $6
echo arg7 \(runnumber\): $7
echo arg8 \(sequence\): $8
echo arg9 \(git commit id\): $9
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $6)
sequence=$(printf "%06d" $7)

echo running root.exe -q -b Fun4All_G4_Global.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$cdbtag\",\"$9\"\)
root.exe -q -b  Fun4All_G4_Global.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$cdbtag\",\"$9\"\)

echo "script done"
