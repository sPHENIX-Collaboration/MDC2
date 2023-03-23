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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.349


if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    getinputfiles.pl $5
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
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
# $3: ptmin (GeV/c)
# $4: ptmax (GeV/c)
# $5: trkr cluster input file
# $6: output file
# $7: output dir
# $8: run number
# $9: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(particle\) : $2
echo arg3 \(ptmin \(GeV/c\)\) : $3
echo arg4 \(ptmax \(GeV/c\)\) : $4
echo arg5 \(trkr cluster file\): $5
echo arg6 \(output file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9

runnumber=$(printf "%010d" $8)
sequence=$(printf "%05d" $9)
filename=single_pass4_job0_embed_$2

txtfilename0=${filename}-${runnumber}-${sequence}_0.txt
jsonfilename0=${filename}-${runnumber}-${sequence}_0.json

echo running prmon --filename $txtfilename0 --json-summary $jsonfilename0 -- root.exe -q -b Fun4All_G4_sPHENIX_job0.C\($1,0,\"$5\",\"$6\",\"$7\"\)
prmon --filename $txtfilename0 --json-summary $jsonfilename0 -- root.exe -q -b  Fun4All_G4_sPHENIX_job0.C\($1,0,\"$5\",\"$6\",\"$7\"\)


rsyncdirname=/sphenix/user/sphnxpro/prmon/single/pass4_job0_embed_$2/run$8
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilename0 $rsyncdirname
rsync -av $jsonfilename0 $rsyncdirname

echo "script done"
