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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.349

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $5 > inputfiles.list
    echo $6 >> inputfiles.list
    getinputfiles.pl  --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
        echo error from getinputfiles.pl  --filelist inputfiles.list, exiting
        exit -1
    fi
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: particle
# $3: ptmin (GeV/c)
# $4: ptmax (GeV/c)
# $5: track g4hits input file
# $6: truth g4hits input file
# $7: output dir
# $8: run number
# $9: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(particle\) : $2
echo arg3 \(ptmin \(GeV/c\)\) : $3
echo arg4 \(ptmax \(GeV/c\)\) : $4
echo arg5 \(track g4hits file\): $5
echo arg6 \(truth g4hits file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9

runnumber=$(printf "%010d" $8)
sequence=$(printf "%05d" $9)

echo running root.exe -q -b Fun4All_G4_Pass3Trk.C\($1,\"$2\",$3,$4,\"$5\",\"$6\",\"$7\"\)
root.exe -q -b  Fun4All_G4_Pass3Trk.C\($1,\"$2\",$3,$4,\"$5\",\"$6\",\"$7\"\)

echo "script done"
