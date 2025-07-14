#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 1
fi
run=$1
runnumber=$(printf "%010d" $run)
echo restarting run $1

[ -f bla ] && rm bla
condor_q | grep ' H ' | grep run_pass2_0_20fm.sh | grep sHijing_0_20 | grep ${runnumber} > bla
#condor_q | grep ' H ' | grep run_pileup.sh | grep sHijing_0_20 > bla
[ ! -s bla ] && exit 1
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/condor-$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/7000MB/12000MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
