#!/usr/bin/bash
perl run_runrange.pl 54128 54200 --inc
for i in {54200..54800..100}; do j=$((i+99)); perl run_runrange.pl $i $j --inc; done
perl run_runrange.pl 54900 54974 --inc
