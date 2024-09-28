#! /usr/bin/bash
if [ $# -eq 0 ]
  then
  echo "No arguments supplied"
  exit 0
fi
echo $1
variable=$1
run=19
runnumber=$(printf "%010d" $run)
fm=0_20fm
condor_q | grep ' H ' | grep run_pass3_mbdepd_embed_js.sh | grep ${variable}  > bla
[ -s bla ] || exit 1
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

for i in `cat tmplist`; do condor_submit log/${fm}/run${run}/${variable}/condor_${variable}-$i; done
