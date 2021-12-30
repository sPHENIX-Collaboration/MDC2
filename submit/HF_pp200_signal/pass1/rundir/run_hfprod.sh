#!/usr/bin/bash
export HOME=/sphenix/u/${LOGNAME}
source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc2.3

echo running: run_hfprod.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC2/submit/HF_pp200_signal/pass1/rundir/* .
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: charm or bottom production
# $3: output file
# $4: output dir

echo 'here comes your environment'
#printenv
echo arg1 \(events\) : $1
echo arg2 \(charm or bottom\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo running root.exe -q -b Fun4All_G4_HF_pp_signal.C\($1,\"$2\",\"$3\",\"\",0,\"$4\"\)
prmon  --filename $3.txt --json-summary $3.json -- root.exe -q -b Fun4All_G4_HF_pp_signal.C\($1,\"$2\",\"$3\",\"\",0,\"$4\"\)

mkdir -p /sphenix/user/sphnxpro/prmon/HF_pp200_signal/pass1
rsync -av $3.txt /sphenix/user/sphnxpro/prmon/HF_pp200_signal/pass1
rsync -av $3.json /sphenix/user/sphnxpro/prmon/HF_pp200_signal/pass1

echo "script done"
