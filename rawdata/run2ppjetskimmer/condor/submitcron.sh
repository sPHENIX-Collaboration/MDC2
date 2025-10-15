#!/bin/bash
[[ -e submitrunning ]] && exit 0
echo $$ > submitrunning
source  /opt/sphenix/core/bin/sphenix_setup.sh -n
echo running on `hostname` > run_runrange.log
# first runs have a gl1 problem in initial v006
#perl run_runrange.pl 48706 53880 --inc &>> run_runrange.log
perl run_runrange.pl 47289 53880 --inc >& run_runrange.log
rm submitrunning
