#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo running: $this_script $*

anabuild=${7}

source /opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild
if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR # redundant but in case someone screw this up and we fill the home disk
    perl getinputfiles.pl -dd $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl -dd $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit -1
fi

# arguments 
# $1: number of output events
# $2: input file
# $3: background listfile
# $4: output file
# $5: output directory
# $6: jettrigger
# $7: build
# $8: pileup (in kHz)
# $9: run number
# $10: sequence
# $11: git commit id

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(input file\): $2
echo arg3 \(background listfile\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo arg6 \(jettrigger\): $6
echo arg7 \(build\): $7
echo arg8 \(pileup\): $8
echo arg9 \(runnumber\): $9
echo arg10 \(sequence\): ${10}
echo arg11 \(git commit id\): ${11}
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $9)
sequence=$(printf "%06d" ${10})

filename=timing

echo running root.exe -q -b Fun4All_G4_Pileup_HepMC.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",$8,\"$cdbtag\",\"${11}\"\)
root.exe -q -b  Fun4All_G4_Pileup_HepMC.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",$8,\"$cdbtag\",\"${11}\"\)

[[ -f copyscript.sh ]] && sh copyscript.sh

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/js_pp200_signal/pass2_hepmc/timing.run${8}/${5}

[ ! -d $timedirname ] &&  mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
