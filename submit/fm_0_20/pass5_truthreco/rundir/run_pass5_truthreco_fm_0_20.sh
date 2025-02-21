#! /bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

anabuild=${8}

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    echo $4 >> inputfiles.list
    echo $5 >> inputfiles.list
    getinputfiles.pl --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from getinputfiles.pl --filelist inputfiles.list, exiting
	exit -1
    fi
else
 echo condor scratch NOT set
 exit 1
fi

# arguments 
# $1: number of output events
# $2: dst_trkr_g4hit
# $3: dst_trkr_cluster
# $4: dst_tracks
# $5: dst_truth
# $6: output file
# $7: output directory
# $8: run number
# $9: sequence

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(dst_trkr_g4hit\): $2
echo arg3 \(dst_trkr_cluster\): $3
echo arg4 \(dst_tracks\): $4
echo arg5 \(dst_truth\): $5
echo arg6 \(output file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(build\): $8
echo arg9 \(runnumber\): $9
echo arg10 \(sequence\): ${10}

runnumber=$(printf "%010d" $9)
sequence=$(printf "%06d" ${10})

echo running root.exe -q -b Fun4All_TruthReco.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",\"$7\",\"$cdbtag\"\)
root.exe -q -b  Fun4All_TruthReco.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",\"$7\",\"$cdbtag\"\)

echo "script done"
