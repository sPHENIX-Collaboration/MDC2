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

source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.328



if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    getinputfiles.pl --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from getinputfiles.pl --filelist inputfiles.list, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    hostname
    exit -1
fi

# arguments 
# $1: number of events
# $2: trkr seed input file
# $3: cluster input file
# $4: output file
# $5: output dir
# $6: run number
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(trkr seed file\): $2
echo arg3 \(cluster file\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7

runnumber=$(printf "%010d" $6)
sequence=$(printf "%05d" $7)
filename=fm_0_20_pass4_jobC

txtfilenameC=${filename}-${runnumber}-${sequence}_C.txt
jsonfilenameC=${filename}-${runnumber}-${sequence}_C.json

echo running prmon --filename $txtfilenameC --json-summary $jsonfilenameC -- root.exe -q -b Fun4All_G4_sPHENIX_jobC.C\($1,0,\"$2\",\"$3\",\"$4\",\"$5\"\)
prmon --filename $txtfilenameC --json-summary $jsonfilenameC -- root.exe -q -b  Fun4All_G4_sPHENIX_jobC.C\($1,0,\"$2\",\"$3\",\"$4\",\"$5\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/fm_0_20/pass4_jobC
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilenameC $rsyncdirname
rsync -av $jsonfilenameC $rsyncdirname

echo "script done"
