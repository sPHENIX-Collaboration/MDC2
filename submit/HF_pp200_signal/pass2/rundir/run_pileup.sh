#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc2.7

hostname

echo running: run_pileup.sh $*

# add to the GSEARCHPATH
cat /etc/auto.direct | grep lustre
if [ $? -ne 0 ]
then
# Lustre not mounted
export GSEARCHPATH=${GSEARCHPATH}:MINIO
else
export GSEARCHPATH=.:PG:LUSTRE:XROOTD:DCACHE
fi

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC2/submit/HF_pp200_signal/pass2/rundir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit -1
fi

# arguments 
# $1: number of output events
# $2: input file
# $3: background listfile
# $4: output directory
# $5: quark filter
# $6: run number
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(input file\): $2
echo arg3 \(background listfile\): $3
echo arg4 \(output dir\): $4
echo arg5 \(quarkfilter\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7

runnumber=$(printf "%010d" $6)
sequence=$(printf "%05d" $7)
filename=HF_pp200_signal_pass2_$5

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json


echo running prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Pileup_pp.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Pileup_pp.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/HF_pp200_signal/pass2_$5
if [ ! -d $rsyncdirname ]
then
mkdir -p $rsyncdirname
fi

rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname


echo "script done"
