#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 1
fi
echo $1
variable=$1
run=7
#exit 0
condor_q | grep ' H ' | grep run_pass1_js.sh | grep ${variable}  > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v run=${run} '{print "-000000000"run"-"$1".job"}'`; do echo $i >> tmplist ; done
for i in `cat tmplist`; do condor_submit log/run${run}/${variable}/condor_${variable}$i; done
