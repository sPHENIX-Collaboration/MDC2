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

ana_calo=ana.389
ana_mbdepd=ana.389
ana_pass3trk=ana.389

run_calo=1
run_trk=1
run_mbdepd=1

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n

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
else
    echo condor scratch NOT set
    exit 1
fi

# arguments 
# $1: number of events
# $2: g4hits input file
# $3: calo output file
# $4: calo output dir
# $5: global output file
# $6: global output dir
# $7: track output dir
# $8: quarkfilter

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(g4hits file\): $2
echo arg3 \(calo output file\): $3
echo arg4 \(calo output dir\): $4
echo arg5 \(global output file\): $5
echo arg6 \(global output dir\): $6
echo arg7 \(trk output dir\): $7
echo arg8 \(quarkfilter\): $8

#---------------------------------------------------------------
# Calorimeter Reconstruction
if [ ${run_calo} -gt 0 ]
then
    source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_calo
    echo 'here comes your environment for Fun4All_G4_Calo.C'
    printenv
    echo running calo root.exe -q -b Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)
    root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)
fi

#---------------------------------------------------------------
# Mbd/epd Reconstruction
if [ ${run_mbdepd} -gt 0 ]
then
    source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_mbdepd
    echo 'here comes your environment for Fun4All_G4_MBD_EPD.C'
    printenv
    echo root.exe -q -b Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$5\",\"$6\"\)
    root.exe -q -b  Fun4All_G4_MBD_EPD.C\($1,\"$2\",\"$5\",\"$6\"\)
fi

#---------------------------------------------------------------
# pass3 tracking
if [ ${run_trk} -gt 0 ]
then
    source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_pass3trk
    echo 'here comes your environment for Fun4All_G4_Pass3Trk.C'
    printenv
    echo running root.exe -q -b Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$7\",\"$8\"\)
    root.exe -q -b  Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$7\",\"$8\"\)
fi

echo "script done"
