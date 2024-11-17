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
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: particle
# $3: ptmin
# $4: ptmax
# $5: output file
# $6: output dir
# $7: build
# $8: runnumber
# $9: sequence

echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(particle\): $2
echo arg3 \(ptmin \(MeV\)\): $3
echo arg4 \(ptmax \(MeV\)\): $4
echo arg5 \(output file\): $5
echo arg6 \(output dir\): $6
echo arg7 \(build\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $8)
sequence=$(printf "%05d" $9)

echo running root.exe -q -b Fun4All_G4_Single_pt.C\($1,\"$2\",$3,$4,\"$5\",\"$6\",\"$cdbtag\"\)
root.exe -q -b Fun4All_G4_Single_pt.C\($1,\"$2\",$3,$4,\"$5\",\"$6\",\"$cdbtag\"\)

echo "script done"
