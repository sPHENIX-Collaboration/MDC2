#! /bin/bash
host=`hostname -s`
tagfile=autopilot_${host}.running
[[ -e $tagfile ]] && exit 0
echo $$ > $tagfile
script=autopilot_${host}.pl
[[ ! -f $script ]] && exit 0
logfile=autopilot_${host}.log
perl $script >& $logfile
rm $tagfile
