#! /usr/bin/bash
condor_q | grep ' H ' | grep run_pass3_jobC_nopileup_fm_0_20.sh | grep sHijing_0_20 > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/condor-0000000007-"$1".job"}'`; do condor_submit $i; done
