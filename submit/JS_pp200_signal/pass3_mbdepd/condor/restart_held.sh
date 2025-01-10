#! /usr/bin/bash
if [ $# -lt 2 ]
  then
    echo "No arguments supplied"
    exit 1
fi

echo system: $1
echo pileup: $2
variable=$1_$2

run=22
runnumber=$(printf "%010d" $run)

#exit 0
condor_q | grep ' H ' | grep run_pass3_mbdepd_js.sh | grep ${variable} > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/${variable}/condor_${variable}-$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/4000MB/13000MB/' $i; echo $i; done
for i in `cat sedlist`; do  sed -i 's/1024MB/4000MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/4096MB/8192MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/8192MB/16384MB/' $i; echo $i; done
for i in `cat sedlist`; do  sed -i 's/Priority = 53/Priority = 63/' $i; echo $i; done
for i in `cat sedlist`; do [ -f $i ] && condor_submit $i; done
#/direct/sphenix+u/sphnxpro/MDC2/submit/JS_pp200_signal/pass3_job0_nopileup/condor/log/run7/PhotonJet/condor_PhotonJet-0000000007-15130.out
