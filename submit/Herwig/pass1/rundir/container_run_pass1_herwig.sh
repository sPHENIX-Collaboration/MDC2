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

source /opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
else
   echo condor scratch NOT set
   exit -1
fi

# arguments 
# $1: number of events
# $2: hepmc input file
# $3: output file
# $4: no events to skip
# $5: output dir
# $6: build
# $7: jet trigger
# $8: runnumber
# $9: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(hepmc file\): $2
echo arg3 \(output file\): $3
echo arg4 \(skip\): $4
echo arg5 \(output dir\): $5
echo arg6 \(build\): $6
echo arg7 \(jet trigger\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $8)
sequence=$(printf "%06d" $9)

filename=timing

echo running root.exe -q -b Fun4All_G4_Pass1_herwig.C\($1,\"$2\",\"$3\",$4,\"$5\",\"$cdbtag\"\)
 root.exe -q -b  Fun4All_G4_Pass1_herwig.C\($1,\"$2\",\"$3\",$4,\"$5\",\"$cdbtag\"\)

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/herwig/pass1/timing.run${8}/${7}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
