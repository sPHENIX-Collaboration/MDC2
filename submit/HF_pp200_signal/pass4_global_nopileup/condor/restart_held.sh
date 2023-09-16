#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 1
fi
echo $1
variable=$1
#exit 0
condor_q | grep ' H ' | grep run_pass4_global_nopileup_hf.sh | grep ${variable} > bla
[ -s bla ] || exit 1
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
if [ -f tmplist ]
then
rm tmplist
fi
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "-0000000007-"$1".job"}'`; do echo $i >> tmplist ; done
for i in `cat tmplist`; do condor_submit log/${variable}/condor_${variable}$i; done
