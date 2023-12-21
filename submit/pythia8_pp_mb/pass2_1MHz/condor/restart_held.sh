#! /usr/bin/bash
run=11
condor_q | grep ' H ' | grep run_pileup_pythia8_pp_mb.sh > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
for i in `cat bla | awk '{print $12}' | awk -F- -v run=${run} '{print $3}' | awk -F.  -v run=${run} '{print "log/run"run"/condor_1MHz-00000000"run"-"$1".job"}'`; do condor_submit $i; done
