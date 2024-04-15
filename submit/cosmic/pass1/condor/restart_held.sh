#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 1
fi
echo $1
variable=$1
run=16
runnumber=$(printf "%010d" $run)
magnet=$(printf "magnet_%s" $1)
#exit 0
condor_q | grep ' H ' | grep run_pass1_cosmic.sh | grep ${magnet}  > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
#exit 0
[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $11}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print "-"runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done
for i in `cat tmplist`; do condor_submit log/run${run}/${magnet}/condor$i; done
