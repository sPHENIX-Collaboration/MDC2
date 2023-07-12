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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.366


if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    echo $4 >> inputfiles.list
    echo $5 >> inputfiles.list
    echo $6 >> inputfiles.list
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
# $2: bbc input file
# $3: calo input file
# $4: trkr input file
# $5: truth input file
# $6: vertex input file
# $7: output dir
# $8: run number
# $9: sequence

outbbc="${2/DSTOLD/DST}"
outcalo="${3/DSTOLD/DST}"
outtrkr="${4/DSTOLD/DST}"
outtruth="${5/DSTOLD/DST}"
outvtx="${6/DSTOLD/DST}"

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(bbcinput file\): $2
echo arg3 \(calo input file\): $3
echo arg4 \(trkr input file\): $4
echo arg5 \(truth input file\): $5
echo arg6 \(vertex input file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9

echo bbc outfile is $outbbc
echo calo outfile is $outcalo
echo trkr outfile is $outtrkr
echo truth outfile is $outtruth
echo vtx outfile is $outvtx

runnumber=$(printf "%010d" $8)
sequence=$(printf "%05d" $9)

echo running root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$2\",\"$outbbc\",\"$7\"\)
root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$2\",\"$outbbc\",\"$7\"\)

echo running root.exe -q -b Fun4All_G4_FixCemcGeo.C\($1,\"$3\",\"$outcalo\",\"$7\"\)
root.exe -q -b Fun4All_G4_FixCemcGeo.C\($1,\"$3\",\"$outcalo\",\"$7\"\)

echo running root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$4\",\"$outtrkr\",\"$7\"\)
root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$4\",\"$outtrkr\",\"$7\"\)

echo running root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$5\",\"$outtruth\",\"$7\"\)
root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$5\",\"$outtruth\",\"$7\"\)

echo running root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$6\",\"$outvtx\",\"$7\"\)
root.exe -q -b Fun4All_G4_FixGeo.C\($1,\"$6\",\"$outvtx\",\"$7\"\)

echo "script done"
