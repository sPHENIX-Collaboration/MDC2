#!/usr/bin/bash

condor_q | grep ' H ' | grep run3auau_calocalib.sh > bla
cat bla | awk '{printf("log/condor-%08d-%05d.job\n",$11,$12)}' > f.l
for i in `cat f.l`; do sed -i 's/2048MB/4000MB/' $i; done
for i in `cat bla | awk '{print $1}'`; do condor_rm $i; done
for i in `cat f.l`; do condor_submit $i; done
