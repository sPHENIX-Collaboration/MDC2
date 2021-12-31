#!/usr/bin/bash

export HOME=/sphenix/u/${LOGNAME}

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc2.3

echo running: run_hepmc_pp.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
  cd $_CONDOR_SCRATCH_DIR
  rsync -av /sphenix/u/sphnxpro/MDC2/submit/pythia8_pp_mb/pass1/rundir/* .
else
 echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: hepmc input file
# $3: output file
# $4: no events to skip

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(hepmc file\): $2
echo arg3 \(output file\): $3
echo arg5 \(skip\): $4
echo arg6 \(output dir\): $5
echo running root.exe -q -b Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)

prmon  --filename $3.txt --json-summary $3.json -- root.exe -q -b  Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)

mkdir -p /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1
rsync -av $3.txt /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1
rsync -av $3.json /sphenix/user/sphnxpro/prmon/pythia8_pp_mb/pass1
echo "script done"
