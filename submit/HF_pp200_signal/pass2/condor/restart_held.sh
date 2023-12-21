#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 1
fi
echo $1
variable=$1
variable_3MHz=${variable}_3MHz
run=11
#exit 0
condor_q | grep ' H ' | grep run_pass2_hf.sh | grep ${variable_3MHz} > bla
[ -s bla ] || exit 1
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F.  -v run=${run} '{print "-00000000"run"-"$1".job"}'`; do echo $i >> tmplist ; done
for i in `cat tmplist`; do condor_submit log/run${run}/${variable_3MHz}/condor_${variable_3MHz}$i; done
