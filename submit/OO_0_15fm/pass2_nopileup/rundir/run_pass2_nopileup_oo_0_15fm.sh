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

# check the current tag (if exist), if no tag, save commit id
this_gitcommitid=`git describe --exact-match --tags 2> /dev/null`
if [ $? != 0 ]
then
 this_gitcommitid=`git show HEAD | sed -n 1p | cut -d " " -f 2`
fi

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
else
    echo condor scratch NOT set
    exit 1
fi

container_script=container_`basename $this_script`
#singularity exec -B /home -B /direct/sphenix+u -B /gpfs02 -B /sphenix/u -B /sphenix/lustre01 -B /sphenix/user  -B /sphenix/sim -B /sphenix/cvmfscalib

./$container_script $* $this_gitcommitid

echo "wrapper script done"
