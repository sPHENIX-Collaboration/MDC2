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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.349


if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    echo $4 >> inputfiles.list
    echo $5 >> inputfiles.list
    echo $6 >> inputfiles.list
    getinputfiles.pl  --filelist inputfiles.list
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
# $3: calo g4hits embed file
# $4: track g4hits embed file
# $5: truth g4hits embed file
# $6: vertex embed file
# $7: output directory
# $8: jettrigger
# $9: run number
# $10: sequence

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(bbc g4hits embed file\): $2
echo arg3 \(calo g4hits embed file\): $3
echo arg4 \(track g4hits embed file\): $4
echo arg5 \(truth g4hits embed file\): $5
echo arg6 \(vertex embed file\): $6
echo arg7 \(output dir\): $7
echo arg8 \(jettrigger\): $8
echo arg9 \(runnumber\): $9
echo arg10 \(sequence\): ${10}

runnumber=$(printf "%010d" $9)
sequence=$(printf "%05d" ${10})
filename=fm_0_20_pass3_embed_$8

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running root.exe -q -b Fun4All_G4_Embed.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",0,\"$7\",\"$8\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Embed.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",\"$6\",0,\"$7\",\"$8\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/JS_pp200_signal/pass2_embed/run$9
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname

echo "script done"
