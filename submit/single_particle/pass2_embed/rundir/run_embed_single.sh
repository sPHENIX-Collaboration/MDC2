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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.348

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $5 > inputfiles.list
    echo $6 >> inputfiles.list
    echo $7 >> inputfiles.list
    echo $8 >> inputfiles.list
    echo $9 >> inputfiles.list
    getinputfiles.pl  --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from getinputfiles.pl  --filelist inputfiles.list, exiting
	exit -1
    fi
else
 echo condor scratch NOT set
 exit -1
fi

# arguments 
# $1: number of output events
# $2: particle
# $3: ptmin
# $4: ptmax
# $5: bbc g4hits embed file
# $6: calo g4hits embed file
# $7: track g4hits embed file
# $8: truth g4hits embed file
# $9: vertex embed file
# $10: output directory
# $11: run number
# $12: sequence

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(particle\): $2
echo arg3 \(ptmin\): $3
echo arg4 \(ptmax\): $4
echo arg5 \(bbc g4hits embed file\): $5
echo arg6 \(calo g4hits embed file\): $6
echo arg7 \(track g4hits embed file\): $7
echo arg8 \(truth g4hits embed file\): $8
echo arg9 \(vertex embed file\): $9
echo arg10 \(output dir\): ${10}
echo arg11 \(runnumber\): ${11}
echo arg12 \(sequence\): ${12}

runnumber=$(printf "%010d" ${11})
sequence=$(printf "%05d" ${12})
filename=hijing_embed_$2

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running root.exe -q -b Fun4All_G4_Single_Embed.C\($1,\"$2\",$3, $4, \"$5\",\"$6\",\"$7\",\"$8\",\"$9\",\"${10}\"\)
prmon  --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Single_Embed.C\($1,\"$2\",$3,$4,\"$5\",\"$6\",\"$7\",\"$8\",\"$9\",\"${10}\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/single/single_embed_$2/run${11}
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname

echo "script done"
