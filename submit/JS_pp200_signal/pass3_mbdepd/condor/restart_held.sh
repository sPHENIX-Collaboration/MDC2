#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 0
fi
run=15
runnumber=$(printf "%010d" $run)
MHz=2
echo $1
variable=$1


condor_q | grep ' H ' | grep run_pass3_mbdepd_js.sh | grep ${variable} > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist

for i in `cat tmplist`; do echo log/run${run}/${variable}_${MHz}MHz/condor_${variable}_${MHz}MHz-$i >> sedlist; done

for i in `cat sedlist`; do condor_submit $i; done
