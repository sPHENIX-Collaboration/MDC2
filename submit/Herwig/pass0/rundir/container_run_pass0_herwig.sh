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
# $10: mdc2 git commit id

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(jet trigger\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(build\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7
echo arg8 \(git commit id\): $8
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $6)
sequence=$(printf "%06d" $7)

filename=timing

echo running root.exe -q -b Fun4All_G4_Pass0_herwig.C\($1,\"$3\",\"$4\",\"$2\",\"$cdbtag\",\"$8\"\)
root.exe -q -b  Fun4All_G4_Pass0_herwig.C\($1,\"$3\",\"$4\",\"$2\",\"$cdbtag\",\"$8\"\)

[[ -f copyscript.sh ]] && sh copyscript.sh

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/Herwig/pass0/timing.run${6}/${7}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
