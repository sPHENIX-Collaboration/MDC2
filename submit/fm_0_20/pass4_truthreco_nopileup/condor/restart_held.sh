#! /usr/bin/bash
#exit 0

run=10

condor_q | grep ' H ' | grep run_pass4_truthreco_nopileup_fm_0_20.sh > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

if [ -f tmplist ]
then
rm tmplist
fi
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F.  -v run=${run} '{print "-00000000"run"-"$1".job"}'`; do echo $i >> tmplist ; done

if [ -f sedlist ]
then
rm sedlist
fi
for i in `cat tmplist`; do echo log/run${run}/condor$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/4096MB/12288MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
