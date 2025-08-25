#!/usr/bin/bash

#echo need to implement grep
#exit 1
condor_q | grep ' H ' | grep run3auau_eventcombine.sh  > bla
cat bla | awk '{printf("log/condor-%s_%010d.job\n",$12,$11)}' > f.l
for i in `cat f.l`; do sed -i 's/2048MB/4000MB/' $i; done
for i in `cat bla | awk '{print $1}'`; do condor_rm $i; done
for i in `cat f.l`; do condor_submit $i; done
