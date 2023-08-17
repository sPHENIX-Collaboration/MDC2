#! /usr/bin/bash
condor_q | grep ' H ' | grep run_pass5_truthreco_pau_0_10fm.sh > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

if [ -f tmplist ]
then
rm tmplist
fi
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "-0000000007-"$1".job"}'`; do echo $i >> tmplist ; done

if [ -f sedlist ]
then
rm sedlist
fi
for i in `cat tmplist`; do echo log/condor_$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/6144MB/12288MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
