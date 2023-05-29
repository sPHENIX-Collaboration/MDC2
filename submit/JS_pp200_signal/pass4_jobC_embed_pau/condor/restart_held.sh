#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 0
fi
echo $1
variable=$1
#exit 0
[ -f bla ] && rm bla
condor_q | grep ' H ' | grep run_jobC_embed_pau_js.sh | grep ${variable}  > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "-0000000006-"$1".job"}'`; do echo $i >> tmplist ; done
for i in `cat tmplist`; do condor_submit log/${variable}/condor_${variable}$i; done
