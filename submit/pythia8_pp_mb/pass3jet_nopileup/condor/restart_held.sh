#! /usr/bin/bash
condor_q | grep ' H ' | grep run_pass3jet_nopileup_pp_mb.sh > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/condor-0000000006-"$1".job"}'`; do condor_submit $i; done
