#!/usr/bin/bash

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.355

# arguments 
# $1: number of events
# $2: seed
# $3: output file
# $4: output dir

echo number of events \(arg1\): $1
echo seed \(arg2\): $2
echo output file \(arg3\): $3
echo output dir \(arg4\): $4

xmlfile=/cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/MDC/MDC2/generators/sHijing/pAu_0_10fm.xml
echo running sHijing -n $1 -s $2 -o $3  $xmlfile
if [[ ! -f $xmlfile ]]
then
echo could not find $xmlfile
exit 1
fi
if [[ -d $_CONDOR_SCRATCH_DIR ]]
then
  cd $_CONDOR_SCRATCH_DIR
fi
sHijing -n $1 -s $2 -o $3 $xmlfile
rsync -av $3 $4
