#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 1
fi
run=28
runnumber=$(printf "%010d" $run)
echo restarting $1
variable=$1
grepvar=Herwig_${variable}

#exit 0
condor_q | grep ' H ' | grep run_pass1_herwig.sh | grep ${grepvar} | grep ${runnumber} > bla
#exit 0
[ -s bla ] ||  exit 1
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
#exit 0

[ -f tmplist ] && rm tmplist

for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/${variable}/condor-$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/5500MB/8000MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done

