#! /usr/bin/bash
if [ $# -lt 2 ]
  then
    echo "No arguments supplied"
    exit 1
fi

echo particle: $1
echo minpt: $2
echo maxpt: $3
variable=$1_pt_$2_$3

run=24
runnumber=$(printf "%010d" $run)

#exit 0
condor_q | grep ' H ' | grep run_pass1_pt_single.sh | grep ${variable} > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $14}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/${1}/condor_${variable}-$i >> sedlist; done
#for i in `cat sedlist`; do  sed -i 's/2048MB/4096MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/4096MB/8192MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/8192MB/16384MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done

