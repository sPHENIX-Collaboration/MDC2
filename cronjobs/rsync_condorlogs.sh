#! /bin/bash
host=`hostname -s`
tagfile=rsync_condorlogs_${host}.running
[[ -e $tagfile ]] && exit 0
echo $$ > $tagfile
script=rsync_condorlogs.pl
[[ ! -f $script ]] && exit 0
logfile=rsync_condorlogs_${host}.log
perl $script >& $logfile
rm $tagfile
