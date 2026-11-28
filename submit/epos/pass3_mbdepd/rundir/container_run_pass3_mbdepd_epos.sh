#!/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

# arguments
# $1: number of events
# $2: track g4hits input file
# $3: truth g4hits input file
# $4: output file
# $5: output dir
# $6: build
# $7: pileup
# $8: system
# $9: run number
# $10: sequence
echo Arguments:
echo arg1 \(events\) : $1
echo arg2 \(track g4hits file\): $2
echo arg3 \(truth g4hits file\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo arg6 \(build\): $6
echo arg7 \(pileup\): $7
echo arg8 \(system\): $8
echo arg9 \(runnumber\): $9
echo arg10 \(sequence\): ${10}
echoo arg11: \(gitcommit id\): ${11}
anabuild=${6}

source /opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild
echo cdbtag: $cdbtag

echo 'here comes your environment'
printenv

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    perl getinputfiles.pl --dd  --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from perl getinputfiles.pl --dd --filelist inputfiles.list, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit -1
fi

runnumber=$(printf "%010d" $9)
sequence=$(printf "%06d" ${10})

filename=timing

echo running root.exe -q -b Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",\"$7\",\"$cdbtag\"\"${11}\"\)
root.exe -q -b  Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",\"$7\",\"$cdbtag\",\"${11}\"\)

[[ -f copyscript.sh ]] && sh copyscript.sh

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/epos/$8/pass3_mbdepd/timing.run${9}/${7}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename


echo "script done"
