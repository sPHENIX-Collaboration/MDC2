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

this_gitcommitid=`git show HEAD | sed -n 1p | cut -d " " -f 2`

anabuild=${5}

source /opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
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

# arguments 
# $1: number of events
# $2: bbc_epd input file
# $3: output file
# $4: output dir
# $5: build
# $6: run number
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(bbc/epd file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(build\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7
echo cdbtag: $cdbtag
echo git commit id: $this_gitcommitid

runnumber=$(printf "%010d" $6)
sequence=$(printf "%06d" $7)

filename=timing

echo running root.exe -q -b Fun4All_G4_Global.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\",\"$this_gitcommitid\"\)
root.exe -q -b  Fun4All_G4_Global.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\",\"$this_gitcommitid\"\)

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/shijing_hepmc/fm_0_20/pass3_global_nopileup/timing.run${6}

[ ! -d $timedirname ] &&  mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
