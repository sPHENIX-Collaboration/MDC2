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
    getinputfiles.pl  -dd --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from getinputfiles.pl  --filelist inputfiles.list, exiting
	exit -1
    fi
else
 echo condor scratch NOT set
fi

# arguments 
# $1: number of output events
# $2: bbc g4hits embed file
# $3: output directory
# $4: jettrigger
# $5: build
# $6: run number
# $7: sequence
# $8: fm range

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(g4hits embed file\): $2
echo arg3 \(output dir\): $3
echo arg4 \(jettrigger\): $4
echo arg5 \(build\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7
echo arg8 \(fm range\): $8
echo cdbtag : $cdbtag

runnumber=$(printf "%010d" $6)
sequence=$(printf "%06d" $7)

echo running root.exe -q -b Fun4All_G4_Embed.C\($1,\"$2\",\"$3\",\"$4\",\"$8\",\"$cdbtag\",\"$this_gitcommitid\"\)
root.exe -q -b  Fun4All_G4_Embed.C\($1,\"$2\",\"$3\",\"$4\",\"$8\",\"$cdbtag\",\"$this_gitcommitid\"\)

echo "script done"
