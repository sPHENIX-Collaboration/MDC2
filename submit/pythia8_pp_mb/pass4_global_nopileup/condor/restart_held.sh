#! /usr/bin/bash

run=8

condor_q | grep ' H ' | grep run_pass4_global_nopileup_pp_mb.sh  > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v run=${run} '{print "000000000"run"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/condor-$i >> sedlist; done
for i in `cat sedlist`; do condor_submit $i; done
