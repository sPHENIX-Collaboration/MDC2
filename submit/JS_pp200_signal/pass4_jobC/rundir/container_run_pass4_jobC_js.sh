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

anabuild=${7}

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    echo $3 > inputfiles.list
    echo $4 >> inputfiles.list
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
# $2: jet trigger
# $3: trkr seed input file
# $4: cluster input file
# $5: output file
# $6: output dir
# $7: build
# $8: run number
# $9: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(jet trigger\): $2
echo arg3 \(trkr seed file\): $3
echo arg4 \(cluster file\): $4
echo arg5 \(output file\): $5
echo arg6 \(output dir\): $6
echo arg7 \(build\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $8)
sequence=$(printf "%06d" $9)

filename=timing

echo running root.exe -q -b Fun4All_G4_sPHENIX_jobC.C\($1,0,\"$3\",\"$4\",\"$5\",\"$6\",\"$cdbtag\"\)
root.exe -q -b  Fun4All_G4_sPHENIX_jobC.C\($1,0,\"$3\",\"$4\",\"$5\",\"$6\",\"$cdbtag\"\)

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/js_pp200_signal/pass4_jobC/timing.run${$8}/${2}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

cp -v jobtime.root $rootfilename

echo "script done"
