#! /usr/bin/bash
condor_q | grep ' H ' | grep run_pass3_jobA_nopileup_fm_0_488.sh > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/run7/condor-0000000007-"$1".job"}'`; do condor_submit $i; done
