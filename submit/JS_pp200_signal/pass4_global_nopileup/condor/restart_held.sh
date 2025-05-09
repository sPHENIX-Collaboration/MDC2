#! /usr/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
fi
echo $1
variable=$1
run=21
runnumber=$(printf "%010d" $run)
condor_q | grep ' H ' | grep run_pass4_global_nopileup_js.sh | grep ${variable}  | grep ${runnumber} > bla
#exit 0
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F.  -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done
[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/${variable}/condor_${variable}-$i >> sedlist; done
#for i in `cat sedlist`; do  sed -i 's/2000MB/4000MB/' $i; echo $i; done

for i in `cat sedlist`; do condor_submit $i; done
