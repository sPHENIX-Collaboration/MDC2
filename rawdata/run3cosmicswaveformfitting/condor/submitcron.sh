#!/bin/bash
[[ -e submitrunning ]] && exit 0
echo $$ > submitrunning
source  /opt/sphenix/core/bin/sphenix_setup.sh -n
echo running on `hostname` > run_runrange.log
perl run_runrange.pl 66390 90000 --inc &>> run_runrange.log
#perl run_runrange.pl 79000 90000 --inc &>> run_runrange.log
rm submitrunning
