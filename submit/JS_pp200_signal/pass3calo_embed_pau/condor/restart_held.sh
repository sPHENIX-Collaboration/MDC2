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
condor_q | grep ' H ' | grep run_pass3calo_embed_pau_js.sh | grep ${variable} > bla
[ -f bla ] || exit 0
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "-0000000006-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/${variable}/condor_${variable}$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/2048MB/4096MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
