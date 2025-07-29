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

# check the current tag (if exist), if no tag, save commit id
this_gitcommitid=`git describe --exact-match --tags 2> /dev/null`
if [ $? != 0 ]
then
 this_gitcommitid=`git show HEAD | sed -n 1p | cut -d " " -f 2`
fi

anabuild=${5}

source /opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
    cat $3 >> inputfiles.list
    getinputfiles.pl -filelist inputfiles.list
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
# $1: number of output events
# $2: input file
# $3: background listfile
# $4: output directory
# $5: build
# $6: run number
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(input file\): $2
echo arg3 \(background listfile\): $3
echo arg4 \(output dir\): $4
echo arg5 \(build\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $6)
sequence=$(printf "%06d" $7)

echo running root.exe -q -b Fun4All_G4_Pileup.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\",\"$this_gitcommitid\"\)
root.exe -q -b  Fun4All_G4_Pileup.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\",\"$this_gitcommitid\"\)

echo "script done"
