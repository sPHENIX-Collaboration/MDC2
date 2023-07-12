#! /usr/bin/bash
[ -f bla ] && rm bla
condor_q | grep ' H ' | grep run_cemc_pass3trk_geo_fix_0_20fm.sh > bla
[ ! -s bla ] && exit 0
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/condor-0000000006-"$1".job"}'`; do sed -i 's/7168MB/14336MB/' $i; echo $i; condor_submit $i; done
#for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "log/condor-0000000006-"$1".job"}'`; do echo $i; condor_submit $i; done
[ -f bla ] && rm bla
