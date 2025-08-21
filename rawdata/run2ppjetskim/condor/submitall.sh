#!/usr/bin/bash
perl run_runrange.pl 47289 47299 --inc
for i in {47300..53700..100}; do j=$((i+99)); perl run_runrange.pl $i $j --inc; done
perl run_runrange.pl 53800 53880 --inc
