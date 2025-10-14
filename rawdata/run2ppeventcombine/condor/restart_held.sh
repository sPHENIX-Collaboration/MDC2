#!/usr/bin/bash

condor_q | grep ' H ' | grep run2pp_eventcombine.sh  > bla
cat bla | awk '{printf("log/condor-%s_%010d.job\n",$12,$11)}' > f.l
#cat bla  | awk '{print "log/condor-"$12"_00000"$11".job"}' > f.l
for i in `cat f.l`; do sed -i 's/4000MB/6000MB/' $i; done
for i in `cat f.l`; do sed -i 's/2048MB/4000MB/' $i; done
for i in `cat bla | awk '{print $1}'`; do condor_rm $i; done
for i in `cat f.l`; do condor_submit $i; done
