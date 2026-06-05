#! /usr/bin/bash
if [ $# -lt 1 ]
  then
    echo "No arguments supplied"
    exit 1
fi

echo pileup: $1
variable=$1

run=28
runnumber=$(printf "%010d" $run)
grepvar=run_pass5_truthreco_oo.sh

#exit 0
condor_q | grep ' H ' | grep ${grepvar} | grep ${variable} | grep ${runnumber} > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/${variable}/condor_$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/4000MB/6000MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/4096MB/8192MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/8192MB/16384MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/Priority = 51/Priority = 61/' $i; echo $i; done
for i in `cat sedlist`; do [ -f $i ] && condor_submit $i; done

