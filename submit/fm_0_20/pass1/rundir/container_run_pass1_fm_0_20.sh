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


# arguments 
# $1: number of events
# $2: hepmc input file
# $3: output file
# $4: no events to skip
# $5: output dir
# $6: build
# $7: runnumber
# $8: sequence
# $9: git commit id

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(hepmc file\): $2
echo arg3 \(output file\): $3
echo arg4 \(skip\): $4
echo arg5 \(output dir\): $5
echo arg6 \(build\): $6
echo arg7 \(runnumber\): $7
echo arg8 \(sequence\): $8
echo arg9 \(git commit id\): $9
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $7)
sequence=$(printf "%06d" $8)

filename=timing

echo running root.exe -q -b Fun4All_G4_Pass1.C\($1,\"$2\",\"$3\",$4,\"$5\",\"$cdbtag\",\"$9\"\)
 root.exe -q -b  Fun4All_G4_Pass1.C\($1,\"$2\",\"$3\",$4,\"$5\",\"$cdbtag\",\"$9\"\)

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/shijing_hepmc/fm_0_20/pass1/timing.run${7}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
