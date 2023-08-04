#! /usr/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit 1
fi
echo $1
variable=$1
[ -f bla ] && rm bla
condor_q | grep ' H ' | grep run_cemc_pass2_geo_fix_js.sh  | grep ${variable} > bla
#condor_q | grep ' H ' | grep run_pileup.sh | grep sHijing_0_20 > bla
[ ! -s bla ] && exit 0
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "-0000000006-"$1".job"}'`; do echo $i >> tmplist ; done
[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/${variable}/condor_${variable}$i >> sedlist; done
#for i in `cat sedlist`; do  sed -i 's/12288MB/24576MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done

