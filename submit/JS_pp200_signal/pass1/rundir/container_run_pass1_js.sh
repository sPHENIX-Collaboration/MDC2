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

anabuild=${5}

#source /opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild
source /opt/sphenix/core/bin/sphenix_setup.sh -n new

cdbtag=MDC2_$anabuild


# arguments 
# $1: number of events
# $2: jet trigger
# $3: output file
# $4: output dir
# $5: build
# $6: runnumber
# $7: sequence
# $8: photonjet

echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(jet trigger\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(build\): $5
echo arg6 \(photonjet\): $6
echo arg7 \(runnumber\): $7
echo arg8 \(sequence\): $8
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $7)
sequence=$(printf "%06d" $8)

filename=timing

if [ $6 -eq 0 ]
then
echo running root.exe -q -b Fun4All_G4_JS_pp_signal.C\($1,\"$2\",\"$3\",\"\",0,\"$4\",\"$cdbtag\"\)
root.exe -q -b Fun4All_G4_JS_pp_signal.C\($1,\"$2\",\"$3\",\"\",0,\"$4\",\"$cdbtag\"\)
else
echo running root.exe -q -b Fun4All_G4_PhotonJet_pp_signal.C\($1,\"$2\",\"$3\",\"\",0,\"$4\",\"$cdbtag\"\)
root.exe -q -b Fun4All_G4_PhotonJet_pp_signal.C\($1,\"$2\",\"$3\",\"\",0,\"$4\",\"$cdbtag\"\)
fi

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/js_pp200_signal/pass1/timing.run${6}/${2}

[ ! -d $timedirname ] &&  mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
