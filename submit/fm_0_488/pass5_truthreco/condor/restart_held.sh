#! /usr/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit 1
fi
echo $1
variable=$1
#exit 0
condor_q | grep ' H ' | grep run_pass5_truthreco_fm_0_488.sh | grep ${variable} > bla

[ -s bla ] ||  exit 1

for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

if [ -f tmplist ]
then
rm tmplist
fi
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "-0000000007-"$1".job"}'`; do echo $i >> tmplist ; done

if [ -f sedlist ]
then
rm sedlist
fi
for i in `cat tmplist`; do echo log/${variable}/condor_${variable}$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/4096MB/12288MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
