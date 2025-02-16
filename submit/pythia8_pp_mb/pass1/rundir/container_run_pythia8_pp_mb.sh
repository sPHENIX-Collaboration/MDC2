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

anabuild=${4}

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

# arguments 
# $1: number of events
# $2: output file
# $3: output dir
# $4: build
# $5: runnumber
# $6: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(output file\): $2
echo arg3 \(output dir\): $3
echo arg4 \(build\): $4
echo arg5 \(runnumber\): $5
echo arg6 \(sequence\): $6
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $5)
sequence=$(printf "%06d" $6)

filename=timing

echo running root.exe -q -b Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\",\"$cdbtag\"\)

root.exe -q -b  Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\",\"$cdbtag\"\)

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/pythia8_pp_mb/pass1/timing.run${5}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
