#! /usr/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit 1
fi
echo $1
variable=$1
run=23
runnumber=$(printf "%010d" $run)
fm=0_20fm
withhijing=${fm}_50kHz_bkg_0_20fm
#exit 0
condor_q | grep ' H ' | grep run_pass3jet_embed_js.sh | grep ${withhijing} | grep ${variable} | grep ${runnumber} > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F.  -v runnumber=${runnumber} '{print ""runnumber"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/${fm}/run${run}/${variable}/condor_${variable}-$i >> sedlist; done
#for i in `cat sedlist`; do  sed -i 's/15000MB/17000MB/' $i; echo $i; done
#for i in `cat sedlist`; do  sed -i 's/12000MB/15000MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
