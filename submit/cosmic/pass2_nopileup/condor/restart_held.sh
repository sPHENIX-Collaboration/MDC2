#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 1
fi
echo $1
variable=$1
#exit 0
run=16
runnumber=$(printf "%010d" $run)
magnet=$(printf "magnet_%s" $1)
condor_q | grep ' H ' | grep run_pass2_nopileup_cosmic.sh | grep ${magnet} > bla
#exit 0
[ -s bla ] || exit 1
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $11}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print "-"runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done
[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/${magnet}/condor$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/1024MB/4096MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
