#! /usr/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
fi
echo $1
variable=$1
#exit 0
condor_q | grep ' H ' | grep run_pass3calo_embed.sh | grep ${variable} | grep sHijing_0_20 > bla
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

if [ -f tmplist ]
then
rm tmplist
fi
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "-0000000006-"$1".job"}'`; do echo $i >> tmplist ; done

if [ -f sedlist ]
then
rm sedlist
fi
for i in `cat tmplist`; do echo log/${variable}/condor_${variable}$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/6144MB/12288MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
