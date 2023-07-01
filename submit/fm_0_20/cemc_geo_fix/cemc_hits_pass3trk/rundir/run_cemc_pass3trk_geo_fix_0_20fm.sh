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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.363


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
ls -l
# arguments 
# $1: number of output events
# $2: trkr input file
# $3: truth input file
# $4: output dir
# $5: run number
# $6: sequence

outtrkr="${2/DSTOLD/DST}"
outtruth="${3/DSTOLD/DST}"

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(trkr input file\): $2
echo arg3 \(truth input file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(runnumber\): $5
echo arg6 \(sequence\): $6
echo trkr outfile is $outtrkr
echo truth outfile is $outtruth

runnumber=$(printf "%010d" $5)
sequence=$(printf "%05d" $6)

echo running root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$2\",\"$outtrkr\",\"$4\"\)
root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$2\",\"$outtrkr\",\"$4\"\)

echo running root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$3\",\"$outtruth\",\"$4\"\)
root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$3\",\"$outtruth\",\"$4\"\)

echo "script done"
