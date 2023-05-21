#! /usr/bin/bash
[ -f bla ] && rm bla
condor_q | grep ' H ' | grep run_pass4_job0_pau_0_10fm.sh > bla
[ ! -s bla ] && exit 0
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/condor-0000000006-"$1".job"}'`; do echo $i; condor_submit $i; done
[ -f bla ] && rm bla
