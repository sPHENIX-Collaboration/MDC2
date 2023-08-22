#! /usr/bin/bash
condor_q | grep ' H ' | grep run_pileup_pythia8_pp_mb.sh > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/condor_3MHz-0000000007-"$1".job"}'`; do condor_submit $i; done
