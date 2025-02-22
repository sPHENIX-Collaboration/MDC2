#! /usr/bin/bash
#exit 0

run=26
runnumber=$(printf "%010d" $run)

condor_q | grep ' H ' | grep run_pass1_ampt.sh > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F.  -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

if [ -f sedlist ]
then
rm sedlist
fi
for i in `cat tmplist`; do echo log/run${run}/condor-$i >> sedlist; done
#for i in `cat sedlist`; do  sed -i 's/4096MB/12288MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
