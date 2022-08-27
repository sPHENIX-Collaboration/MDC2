#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;

my $test;
GetOptions("test"=>\$test);
if ($#ARGV < 3)
{
    print "usage: run_condor.pl <events> <jettrigger> <outdir> <outfile> <skip> <runnumber> <sequence>\n";
    print "options:\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}
else
{
    print "running condor\n";
}
my $localdir=`pwd`;
chomp $localdir;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass1_single.sh",$rundir);
my $nevents = $ARGV[0];
my $particle = $ARGV[1];
my $pmin = $ARGV[2];
my $pmax = $ARGV[3];
my $dstoutdir = $ARGV[4];
my $dstoutfile = $ARGV[5];
my $runnumber = $ARGV[6];
my $sequence = $ARGV[7];
my $suffix = sprintf("%010d-%05d",$runnumber,$sequence);
my $logdir = sprintf("%s/log",$localdir);
mkpath($logdir);
my $condorlogdir = sprintf("/tmp/single_particle/pass1");
mkpath($condorlogdir);
my $partprop = sprintf("%s_%d_%d",$particle,$pmin,$pmax);
my $jobfile = sprintf("%s/condor_%s-%s.job",$logdir,$partprop,$suffix);
if (-f $jobfile)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
}
my $condorlogfile = sprintf("%s/condor_%s-%s.log",$condorlogdir,$partprop,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor_%s-%s.err",$logdir,$partprop,$suffix);
my $outfile = sprintf("%s/condor_%s-%s.out",$logdir,$partprop,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$nevents $particle $pmin $pmax $dstoutfile $dstoutdir $runnumber $sequence\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
#print F "accounting_group = group_sphenix.prod\n";
print F "accounting_group = group_sphenix.mdc2\n";
print F "accounting_group_user = sphnxpro\n";
print F "Requirements = (CPU_Type == \"mdc2\")\n";
print F "request_memory = 4096MB\n";
print F "Priority 	= 801\n";
print F "job_lease_duration = 3600\n";
print F "Queue 1\n";
close(F);
if (defined $test)
{
    print "would submit $jobfile\n";
}
else
{
    system("condor_submit $jobfile");
}
