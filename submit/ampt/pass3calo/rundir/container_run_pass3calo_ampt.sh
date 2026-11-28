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
# $2: calo g4hits input file
# $3: output file
# $4: output dir
# $5: build
# $6: pileup
# $7: system
# $8: run number
# $9: sequence
echo Arguments:
echo arg1 \(events\) : $1
echo arg2 \(calo g4hits file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(build\): $5
echo arg6 \(pileup\): $6
echo arg7 \(system\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9
echoo arg10: \(gitcommit id\): ${10}

anabuild=${5}

source /opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild
echo cdbtag: $cdbtag

echo 'here comes your environment'
printenv

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    echo $2 > inputfiles.list
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

runnumber=$(printf "%010d" $8)
sequence=$(printf "%06d" $9)

filename=timing

echo running root.exe -q -b Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\"\"${11}\"\)
root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\",\"${11}\"\)

[[ -f copyscript.sh ]] && sh copyscript.sh

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/ampt/$7/pass3_mbdepd/timing.run${8}/${6}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename


echo "script done"
