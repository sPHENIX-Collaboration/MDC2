#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 0
fi
echo resetting $1
grepvariable=$1-
variable=$1
run=11
echo $variable
#[ -f bla ] && rm bla
#condor_q | grep ' H ' | grep run_pass3_job0_nopileup_hf.sh | grep ${grepvariable} > bla
#[ ! -s bla ] && exit 0
#for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done

[ -f tmplist ] && rm tmplist
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. -v run=${run} '{print "-00000000"run"-"$1".job"}'`; do echo $i >> tmplist ; done

[ -f sedlist ] && rm sedlist
for i in `cat tmplist`; do echo log/run${run}/${variable}/condor_${variable}$i >> sedlist; done
for i in `cat sedlist`; do  sed -i 's/4096MB/512MB/' $i; echo $i; done
for i in `cat sedlist`; do condor_submit $i; done
