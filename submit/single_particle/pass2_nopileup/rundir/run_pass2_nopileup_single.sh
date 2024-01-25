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

ana_calo=ana.398
ana_bbcepd=ana.398
ana_pass3trk=ana.398

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
fi

# arguments 
# $1: number of events
# $2: g4hits input file
# $3: calo output file
# $4: calo output dir
# $5: track output dir
# $6: runnumber
# $7: segment
# $8: filetype

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(g4hits file\): $2
echo arg3 \(calo output file\): $3
echo arg4 \(calo output dir\): $4
echo arg5 \(trk output dir\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(segment\): $7
echo arg8 \(filetype\): $8


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

exit 0

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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $ana_pass3trk

echo 'here comes your environment'
printenv

echo running root.exe -q -b Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$5\",\"$8\"\)
root.exe -q -b  Fun4All_G4_Pass3Trk.C\($1,\"$2\",\"$5\",\"$8\"\)

echo "script done"
