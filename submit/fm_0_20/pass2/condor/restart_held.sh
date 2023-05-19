#! /usr/bin/bash
[ -f bla ] && rm bla
#condor_q | grep ' H ' | grep run_pileup_0_20fm.sh | grep sHijing_0_20 > bla
condor_q | grep ' H ' | grep run_pileup.sh | grep sHijing_0_20 > bla
[ ! -s bla ] && exit 0
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
#for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/condor-0000000006-"$1".job"}'`; do sed -i 's/run_pileup.sh/run_pileup_0_20fm.sh/' $i; echo $i; condor_submit $i; done
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/condor-0000000006-"$1".job"}'`; do echo $i; condor_submit $i; done
[ -f bla ] && rm bla
