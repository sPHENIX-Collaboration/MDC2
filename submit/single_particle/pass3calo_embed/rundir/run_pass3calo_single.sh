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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.376

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    getinputfiles.pl $5
    if [ $? -ne 0 ]
    then
        echo error from getinputfiles.pl $5, exiting
        exit -1
    fi
else
    echo condor scratch NOT set
    hostname
    exit -1
fi
# arguments 
# $1: number of events
# $2: particle
# $3: ptmin
# $4: ptmax
# $5: calo g4hits input file
# $6: output file
# $7: output dir
# $8: jet trigger
# $9: run number
# $10: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(particle\): $2
echo arg3 \(ptmin\): $3
echo arg4 \(ptmax\): $4
echo arg5 \(calo g4hits file\): $5
echo arg6 \(output file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(jettrigger\): $8
echo arg9 \(runnumber\): ${9}
echo arg10 \(sequence\): ${10}

runnumber=$(printf "%010d" ${9})
sequence=$(printf "%05d" ${10})

echo running root.exe -q -b Fun4All_G4_Calo.C\($1,\"$5\",\"$6\",\"$7\"\)
root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$5\",\"$6\",\"$7\"\)

echo "script done"
