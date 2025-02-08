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

ana_calo=${9}
ana_mbdepd=${9}
ana_pass3trk=${9}

run_calo=${12}
run_mbdepd=${13}
run_trk=${14}

# just to get a working environment, the specific ana builds for each reconstruction are set later
source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
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
# $5: global output file
# $6: global output dir
# $7: track output dir
# $8: jettrigger
# $9: build
# $10: runnumber
# $11: sequence
# $12: enable calo
# $13: enable mbd
# $14: enable trk

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(g4hits file\): $2
echo arg3 \(calo output file\): $3
echo arg4 \(calo output dir\): $4
echo arg5 \(global output file\): $5
echo arg6 \(global output dir\): $6
echo arg7 \(trk output dir\): $7
echo arg8 \(jettrigger\): $8
echo arg9 \(build\): $9
echo arg10 \(runnumber\): ${10}
echo arg11 \(sequence\): ${11}
echo arg12 \(enable calo\): ${12}
echo arg13 \(enable mbd\): ${13}
echo arg14 \(enable trk\): ${14}
echo cdbtag : ${cdbtag}

runnumber=$(printf "%010d" ${10})
sequence=$(printf "%06d" ${11})

#---------------------------------------------------------------
# Calorimeter Reconstruction
if [ ${run_calo} -gt 0 ]
then
    source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_calo
    echo 'here comes your environment for Fun4All_G4_Calo.C'
    cdbtag=MDC2_$ana_calo
    printenv

    echo running root.exe -q -b Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\"\)
    root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\"\)
fi

#---------------------------------------------------------------
# Global Reconstruction
if [ ${run_mbdepd} -gt 0 ]
then
    source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_mbdepd
    echo 'here comes your environment for Fun4All_G4_MBD_EPD.C'
    cdbtag=MDC2_$ana_mbdepd
    printenv

    echo running root.exe -q -b Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$5\",\"$6\",\"$cdbtag\"\)
    root.exe -q -b  Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$5\",\"$6\",\"$cdbtag\"\)
fi

#---------------------------------------------------------------
# pass3 tracking
if [ ${run_trk} -gt 0 ]
then
    source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_pass3trk
    echo 'here comes your environment for Fun4All_G4_Pass3Trk.C'
    cdbtag=MDC2_$ana_pass3trk
    printenv

    echo running root.exe -q -b Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$7\",\"$8\",\"$cdbtag\"\)
    root.exe -q -b  Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$7\",\"$8\",\"$cdbtag\"\)
fi

echo "script done"
