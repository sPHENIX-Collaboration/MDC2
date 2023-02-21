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

source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.347

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: particle
# $3: pmin
# $4: pmax
# $5: number of particles per event
# $6: output file
# $7: output dir
# $8: runnumber
# $9: sequence

echo 'here comes your environment'

printenv

echo arg1 \(events\) : $1
echo arg2 \(particle\): $2
echo arg3 \(pmin \(MeV\)\): $3
echo arg4 \(pmax \(MeV\)\): $4
echo arg5 \(number of particles\): $5
echo arg6 \(output file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9

runnumber=$(printf "%010d" $7)
sequence=$(printf "%05d" $8)
filename=single_$2_$3_$4

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Multiple.C\($1,\"$2\",$3,$4,$5,\"$6\",\"$7\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Multiple.C\($1,\"$2\",$3,$4,$5,\"$6\",\"$7\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/single/pass1_$2_$3_$4

if [ ! -d $rsyncdirname ]
then
mkdir -p $rsyncdirname
fi
rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname


echo "script done"
