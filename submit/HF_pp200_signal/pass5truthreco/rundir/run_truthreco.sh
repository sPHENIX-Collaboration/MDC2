#! /bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.319

hostname

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
    getinputfiles.pl $3
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $3, exiting
	exit -1
    fi
    getinputfiles.pl $4
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $4, exiting
	exit -1
    fi
    getinputfiles.pl $5
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $5, exiting
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
# $10" quarkfilter

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(dst_trkr_g4hit\): $2
echo arg3 \(dst_trkr_cluster\): $3
echo arg4 \(dst_tracks\): $4
echo arg5 \(dst_truth\): $5
echo arg6 \(output file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9
echo arg10 \(quarkfilter\): $10

runnumber=$(printf "%010d" $8)
sequence=$(printf "%05d" $9)
filename=HF_pp200_signal_pass5_truthreco_$10

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running root.exe -q -b Fun4All_TruthReco.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",\"$7\"\)
root.exe -q -b  Fun4All_TruthReco.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",\"$7\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/HF_pp200_signal/pass5_truthreco_$10
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname

echo "script done"
