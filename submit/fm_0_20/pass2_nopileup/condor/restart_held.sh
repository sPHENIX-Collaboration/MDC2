#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 1
fi
run=$1
runnumber=$(printf "%010d" $run)
echo restarting run $1

#exit 0
condor_q | grep ' H ' | grep run_pass2_nopileup_fm_0_20.sh | grep ${runnumber} > bla
[ -s bla ] ||  exit 1
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
#exit 0

[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/condor_calo_mbd-$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/7000MB/12000MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/8000MB/10000MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
