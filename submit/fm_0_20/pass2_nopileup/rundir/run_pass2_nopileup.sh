#!/usr/bin/bash

export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc2.6

hostname

echo running: run_pass2_nopileup.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC2/submit/fm_0_20/pass2_nopileup/rundir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: g4hits input file
# $3: calo output file
# $4: calo output dir
# $5: track output dir
# $6: runnumber
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(g4hits file\): $2
echo arg3 \(calo output file\): $3
echo arg4 \(calo output dir\): $4
echo arg5 \(trk output dir\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7

runnumber=$(printf "%010d" $6)
sequence=$(printf "%05d" $7)
filename_calo=fm_0_20_pass2_nopileup_calo
filename_trkr=fm_0_20_pass2_nopileup_trkr

txtfilename=${filename_calo}-${runnumber}-${sequence}.txt
jsonfilename=${filename_calo}-${runnumber}-${sequence}.json

echo running calo  prmon  --filename $txtfilename --json-summary $jsonfilename --  root.exe -q -b Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)

rsync -av $txtfilename /sphenix/user/sphnxpro/prmon/fm_0_20/pass2_nopileup
rsync -av $jsonfilename /sphenix/user/sphnxpro/prmon/fm_0_20/pass2_nopileup

txtfilename=${filename_trkr}-${runnumber}-${sequence}.txt
jsonfilename=${filename_trkr}-${runnumber}-${sequence}.json

echo running prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$5\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$5\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/fm_0_20/pass2_nopileup
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname

echo "script done"
